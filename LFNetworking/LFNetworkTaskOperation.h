//
//  LFNetworkTaskOperation.h
//  LFURLSessionManager
//
//  Created by Wei Zhang on 9/01/14.
//  Copyright (c) 2014 Wei Zhang. All rights reserved.
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

#import <Foundation/Foundation.h>

@class LFNetworkTaskOperation;
@class LFNetworkDataTaskOperation;

typedef void(^LFURLSessionTaskDidCompleteWithDataErrorBlock)(LFNetworkTaskOperation *operation,
                                                NSData *data,
                                                NSError *error);
typedef void(^LFURLSessionTaskDidReceiveChallengeBlock)(LFNetworkTaskOperation *operation,
                                                    NSURLAuthenticationChallenge *challenge,
                                                    void(^completionHandler)(NSURLSessionAuthChallengeDisposition dispostion, NSURLCredential *credential)
                                                    );
typedef void(^LFURLSessionTaskDidSendBodyDataBlock)(LFNetworkTaskOperation *operation,
                                                    int64_t byteSent,
                                                    int64_t totalByteSent,
                                                    int64_t totalByteExpectedToSend);
typedef void(^LFURLSessionTaskNeedNewBodyStreamBlock)(LFNetworkTaskOperation *operation,
                                                      void(^completionHandler)(NSInputStream *bodyStream));
typedef void(^LFURLSessionTaskWillPerformHTTPRedirectionBlock)(LFNetworkTaskOperation *operation,
                                                               NSHTTPURLResponse *response,
                                                               NSURLRequest *request,
                                                               void(^completionHandler)(NSURLRequest *));


/** Base NSURLSessionTask operation class.
 *
 * This is an abstract class is not intended to be used by itself. Instead, use one of its subclasses, `<LFNetworkDataTaskOperation>`, `<LFNetworkDownloadTaskOperation>`, or `<LFNetworkUploadTaskOperation>`.
 */

@interface LFNetworkTaskOperation : NSOperation <NSURLSessionTaskDelegate>

/// ----------------
/// @name Properties
/// ----------------

/// The `NSURLSessionTask` associated with this operation

@property (nonatomic, weak) NSURLSessionTask *task;

/// The `NSURLCredential` to be used if authentication challenge received.

@property (nonatomic, strong) NSURLCredential *credential;

/** Did complete handler block
 
 Uses the following typdef:
 
 typedef void(^LFURLSessionTaskDidCompleteWithDataErrorBlock)(LFNetworkTaskOperation *operation,
 NSData *data,
 NSError *error);
 */

@property (nonatomic, copy) LFURLSessionTaskDidCompleteWithDataErrorBlock didCompleteWithDataErrorHandler;

/** Did receive challenge handler block
 
 Uses the following typdef:
 
 typedef void(^LFURLSessionDidReceiveChallengeBlock)(LFNetworkTaskOperation *operation,
 NSURLAuthenticationChallenge *challenge,
 void(^completionHandler)(NSURLSessionAuthChallengeDisposition dispostion, NSURLCredential *credential)
 );
 */

@property (nonatomic, copy) LFURLSessionTaskDidReceiveChallengeBlock didReceiveChallengeHandler;

/** Did send body data handler block
 
 Uses the following typdef:
 
 typedef void(^LFURLSessionTaskDidSendBodyDataBlock)(LFNetworkTaskOperation *operation,
 int64_t byteSent,
 int64_t totalByteSent,
 int64_t totalByteExpectedToSend);
 */

@property (nonatomic, copy) LFURLSessionTaskDidSendBodyDataBlock didSendBodyDataHandler;

/** Need new body stream handler block
 
 Uses the following typedef:
 
 typedef void(^LFURLSessionTaskNeedNewBodyStreamBlock)(LFNetworkTaskOperation *operation,
 void(^completionHandler)(NSInputStream *bodyStream));
 */

@property (nonatomic, copy) LFURLSessionTaskNeedNewBodyStreamBlock needNewBodyStreamHandler;

/** Will perform HTTP redirect handler block
 
 Uses the following typedef:
 
 typedef void(^LFURLSessionTaskWillPerformHTTPRedirectionBlock)(LFNetworkTaskOperation *operation,
 NSHTTPURLResponse *response,
 NSURLRequest *request,
 void(^completionHandler)(NSURLRequest *));
 */

@property (nonatomic, copy) LFURLSessionTaskWillPerformHTTPRedirectionBlock willPerformHTTPRedirectHandler;

///-------------------------------
/// @name Managing Callback Queues
///-------------------------------

/**
 The dispatch queue for `completionBlock`. If `NULL` (default), the main queue is used.
 */
@property (nonatomic, strong) dispatch_queue_t completionQueue;

/// --------------------
/// @name Initialization
/// --------------------

/** Create NetworkTaskOperation
 *
 * @param session The `NSURLSession` for which the task operation should be created.
 * @param request The `NSURLRequest` for the task operation.
 *
 * @return        Returns NetworkTaskOperation.
 */

- (instancetype)initWithSession:(NSURLSession *)session
                        request:(NSURLRequest *)request;

/// ------------------------------
/// @name Inquire regarding status
/// ------------------------------

/** Return whether this operation respond to a challenge.
 *
 * @return `YES` if it can respond to challenge. `NO` if the session manager will try.
 */

- (BOOL)canRespondToChallenge;

/// ----------------------
/// @name Manage operation
/// ----------------------

/** Complete the operation.
 */

- (void)completeOperation;

@end
