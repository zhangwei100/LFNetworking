//
//  LFNetworkDataTaskOperation.h
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

@class LFNetworkDataTaskOperation;

typedef void(^LFURLSessionDataTaskDidReceiveResponseBlock)(LFNetworkDataTaskOperation *operation,
                                                           NSURLResponse *response,
                                                           void(^completionHandler)(NSURLSessionResponseDisposition dispostion));
typedef void(^LFURLSessionDataTaskDidReceiveDataBlock)(LFNetworkDataTaskOperation *operation,
                                                       NSData *data,
                                                       long long totalBytesExpected,
                                                       long long bytesReceived);
typedef void(^LFURLSessionDataTaskProgressBlock)(LFNetworkDataTaskOperation *operation,
                                                 long long totalBytesExpected,
                                                 long long bytesReceived);
typedef void(^LFURLSessionDataTaskWillCacheResponseBlock)(LFNetworkDataTaskOperation *operation,
                                                          NSCachedURLResponse *proposedResponse,
                                                          void(^completionHandler)(NSCachedURLResponse *cachedURLResponse));
typedef void(^LFURLSessionDataTaskWillBecomeDownloadTaskBlock)(LFNetworkDataTaskOperation *operation,
                                                               NSURLSessionDownloadTask *downloadTask);

/** Operation that wraps delegate-based NSURLSessionDataDask.
 *
 * This is a `<LFNetworkTaskOperation>` subclass instantiated by `<LFURLSessionManager>` method
 * `dataOperationWithRequest:progressHandler:completionHandler:`.
 * This implements the `NSURLSessionTaskDelegate` methods, which the
 * `<LFURLSessionManager>` will invoke as it (the actual task delegate)
 * receives its delegate calls.
 */
@interface LFNetworkDataTaskOperation : LFNetworkTaskOperation <NSURLSessionDataDelegate>

/// ----------------
/// @name Properties
/// ----------------

/** Called by `NSURLSessionDataDelegate` method `URLSession:dataTask:didReceiveResponse:completionHandler:`.
 
 Uses the following typdef:
 
 typedef void(^LFURLSessionDataTaskDidReceiveResponseBlock)(LFNetworkDataTaskOperation *operation,
 NSURLResponse *response,
 void(^completionHandler)(NSURLSessionResponseDisposition dispostion));
 */

@property (nonatomic, copy) LFURLSessionDataTaskDidReceiveResponseBlock didReceiveResponseHandler;

/** Called by `NSURLSessionDataDelegate` method `URLSession:dataTask:didReceiveData:`.
 
 Use this block if you do not want the `LFNetworkDataTaskOperation` to build a `NSData` object
 with the entire response, but rather if you're going to handle the data as it comes in yourself
 (e.g. you have your own streaming method or are going to be processing the response as it comes
 in, rather than waiting for the entire response).
 
 Uses the following typedef:
 
 typedef void(^LFURLSessionDataTaskDidReceiveDataBlock)(LFNetworkDataTaskOperation *operation,
 NSData *data,
 long long totalBytesExpected,
 long long bytesReceived);
 
 @note The `totalBytesExpected` parameter of this block is provided by the server, and as such, it is not entirely reliable. Also note that if it could not be determined, `totalBytesExpected` may be reported as -1.
 
 @see progressHandler
 
 */

@property (nonatomic, copy) LFURLSessionDataTaskDidReceiveDataBlock didReceiveDataHandler;

/** Called by `NSURLSessionDataDelegate` method `URLSession:dataTask:didReceiveData:`
 
 Use this block if you do want the `LFNetworkDataTaskOperation` to build a `NSData` object
 with the entire response, but simply want to be notified of its progress.
 
 Uses the following typedef:
 
 typedef void(^LFURLSessionDataTaskProgressBlock)(LFNetworkDataTaskOperation *operation,
 long long totalBytesExpected,
 long long bytesReceived);
 
 @note The `totalBytesExpected` parameter of this block is provided by the server, and as such, it is not entirely reliable. Also note that if it could not be determined, `totalBytesExpected` may be reported as -1.
 
 @see didReceiveDataHandler
 
 */

@property (nonatomic, copy) LFURLSessionDataTaskProgressBlock progressHandler;

/** Called by `NSURLSessionDataDelegate` method `URLSession:dataTask:willCacheResponse:completionHandler:`
 
 Uses the following typedef:
 
 typedef void(^LFURLSessionDataTaskWillCacheResponseBlock)(LFNetworkDataTaskOperation *operation,
 NSCachedURLResponse *proposedResponse,
 void(^completionHandler)(NSCachedURLResponse *cachedURLResponse));
 */

@property (nonatomic, copy) LFURLSessionDataTaskWillCacheResponseBlock willCacheResponseHandler;

/** Called by `NSURLSessionDataDelegate` method `URLSession:dataTask:didBecomeDownloadTask:`
 
 Uses the following typdef:
 
 typedef void(^LFURLSessionDataTaskWillBecomeDownloadTaskBlock)(LFNetworkDataTaskOperation *operation,
 NSURLSessionDownloadTask *downloadTask);
 */

@property (nonatomic, copy) LFURLSessionDataTaskWillBecomeDownloadTaskBlock willBecomeDownloadTaskHandler;


@end
