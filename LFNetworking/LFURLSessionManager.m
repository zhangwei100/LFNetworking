//
//  LFURLSessionManager.m
//  LFURLSessionManager
//
//  Created by Wei Zhang on 9/01/14.
//  Copyright (c) 2014 WeiZhang. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "LFURLSessionManager.h"

@interface LFURLSessionManager () <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

@property (readwrite, nonatomic, strong) NSURLSessionConfiguration *sessionConfiguration;
@property (readwrite, nonatomic, strong) NSURLSession *session;
@property (readwrite, nonatomic, strong) NSMutableDictionary *operations;

/** Convenience method */
- (LFNetworkTaskOperation *)taskOperationWithURLSessionTask:(NSURLSessionTask *)task;
- (void)removeTaskOperationForTask:(NSURLSessionTask *)task;
- (void)addTaskToOperationsWithTaskOperation:(LFNetworkTaskOperation *)taskOperation;

@end

@implementation LFURLSessionManager

#pragma mark -
#pragma mark Initialization

- (instancetype)init {
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    return [self initWithSessionConfiguration:sessionConfiguration];
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration {
    
    self = [super init];
    if (!self) {
        return nil;
    }
    
    if (!configuration) {
        configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    }
    
    self.sessionConfiguration = configuration;
    self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    
    self.securityPolicy = [AFSecurityPolicy defaultPolicy];
    
    self.operations = [[NSMutableDictionary alloc] init];
    
    return self;
}

- (LFNetworkDataTaskOperation *)dataOperationWithRequest:(NSURLRequest *)request
                                         progressHandler:(LFURLSessionDataTaskProgressBlock)progressHandler
                                       completionHandler:(LFURLSessionTaskDidCompleteWithDataErrorBlock)didCompleteWithDataErrorHandler {
    
    NSParameterAssert(request);
    
    LFNetworkDataTaskOperation *operation = [[LFNetworkDataTaskOperation alloc] initWithSession:self.session request:request];
    NSAssert(operation, @"%s: instantiation of NetworkDataTaskOperation failed", __FUNCTION__);
    
    operation.progressHandler = progressHandler;
    operation.didCompleteWithDataErrorHandler = didCompleteWithDataErrorHandler;
    operation.completionQueue = self.completionQueue;
    
    [self addTaskToOperationsWithTaskOperation:operation];
    
    return operation;
}

- (LFNetworkDataTaskOperation *)dataOperationWithURL:(NSURL *)url
                                     progressHandler:(LFURLSessionDataTaskProgressBlock)progressHandler
                                   completionHandler:(LFURLSessionTaskDidCompleteWithDataErrorBlock)didCompleteWithDataErrorHandler {
    
    NSParameterAssert(url);
    
    return [self dataOperationWithRequest:[NSURLRequest requestWithURL:url]
                          progressHandler:progressHandler
                        completionHandler:didCompleteWithDataErrorHandler];
}

#pragma mark -
#pragma mark NSOperationQueue

+ (NSOperationQueue *)sharedNetworkOperationQueue {
    static NSOperationQueue *_sharedNetworkOperationQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedNetworkOperationQueue = [[NSOperationQueue alloc] init];
        _sharedNetworkOperationQueue.name = [NSString stringWithFormat:@"%@.LFURLSessionManager.%p", [[NSBundle mainBundle] bundleIdentifier], self];
        _sharedNetworkOperationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
    });
    
    return _sharedNetworkOperationQueue;
}

- (void)addOperation:(NSOperation *)operation {
    [[[self class] sharedNetworkOperationQueue] addOperation:operation];
}

#pragma mark -
#pragma mark NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    if (self.didBecomeInvalidHandler) {
        dispatch_async(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.didBecomeInvalidHandler(self, error);
        });
    }
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;
    
    if (self.didReceiveChallengeHandler) {
        dispatch_async(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.didReceiveChallengeHandler(self, challenge, completionHandler);
        });
    } else {
        
        if (0 == challenge.previousFailureCount && self.credential) {
            completionHandler(NSURLSessionAuthChallengeUseCredential, self.credential);
        } else {
            if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
                if ([self.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
                    credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                    if (credential) {
                        disposition = NSURLSessionAuthChallengeUseCredential;
                    } else {
                        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
                    }
                } else {
                    disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
                }
            } else {
                disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            }
            if (completionHandler) {
                completionHandler(disposition, credential);
            }
        }
    }
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    
    BOOL __block shouldCallCompletionHanlder;
    
    if (self.urlSessionDidFinishEventsHandler) {
        dispatch_async(self.completionQueue ?: dispatch_get_main_queue(), ^{
            shouldCallCompletionHanlder = self.urlSessionDidFinishEventsHandler(self);
        });
    } else {
        shouldCallCompletionHanlder = YES;
    }
    
    if (shouldCallCompletionHanlder) {
        if (self.backgroundSessionCompletionHandler) {
            self.backgroundSessionCompletionHandler();
            self.backgroundSessionCompletionHandler = nil;
        }
    }
}

#pragma mark -
#pragma mark NSURLSessionTaskDelegate

- (LFNetworkTaskOperation *)taskOperationWithURLSessionTask:(NSURLSessionTask *)task {
    return self.operations[@(task.taskIdentifier)];
}

- (void)addTaskToOperationsWithTaskOperation:(LFNetworkTaskOperation *)taskOperation {
    [self.operations setObject:taskOperation forKey:@(taskOperation.task.taskIdentifier)];
}

- (void)removeTaskOperationForTask:(NSURLSessionTask *)task {
    LFNetworkTaskOperation *taskOperation = [self taskOperationWithURLSessionTask:task];
    
    if (!taskOperation) return;
    
    [self.operations enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (obj == taskOperation) {
            [self.operations removeObjectForKey:key];
            *stop = YES;
        }
    }];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    LFNetworkTaskOperation *operation = [self taskOperationWithURLSessionTask:task];
    
    if ([operation respondsToSelector:@selector(URLSession:task:didCompleteWithError:)] && operation.didCompleteWithDataErrorHandler) {
        [operation URLSession:session task:task didCompleteWithError:error];
    } else {
        if (self.didCompleteHandler) {
            dispatch_async(self.completionQueue ?: dispatch_get_main_queue(), ^{
                self.didCompleteHandler(self, task, error);
            });
        }
        
        [operation completeOperation];
    }
    
    [self removeTaskOperationForTask:task];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    LFNetworkTaskOperation *operation = [self taskOperationWithURLSessionTask:task];
    
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    __block NSURLCredential *credential = nil;
    
    if ([operation respondsToSelector:@selector(URLSession:task:didReceiveChallenge:completionHandler:)] && challenge.previousFailureCount == 0 && [operation canRespondToChallenge]) {
        [operation URLSession:session task:task didReceiveChallenge:challenge completionHandler:completionHandler];
    } else {
        if (self.didReceiveChallengeHandler) {
            dispatch_async(self.completionQueue ?: dispatch_get_main_queue(), ^{
                self.didReceiveChallengeHandler(self, challenge, completionHandler);
            });
        } else {
            if (self.credential && challenge.previousFailureCount == 0) {
                completionHandler(NSURLSessionAuthChallengeUseCredential, self.credential);
            } else {
                if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
                    if ([self.securityPolicy evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:challenge.protectionSpace.host]) {
                        disposition = NSURLSessionAuthChallengeUseCredential;
                        credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
                    } else {
                        disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
                    }
                } else {
                    disposition = NSURLSessionAuthChallengePerformDefaultHandling;
                }
            }
            
            if (completionHandler) {
                completionHandler(disposition, credential);
            }
        }
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    LFNetworkTaskOperation *operation = [self taskOperationWithURLSessionTask:task];
    
    if ([operation respondsToSelector:@selector(URLSession:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:)]) {
        [operation URLSession:session task:task didSendBodyData:bytesSent totalBytesSent:totalBytesSent totalBytesExpectedToSend:totalBytesExpectedToSend];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task needNewBodyStream:(void (^)(NSInputStream *bodyStream))completionHandler
{
    LFNetworkTaskOperation *operation = [self taskOperationWithURLSessionTask:task];
    
    if ([operation respondsToSelector:@selector(URLSession:task:needNewBodyStream:)]) {
        [operation URLSession:session task:task needNewBodyStream:completionHandler];
    } else {
        completionHandler(nil);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler
{
    LFNetworkTaskOperation *operation = [self taskOperationWithURLSessionTask:task];
    
    if ([operation respondsToSelector:@selector(URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:)]) {
        [operation URLSession:session task:task willPerformHTTPRedirection:response newRequest:request completionHandler:completionHandler];
    } else {
        completionHandler(request);
    }
}

#pragma mark -
#pragma mark NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler
{
    LFNetworkDataTaskOperation *operation = (LFNetworkDataTaskOperation *)[self taskOperationWithURLSessionTask:dataTask];
    
    if ([operation respondsToSelector:@selector(URLSession:dataTask:didReceiveResponse:completionHandler:)]) {
        [operation URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
    } else {
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    LFNetworkDataTaskOperation *operation = (LFNetworkDataTaskOperation *)[self taskOperationWithURLSessionTask:dataTask];
    
    if ([operation respondsToSelector:@selector(URLSession:dataTask:didReceiveData:)]) {
        [operation URLSession:session dataTask:dataTask didReceiveData:data];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse *cachedResponse))completionHandler
{
    LFNetworkDataTaskOperation *operation = (LFNetworkDataTaskOperation *)[self taskOperationWithURLSessionTask:dataTask];
    
    if ([operation respondsToSelector:@selector(URLSession:dataTask:willCacheResponse:completionHandler:)]) {
        [operation URLSession:session dataTask:dataTask willCacheResponse:proposedResponse completionHandler:completionHandler];
    } else {
        completionHandler(proposedResponse);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask
{
    LFNetworkDataTaskOperation *operation = (LFNetworkDataTaskOperation *)[self taskOperationWithURLSessionTask:dataTask];
    
    if ([operation respondsToSelector:@selector(URLSession:dataTask:didBecomeDownloadTask:)]) {
        [operation URLSession:session dataTask:dataTask didBecomeDownloadTask:downloadTask];
    }
}

@end
