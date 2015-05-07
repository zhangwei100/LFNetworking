//
//  LFHTTPSessionManager.m
//
//
//  Created by Wei Zhang on 09/01/14.
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

#import "LFHTTPSessionManager.h"

@interface LFHTTPSessionManager ()

@property (readwrite, nonatomic, strong) NSURL *baseURL;

- (LFNetworkDataTaskOperation *)dataTaskOperationWithHTTPMethod:(NSString *)method
                                                      URLString:(NSString *)urlString
                                                     parameters:(id)parameters
                                      constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                                                        success:(void (^)(LFNetworkDataTaskOperation *taskOperation, id responseObject))success
                                                        failure:(void (^)(LFNetworkDataTaskOperation *taskOperation, NSError *error))failure;

@end

@implementation LFHTTPSessionManager

+ (instancetype)manager {
    return [[[self class] alloc] initWithBaseURL:nil];
}

- (instancetype)init {
    return [self initWithBaseURL:nil];
}

- (instancetype)initWithBaseURL:(NSURL *)url {
    return [self initWithBaseURL:url sessionConfiguration:nil];
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration {
    return [self initWithBaseURL:nil sessionConfiguration:configuration];
}

- (instancetype)initWithBaseURL:(NSURL *)url
           sessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    self = [super initWithSessionConfiguration:configuration];
    if (!self) {
        return nil;
    }
    
    // Ensure terminal slash for baseURL path, so that NSURL +URLWithString:relativeToURL: works as expected
    if ([[url path] length] > 0 && ![[url absoluteString] hasSuffix:@"/"]) {
        url = [url URLByAppendingPathComponent:@""];
    }
    
    self.baseURL = url;
    
    self.requestSerializer = [AFHTTPRequestSerializer serializer];
    self.responseSerializer = [AFJSONResponseSerializer serializer];
    
    return self;
}

- (LFNetworkDataTaskOperation *)dataTaskOperationWithHTTPMethod:(NSString *)method
                                                      URLString:(NSString *)urlString
                                                     parameters:(id)parameters
                                      constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                                                        success:(void (^)(LFNetworkDataTaskOperation *, id))success
                                                        failure:(void (^)(LFNetworkDataTaskOperation *, NSError *))failure {
    NSError *serializationError = nil;
    NSMutableURLRequest *request = nil;
    
    if (block) {
        
        request = [self.requestSerializer multipartFormRequestWithMethod:method
                                                               URLString:urlString
                                                              parameters:parameters
                                               constructingBodyWithBlock:block
                                                                   error:&serializationError];
    } else {
        
        request = [self.requestSerializer requestWithMethod:method
                                                  URLString:[[NSURL URLWithString:urlString relativeToURL:self.baseURL] absoluteString]
                                                 parameters:parameters
                                                      error:&serializationError];
    }
    
    if (serializationError) {
        
        if (failure) {
            dispatch_async(self.completionQueue ?: dispatch_get_main_queue(), ^{
                failure(nil, serializationError);
            });
        }
        
        return nil;
    }
    
    __block LFNetworkDataTaskOperation *dataTaskOperation = nil;
    
    dataTaskOperation = [self dataOperationWithRequest:request progressHandler:nil completionHandler:^(LFNetworkTaskOperation *operation, NSData *data, NSError *error) {
        
        if (error) {
            
            if (failure) {
                failure((LFNetworkDataTaskOperation *)operation, error);
            }
            
        } else {
            
            if (success) {
                
                if (self.responseSerializer) {
                    NSError *serializationError = nil;
                    id object = [self.responseSerializer responseObjectForResponse:operation.task.response data:data error:&serializationError];
                    if (serializationError) {
                        if (failure) {
                            failure(dataTaskOperation, serializationError);
                        }
                    } else {
                        success(dataTaskOperation, object);
                    }
                } else {
                    success(dataTaskOperation, data);
                }
            }
        }
    }];
    
    return dataTaskOperation;
}

- (LFNetworkDataTaskOperation *)POST:(NSString *)urlString
                          parameters:(id)parameters
           constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                             success:(void (^)(LFNetworkDataTaskOperation *taskOperation, id responseObject))success
                             failure:(void (^)(LFNetworkDataTaskOperation *taskOperation, NSError *error))failure {
    
    LFNetworkDataTaskOperation *operation = [self dataTaskOperationWithHTTPMethod:@"POST" URLString:urlString parameters:parameters constructingBodyWithBlock:block success:success failure:failure];
    
    [self addOperation:operation];
    
    return operation;
}

- (LFNetworkDataTaskOperation *)POST:(NSString *)urlString
                          parameters:(id)parameters
                             success:(void (^)(LFNetworkDataTaskOperation *, id))success
                             failure:(void (^)(LFNetworkDataTaskOperation *, NSError *))failure {
    
    return [self POST:urlString parameters:parameters constructingBodyWithBlock:nil success:success failure:false];
}

- (LFNetworkDataTaskOperation *)GET:(NSString *)urlString
                         parameters:(id)parameters
                            success:(void (^)(LFNetworkDataTaskOperation *, id))success
                            failure:(void (^)(LFNetworkDataTaskOperation *, NSError *))failure {
    
    LFNetworkDataTaskOperation *operation = [self dataTaskOperationWithHTTPMethod:@"GET" URLString:urlString parameters:parameters constructingBodyWithBlock:nil success:success failure:failure];
    
    [self addOperation:operation];
    
    return operation;
}

- (LFNetworkDataTaskOperation *)DELETE:(NSString *)urlString
                            parameters:(id)parameters
                               success:(void (^)(LFNetworkDataTaskOperation *taskOperation, id responseObject))success
                               failure:(void (^)(LFNetworkDataTaskOperation *taskOperation, NSError *error))failure {

    LFNetworkDataTaskOperation *operation = [self dataTaskOperationWithHTTPMethod:@"DELETE" URLString:urlString parameters:parameters constructingBodyWithBlock:nil success:success failure:failure];
    
    [self addOperation:operation];
    
    return operation;
}

- (LFNetworkDataTaskOperation *)PUT:(NSString *)urlString
                         parameters:(id)parameters
                            success:(void (^)(LFNetworkDataTaskOperation *taskOperation, id responseObject))success
                            failure:(void (^)(LFNetworkDataTaskOperation *taskOperation, NSError *error))failure {
    
    LFNetworkDataTaskOperation *operation = [self dataTaskOperationWithHTTPMethod:@"PUT" URLString:urlString parameters:parameters constructingBodyWithBlock:nil success:success failure:failure];
    
    [self addOperation:operation];
    
    return operation;
}


@end
