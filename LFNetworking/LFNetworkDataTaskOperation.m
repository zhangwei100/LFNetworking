//
//  LFNetworkDataTaskOperation.m
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

#import "LFNetworkDataTaskOperation.h"

@interface LFNetworkDataTaskOperation ()

@property (nonatomic, assign) long long totalBytesExpected;
@property (nonatomic, assign) long long bytesReceived;

@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) NSError *error;

@end

@implementation LFNetworkDataTaskOperation

#pragma mark -
#pragma mark Initialization

- (instancetype)initWithSession:(NSURLSession *)session request:(NSURLRequest *)request {
    
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.task = [session dataTaskWithRequest:request];
    
    return self;
}

#pragma mark -
#pragma mark NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (self.didCompleteHandler) {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.didCompleteHandler(self, self.responseData, error);
            self.didCompleteHandler = nil;
            self.responseData = nil;
        });
    }
    
    [self completeOperation];
}

#pragma mark -
#pragma mark NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    
    if (self.didReceiveResponseHandler) {
        
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.didReceiveResponseHandler(self, response, completionHandler);
        });
        
    } else {
        
        if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse *)response;
            NSInteger statusCode = [httpURLResponse statusCode];
            self.totalBytesExpected = [response expectedContentLength];
            self.bytesReceived = 0ll;
            
            if (200 == statusCode) {
                completionHandler(NSURLSessionResponseAllow);
            } else {
                completionHandler(NSURLSessionResponseCancel);
                if (self.didCompleteHandler) {
                    self.error = [NSError errorWithDomain:NSStringFromClass([self class]) code:statusCode userInfo:@{@"statusCode": @(statusCode), @"response": dataTask.response}];
                }
            }
            
            return;
            
        } else {
            completionHandler(NSURLSessionResponseAllow);
        }
        
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    
    self.bytesReceived += [data length];
    
    if (self.didReceiveDataHandler) {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.didReceiveDataHandler(self, data, self.totalBytesExpected, self.bytesReceived);
        });
    } else {
        if (!self.responseData) {
            self.responseData = [NSMutableData dataWithData:data];
        } else {
            [self.responseData appendData:data];
        }
    }
    
    if (self.progressHandler) {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.progressHandler(self, self.totalBytesExpected, self.bytesReceived);
        });
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse *))completionHandler {
    if (self.willCacheResponseHandler) {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.willCacheResponseHandler(self, proposedResponse, completionHandler);
        });
    } else {
        completionHandler(proposedResponse);
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    if (self.willBecomeDownloadTaskHandler) {
        dispatch_sync(self.completionQueue ?: dispatch_get_main_queue(), ^{
            self.willBecomeDownloadTaskHandler(self, downloadTask);
        });
    }
}

@end
