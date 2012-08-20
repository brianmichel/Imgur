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

typedef enum ImgurAPIType {
  ImgurAPITypeAnonymous = 0,
  ImgurAPITypeAuthenticated
} ImgurAPIType;

NSDictionary * ImgurCreateParamsDictionary(NSString *name, NSString *title, NSString *caption);

typedef void(^ImgurCompletionHandler)(NSError *, NSDictionary *);
typedef void(^ImgurOAuthCompletionHandler)(NSError *);

@class Imgur;
@protocol ImgurDelegate <NSObject>

- (void)imgurNeedsAuthentication:(Imgur *)imgur;
- (void)imgurNeedsAuthorizationForURL:(NSURL *)url;

@end

@interface Imgur : RSOAuthEngine

@property (assign, readonly) ImgurAPIType apiType;
@property (strong, readonly) NSString *developerKey;
@property (strong, readonly) NSString *userName;
@property (copy, readwrite) ImgurOAuthCompletionHandler oauthCompletionHandler;

@property (assign) id<ImgurDelegate> delegate;

+ (NSURL *)urlForHashCode:(NSString *)hashCode;

- (id)initWithKey:(NSString *)key andSecret:(NSString *)secret;
- (id)initWithDeveloperKey:(NSString *)key;

- (void)resumeAuthenticationFlowFromURL:(NSURL *)url;

- (void)fetchImageForHashCode:(NSString *)hashCode withCompletionHandler:(ImgurCompletionHandler)handler;

- (void)uploadImageFromData:(NSData *)imageData withParams:(NSDictionary *)parameters andCompletionHandler:(ImgurCompletionHandler)handler;
- (void)uploadImageFromURL:(NSURL *)imageURL withParams:(NSDictionary *)parameters andCompletionHandler:(ImgurCompletionHandler)handler;

@end
