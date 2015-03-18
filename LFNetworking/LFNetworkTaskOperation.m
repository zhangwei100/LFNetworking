//
//  LFNetworkTaskOperation.m
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

#import "LFNetworkTaskOperation.h"

@interface LFNetworkTaskOperation ()

@property (nonatomic, readwrite, getter = isFinished) BOOL finished;
@property (nonatomic, readwrite, getter = isExecuting) BOOL executing;

@end

@implementation LFNetworkTaskOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

#pragma mark -
#pragma mark Initialization

- (instancetype)initWithSession:(NSURLSession *)session
                        request:(NSURLRequest *)request
{
    NSAssert(FALSE, @"%s should not be called for LFNetworkTaskOperation, but rather LFNetworkDataTaskOperation, LFNetworkDownloadTaskOperation, or LFNetworkUploadTaskOperation", __FUNCTION__);
    
    return nil;
}

- (BOOL)canRespondToChallenge {
    return self.credential || self.didReceiveChallengeHandler;
}

#pragma mark -
#pragma mark Manage Operation

- (void)start {

    // "For operations that are queued but not yet executing, the queue must still call the operation object’s start method so that it can processes the cancellation event and mark itself as finished." So we must do the checking here in case it has already been canceled.
    if ([self isCancelled]) {
        self.finished = YES;
        return;
    }
    
    self.executing = YES;
    [self.task resume];
}

- (void)cancel {
    [self.task cancel];
    [super cancel];
}

- (void)completeOperation {
    self.executing = NO;
    self.finished = YES;
}

#pragma mark -
#pragma mark NSOperation methods;

- (BOOL)isConcurrent {
    return YES;
}

// Overide this since we have to change the status manually in different callbacks.
- (void)setExecuting:(BOOL)executing {
    // KVO is critical here while we subclassing NSOperation since NSOperationQueue are based on KVO to manage NSOperations.
    if (executing != _executing) {
        [self willChangeValueForKey:@"isExecuting"];
        _executing = executing;
        [self didChangeValueForKey:@"isExecuting"];
    }
}

- (void)setFinished:(BOOL)finished {
    if (finished != _finished) {
        [self willChangeValueForKey:@"isFinished"];
        _finished = finished;
        [self didChangeValueForKey:@"isFinished"];
    }
}

#pragma mark -
#pragma mark NSURLSessionTaskDeleagte

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    // Warning: Subclass should override this method.
    
    if (self.didCompleteWithDataErrorHandler) {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.didCompleteWithDataErrorHandler(self, nil, error);
            self.didCompleteWithDataErrorHandler = nil;
        });
    }

    [self completeOperation];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition , NSURLCredential *credential))completionHandler {
    if (self.didReceiveChallengeHandler) {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.didReceiveChallengeHandler(self, challenge, completionHandler);
        });
    } else {
        if (0 == challenge.previousFailureCount && self.credential) {
            completionHandler(NSURLSessionAuthChallengeUseCredential, self.credential);
        } else {
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        }
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend {
    if (self.didSendBodyDataHandler) {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.didSendBodyDataHandler(self, bytesSent, totalBytesSent, totalBytesExpectedToSend);
        });
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task needNewBodyStream:(void (^)(NSInputStream *))completionHandler {
    if (self.needNewBodyStreamHandler) {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.needNewBodyStreamHandler(self, completionHandler);
        });
    } else {
        completionHandler(nil);
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest *))completionHandler {
    if (self.willPerformHTTPRedirectHandler) {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.willPerformHTTPRedirectHandler(self, response, request, completionHandler);
        });
    } else {
        completionHandler(request);
    }
}

@end
