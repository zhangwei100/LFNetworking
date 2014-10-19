//
//  LFURLSessionManager.h
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
#import "LFNetworkDataTaskOperation.h"
#import "AFSecurityPolicy.h"

@class LFURLSessionManager;

typedef BOOL(^LFURLSessionDidFinishEventsHandler)(LFURLSessionManager *manager);
typedef void(^LFURLSessionDidBecomeInvalidWithErrorBlock)(LFURLSessionManager *manger,
                                                          NSError *error);
typedef void(^LFURLSessionDidReceiveChallengeBlock)(LFURLSessionManager *manager,
                                                    NSURLAuthenticationChallenge *challenge,
                                                    void (^completionHandler)(NSURLSessionAuthChallengeDisposition dispostion, NSURLCredential *credential));
typedef void(^LFURLSessionManagerURLSessionTaskDidCompleteBlock)(LFURLSessionManager *manager,
                                                              NSURLSessionTask *task,
                                                              NSError *error);
@interface LFURLSessionManager : NSObject

/// ----------------
/// @name Properties
/// ----------------

/** The completion handler to be set by app delegate's `handleEventsForBackgroundURLSession`
*  and to be called by `URLSessionDidFinishEventsHandler`.
*/
@property (nonatomic, copy) void (^backgroundSessionCompletionHandler)(void);

/** The block that will be called by `URLSessionDidFinishEventsForBackgroundURLSession:`.

This uses the following typedef:

typedef BOOL(^URLSessionDidFinishEventsHandler)(LFURLSessionManager *manager);

@note If this block calls the completion handler, it should return `NO`, to inform the default `URLSessionDidFinishEvents` method
that it does not need to call the `completionHandler`. It should also make sure to `nil` the `completionHandler` after it calls it.

If this block does not call the completion handler itself, it should return `YES` to inform
the default routine that it should call the `completionHandler` and perform the necessary clean-up.
*/

@property (nonatomic, copy) LFURLSessionDidFinishEventsHandler urlSessionDidFinishEventsHandler;

/** The block that will be called by `URLSession:didBecomeInvalidWithError:`.

This uses the following typedef:

typedef void(^LFURLSessionDidBecomeInvalidWithErrorBlock)(LFURLSessionManager *manger,
NSError *error);

*/

@property (nonatomic, copy) LFURLSessionDidBecomeInvalidWithErrorBlock didBecomeInvalidHandler;

/** The block that will be called by `URLSession:didReceiveChallenge:completionHandler:`.

This uses the following typedef:

typedef void(^DidReceiveChallenge)(NetworkManager *manager,
NSURLAuthenticationChallenge *challenge,

*/

@property (nonatomic, copy) LFURLSessionDidReceiveChallengeBlock didReceiveChallengeHandler;

/** The block that will be called by `URLSession:task:didCompleteWithError:`.
 Generally we keep the task methods at the task operation class level, but for background
 downloads, we may lose the operations when the app is killed.
 
 This uses the following typedef:
 
 typedef void(^LFURLSessionManagerURLSessionTaskDidCompleteBlock)(LFURLSessionManager *manager,
 NSURLSessionTask *task,
 NSError *error);
 
 */
@property (nonatomic, copy) LFURLSessionManagerURLSessionTaskDidCompleteBlock didCompleteHandler;

///-------------------------------
/// @name Managing Security Policy
///-------------------------------

/**
 The security policy used by created request operations to evaluate server trust for secure connections. `LFURLSessionManager` uses the `defaultPolicy` unless otherwise specified.
 */
@property (nonatomic, strong) AFSecurityPolicy *securityPolicy;

/**
 The managed session.
 */
@property (readonly, nonatomic, strong) NSURLSession *session;

/** Credential to be tried if receive session-level authentication challenge.
 */
@property (nonatomic, strong) NSURLCredential *credential;

/** The GCD queue to which completion/progress blocks will be dispatched. If `nil`, it will use `dispatch_get_main_queue()`.
 */
@property (nonatomic, strong) dispatch_queue_t completionQueue;

///---------------------
/// @name Initialization
///---------------------

/**
 Creates and returns a manager for a session created with the specified configuration. This is the designated initializer.
 
 @param configuration The configuration used to create the managed session.
 
 @return A manager for a newly-created session.
 */
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration;

/** Create data task operation
 *
 * @param request The `NSURLRequest`
 * @param progressHandler The block that will be called with as the data is being downloaded.
 * @param didCompleteHandler The block that will be called when task is done.
 *
 * @return Returns `LFNetworkDataTaskOperation`.
 *
 * @note If you supply `progressHandler`, it is assumed that you will take responsibility for
 *       handling the individual data chunks as they come in. If you don't provide this block, this
 *       class will aggregate all of the individual `NSData` objects into one final one for you.
 *
 * @note The progress/completion blocks will, by default, be called on the main queue. If you want
 *       to use a different GCD queue, specify a non-nil `<completionQueue>` value.
 */

- (LFNetworkDataTaskOperation *)dataOperationWithRequest:(NSURLRequest *)request
                                         progressHandler:(LFURLSessionDataTaskProgressBlock)progressHandler
                                       completionHandler:(LFURLSessionTaskDidCompleteBlock)didCompleteHandler;

/** Create data task operation.
 *
 * @param url The `NSURL`.
 * @param progressHandler The block that will be called with as the data is being downloaded.
 * @param didCompleteHandler The block that will be called when the task is done.
 *
 * @return Returns `LFNetworkDataTaskOperation`.
 *
 * @note If you supply `progressHandler`, it is assumed that you will take responsibility for
 *       handling the individual data chunks as they come in. If you don't provide this block, this
 *       class will aggregate all of the individual `NSData` objects into one final one for you.
 *
 * @note The progress/completion blocks will, by default, be called on the main queue. If you want
 *       to use a different GCD queue, specify a non-nil `<completionQueue>` value.
 */

- (LFNetworkDataTaskOperation *)dataOperationWithURL:(NSURL *)url
                                     progressHandler:(LFURLSessionDataTaskProgressBlock)progressHandler
                                   completionHandler:(LFURLSessionTaskDidCompleteBlock)didCompleteHandler;

/// -----------------------------------------------
/// @name NSOperationQueue utility methods
/// -----------------------------------------------

/** Operation queue for network requests.
*
* If you want, you can add operations to the NSURLSessionManager-provided operation queue.
* This method is provided in case you want to customize the queue or add operations to it yourself.
*
* @return An `NSOperationQueue`. This will instantiate a queue if one hadn't already been created.
 */

+ (NSOperationQueue *)sharedNetworkOperationQueue;

/** Add operation.
 *
 * A convenience method to add operation to the network manager's `networkQueue` operation queue.
 *
 * @param operation The operation to be added to the queue.
 */

- (void)addOperation:(NSOperation *)operation;

@end
