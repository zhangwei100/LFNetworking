//
//  LFHTTPSessionManager.h
//
//
//  Created by Wei Zhang on 09/01/14.
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
#import "AFURLResponseSerialization.h"
#import "AFURLRequestSerialization.h"

/** `LFHTTPSessionManager` is a subclass of `LFURLSessionManager` with convenience methods for making HTTP requests.
 */

@interface LFHTTPSessionManager : LFURLSessionManager

/**
 The URL used to monitor reachability, and construct requests from relative paths in methods like `requestWithMethod:URLString:parameters:`, and the `GET` / `POST` / et al. convenience methods.
 */
@property (readonly, nonatomic, strong) NSURL *baseURL;

/**
 Requests created with `requestWithMethod:URLString:parameters:` & `multipartFormRequestWithMethod:URLString:parameters:constructingBodyWithBlock:` are constructed with a set of default headers using a parameter serialization specified by this property. By default, this is set to an instance of `AFHTTPRequestSerializer`, which serializes query string parameters for `GET`, `HEAD`, and `DELETE` requests, or otherwise URL-form-encodes HTTP message bodies.
 
 @warning `requestSerializer` must not be `nil`.
 */
@property (nonatomic, strong) AFHTTPRequestSerializer <AFURLRequestSerialization> * requestSerializer;

/**
 Responses sent from the server in data tasks created with `dataTaskWithRequest:success:failure:` and run using the `GET` / `POST` / et al. convenience methods are automatically validated and serialized by the response serializer. By default, this property is set to an instance of `AFJSONResponseSerializer`.
 
 @warning `responseSerializer` must not be `nil`.
 */
@property (nonatomic, strong) AFHTTPResponseSerializer <AFURLResponseSerialization> * responseSerializer;

///---------------------
/// @name Initialization
///---------------------

/**
 Creates and returns an `LFHTTPSessionManager` object.
 */
+ (instancetype)manager;

/**
 Initializes an `LFHTTPSessionManager` object with the specified base URL.
 
 @param url The base URL for the HTTP client.
 
 @return The newly-initialized HTTP client
 */
- (instancetype)initWithBaseURL:(NSURL *)url;

/**
 Initializes an `LFHTTPSessionManager` object with the specified base URL.
 
 This is the designated initializer.
 
 @param url The base URL for the HTTP client.
 @param configuration The configuration used to create the managed session.
 
 @return The newly-initialized HTTP client
 */
- (instancetype)initWithBaseURL:(NSURL *)url
           sessionConfiguration:(NSURLSessionConfiguration *)configuration;

///---------------------------
/// @name Making HTTP Requests
///---------------------------

/** Prepare and initiate application/x-www-form-urlencoded request
 *
 * @param url          URL to use for POST request.
 * @param parameters   `NSDictionary` for parameters to add to POST request; may be `nil` if no additional parameters. This accepts `NSString`, `NSNumber`, `NSDate`, and `NSData` objects. If the object is `NSData`, it simply converts it to a UTF8 string. If `NSDate`, this creates RFC 3339 date string (with milliseconds).
 * @param completion   Block to be invoked when POST request completes (or fails).
 *
 * @return             The operation that has been started.
 */
- (LFNetworkDataTaskOperation *)POST:(NSString *)urlString
                          parameters:(id)parameters
                             success:(void (^)(LFNetworkDataTaskOperation *taskOperation, id responseObject))success
                             failure:(void (^)(LFNetworkDataTaskOperation *taskOperation, NSError *error))failure;

/** Prepare and initiate application/x-www-form-urlencoded request
 *
 * @param url          URL to use for POST request.
 * @param parameters   `NSDictionary` for parameters to add to POST request; may be `nil` if no additional parameters. This accepts `NSString`, `NSNumber`, `NSDate`, and `NSData` objects. If the object is `NSData`, it simply converts it to a UTF8 string. If `NSDate`, this creates RFC 3339 date string (with milliseconds).
 * @param completion   Block to be invoked when POST request completes (or fails).
 *
 * @return             The operation that has been started.
 */
- (LFNetworkDataTaskOperation *)POST:(NSString *)urlString
                          parameters:(id)parameters
           constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                             success:(void (^)(LFNetworkDataTaskOperation *taskOperation, id responseObject))success
                             failure:(void (^)(LFNetworkDataTaskOperation *taskOperation, NSError *error))failure;

/** Prepare and initiate application/x-www-form-urlencoded request
 *
 * @param url          URL to use for DELETE request.
 * @param parameters   `NSDictionary` for parameters to add to POST request; may be `nil` if no additional parameters. This accepts `NSString`, `NSNumber`, `NSDate`, and `NSData` objects. If the object is `NSData`, it simply converts it to a UTF8 string. If `NSDate`, this creates RFC 3339 date string (with milliseconds).
 * @param completion   Block to be invoked when DELETE request completes (or fails).
 *
 * @return             The operation that has been started.
 */
- (LFNetworkDataTaskOperation *)DELETE:(NSString *)urlString
                            parameters:(id)parameters
                               success:(void (^)(LFNetworkDataTaskOperation *taskOperation, id responseObject))success
                               failure:(void (^)(LFNetworkDataTaskOperation *taskOperation, NSError *error))failure;

/** Prepare and initiate application/x-www-form-urlencoded request
 *
 * @param url          URL to use for PUT request.
 * @param parameters   `NSDictionary` for parameters to add to POST request; may be `nil` if no additional parameters. This accepts `NSString`, `NSNumber`, `NSDate`, and `NSData` objects. If the object is `NSData`, it simply converts it to a UTF8 string. If `NSDate`, this creates RFC 3339 date string (with milliseconds).
 * @param completion   Block to be invoked when PUT request completes (or fails).
 *
 * @return             The operation that has been started.
 */
- (LFNetworkDataTaskOperation *)PUT:(NSString *)urlString
                         parameters:(id)parameters
                            success:(void (^)(LFNetworkDataTaskOperation *taskOperation, id responseObject))success
                            failure:(void (^)(LFNetworkDataTaskOperation *taskOperation, NSError *error))failure;

/**
 Creates and runs an `NSURLSessionDataTask` with a `GET` request.
 
 @param URLString The URL string used to create the request URL.
 @param parameters The parameters to be encoded according to the client request serializer.
 @param success A block object to be executed when the task finishes successfully. This block has no return value and takes two arguments: the data task, and the response object created by the client response serializer.
 @param failure A block object to be executed when the task finishes unsuccessfully, or that finishes successfully, but encountered an error while parsing the response data. This block has no return value and takes a two arguments: the data task and the error describing the network or parsing error that occurred.
 
 @see -dataTaskWithRequest:completionHandler:
 */
- (LFNetworkDataTaskOperation *)GET:(NSString *)urlString
                         parameters:(id)parameters
                            success:(void (^)(LFNetworkDataTaskOperation *operation, id responseObject))success
                            failure:(void (^)(LFNetworkDataTaskOperation *operation, NSError *error))failure;

@end
