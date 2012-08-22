//
//  Imgur.h
//  Imgur
//
//  Created by Brian Michel on 8/19/12.
//  Copyright (c) 2012 Foureyes. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MKNetworkKit.h"
#import "RSOAuthEngine.h"

OBJC_EXTERN NSString * const kImgurAPIBaseURL;
OBJC_EXTERN NSString * const kImgurAPIVersion;
OBJC_EXTERN NSString * const kImgurCallbackURL;
OBJC_EXTERN NSString * const kImgurDictionaryImageKey;

typedef enum ImgurAPIType {
  ImgurAPITypeAnonymous = 0,
  ImgurAPITypeAuthenticated
} ImgurAPIType;

NSDictionary * ImgurCreateParamsDictionary(NSString *name, NSString *title, NSString *caption);

typedef void(^ImgurCompletionHandler)(NSError *, NSDictionary *);
typedef void(^ImgurOAuthCompletionHandler)(NSError *);

@class Imgur;
@protocol ImgurDelegate <NSObject>

- (void)imgurNeedsAuthorizationForURL:(NSURL *)url;

@end

/*
 Defines Imgur API
 */
@interface Imgur : RSOAuthEngine

@property (assign, readonly) ImgurAPIType apiType;
@property (strong, readonly) NSString *developerKey;
@property (strong, readonly) NSString *userName;
@property (copy, readwrite) ImgurOAuthCompletionHandler oauthCompletionHandler;

@property (assign) id<ImgurDelegate> delegate;

/* Convenience method for generating image url
 @param hashCode Short code for generating the full image url.
 @return Returns an NSURL that may be used to fetch the image at the desired code.
 */
+ (NSURL *)urlForHashCode:(NSString *)hashCode;

/* Designated initializer for accessing the Authenticated Imgur API
 @param key Your OAuth developer consumer key.
 @param secret Your OAuth developer consumer secret.
 @return Returns an initialized Imgur API object.
 @warning *Note:* You *MUST* set yourself as the delegate to get the OAuth callbacks!
 */
- (id)initWithKey:(NSString *)key andSecret:(NSString *)secret;

/* Designated initializer for accessing the Anonymous Imgur API
 @param key Your Anonymous developer key.
 @return Returns an initliazed Imgur API object.
 */
- (id)initWithDeveloperKey:(NSString *)key;

/* Allows the resuming of the OAuth authorization flow
 @param url URL returned by authorizing the Request Token.
 */
- (void)resumeAuthenticationFlowFromURL:(NSURL *)url;

/* Retreive current Imgur site statistics
 @param handler An `ImgurCompletionHander` that will be called after the response has been returned.
 */
- (void)fetchSiteStatisticsWithCompletionHandler:(ImgurCompletionHandler)handler;

/* Retreive an image for a given hashCode
 @param hashCode A valid Imgur hash code for an image.
 @param handler An `ImgurCompletionHandler` that will be called after the response has been returned.
 */
- (void)fetchImageForHashCode:(NSString *)hashCode withCompletionHandler:(ImgurCompletionHandler)handler;

/* Retreive information about a given Imgur hashCode
 */
- (void)fetchImageInformationForHashCode:(NSString *)hashCode withCompletionHandler:(ImgurCompletionHandler)handler;

/* Retreive an album of photos for a given album ID
 @param albumID A valid Imgur album ID.
 @param handler An `ImgurCompletionHandler` that will be called after the response has been returned.
 */
- (void)fetchAlbumForID:(NSString *)albumID withCompletionHandler:(ImgurCompletionHandler)handler;

/* Delete an image for a given delete hash
 @param deleteHash A valid Imgur delete hash code.
 @param handler An `ImgurCompletionHandler` that will be called after the response has been returned.
 */
- (void)deleteImageForDeleteHash:(NSString *)deleteHash withCompletionHandler:(ImgurCompletionHandler)handler;

/* Upload an image for the given data
 @param imageData An NSData representing the image for which upload is desired.
 @param parameters A dictionary representing various information about the image.
 @param handler An `ImgurCompletionHandler` that will be called after the response has been returned.
 @see ImgurCreateParamsDictionary
 */
- (void)uploadImageFromData:(NSData *)imageData withParams:(NSDictionary *)parameters andCompletionHandler:(ImgurCompletionHandler)handler;

/* Sideload an image from a given URL
 @param imageURL A URL that points to an image you wish to sideload into Imgur.
 @param parameters A dictionary representing various information about the image.
 @parameter handler An `ImgurCompletionHandler` that will be called after the response has been returned.
 @see ImgurCreateParamsDictionary
 */
- (void)uploadImageFromURL:(NSURL *)imageURL withParams:(NSDictionary *)parameters andCompletionHandler:(ImgurCompletionHandler)handler;

/* Initialize a MKNKResponseBlock and MKNKErrorBlock for a given handler
 @param outCompletionBlock A pointer to an MKNKResponseBlock that will be initalized with handler.
 @param outErrorBlock A pointer to an MKNKErrorBlock that will be initialized with handler.
 @param handler An `ImgurCompletionHandler` that will be used to initialize the completion and error blocks.
 */
- (void)initializeCompletionBlock:(MKNKResponseBlock *)outCompletionBlock andErrorBlock:(MKNKErrorBlock *)outErrorBlock forHandler:(ImgurCompletionHandler)handler;

@end
