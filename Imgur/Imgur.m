//
//  Imgur.m
//  Imgur
//
//  Created by Brian Michel on 8/19/12.
//  Copyright (c) 2012 Foureyes. All rights reserved.
//

#import "Imgur.h"

NSString * const kImgurAPIBaseURL = @"api.imgur.com";
NSString * const kImgurImageBaseURL = @"http://i.imgur.com";
NSString * const kImgurAPIVersion = @"2.0";

NSString * const kImgurParamsNameKey = @"name";
NSString * const kImgurParamsTitleKey = @"title";
NSString * const kImgurParamsCaptionKey = @"caption";
NSString * const kImgurDictionaryImageKey = @"image";

NSString * const kImgurCallbackURL = @"imgur://auth_token";
NSString * const kImgurRequestTokenPath = @"oauth/request_token";
NSString * const kImgurAccessTokenPath = @"oauth/access_token";

#define IMGUR_AUTHORIZE(__TOKEN__) [NSString stringWithFormat:@"http://%@/oauth/authorize?%@",kImgurAPIBaseURL, __TOKEN__]

NSDictionary * ImgurCreateParamsDictionary(NSString *name, NSString *title, NSString *caption) {
  return @{kImgurParamsNameKey : name,
          kImgurParamsTitleKey : title,
        kImgurParamsCaptionKey : caption};
}

@interface Imgur ()
- (NSString *)urlForImages;
@end

@implementation Imgur

@synthesize developerKey = _developerKey;
@synthesize apiType = _apiType;
@synthesize userName = _userName;
@synthesize oauthCompletionHandler = _oauthCompletionHandler;

#pragma mark - Initializers

- (id)initWithKey:(NSString *)key andSecret:(NSString *)secret {
  self = [super initWithHostName:kImgurAPIBaseURL customHeaderFields:nil signatureMethod:RSOAuthHMAC_SHA1 consumerKey:key consumerSecret:secret callbackURL:kImgurCallbackURL];
  if (self) {
    //Custom initialization
    _apiType = ImgurAPITypeAuthenticated;
    [self retrieveOAuthTokenFromKeychain];
  }
  return self;
}

- (id)initWithDeveloperKey:(NSString *)key {
  
  NSAssert(key, @"Developer key cannot be nil");
  
  self = [super initWithHostName:kImgurAPIBaseURL customHeaderFields:nil];
  if (self) {
    _developerKey = key;
    _apiType = ImgurAPITypeAnonymous;
  }
  return self;
}

#pragma mark - OAuth Access Token store/retrieve

- (void)removeOAuthTokenFromKeychain
{
  // Build the keychain query
  NSMutableDictionary *keychainQuery = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        (__bridge_transfer NSString *)kSecClassGenericPassword, (__bridge_transfer NSString *)kSecClass,
                                        self.consumerKey, kSecAttrService,
                                        self.consumerKey, kSecAttrAccount,
                                        kCFBooleanTrue, kSecReturnAttributes,
                                        nil];
  
  // If there's a token stored for this user, delete it
  SecItemDelete((__bridge_retained CFDictionaryRef) keychainQuery);
}

- (void)storeOAuthTokenInKeychain
{
  // Build the keychain query
  NSMutableDictionary *keychainQuery = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        (__bridge_transfer NSString *)kSecClassGenericPassword, (__bridge_transfer NSString *)kSecClass,
                                        self.consumerKey, kSecAttrService,
                                        self.consumerKey, kSecAttrAccount,
                                        kCFBooleanTrue, kSecReturnAttributes,
                                        nil];
  
  CFTypeRef resData = NULL;
  
  // If there's a token stored for this user, delete it first
  SecItemDelete((__bridge_retained CFDictionaryRef) keychainQuery);
  
  // Build the token dictionary
  NSMutableDictionary *tokenDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          self.token, @"oauth_token",
                                          self.tokenSecret, @"oauth_token_secret",
                                          nil];
  
  // Add the token dictionary to the query
  [keychainQuery setObject:[NSKeyedArchiver archivedDataWithRootObject:tokenDictionary]
                    forKey:(__bridge_transfer NSString *)kSecValueData];
  
  // Add the token data to the keychain
  // Even if we never use resData, replacing with NULL in the call throws EXC_BAD_ACCESS
  SecItemAdd((__bridge_retained CFDictionaryRef)keychainQuery, (CFTypeRef *) &resData);
}

- (BOOL)retrieveOAuthTokenFromKeychain
{
  // Build the keychain query
  NSMutableDictionary *keychainQuery = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        (__bridge_transfer NSString *)kSecClassGenericPassword, (__bridge_transfer NSString *)kSecClass,
                                        self.consumerKey, kSecAttrService,
                                        self.consumerKey, kSecAttrAccount,
                                        kCFBooleanTrue, kSecReturnData,
                                        kSecMatchLimitOne, kSecMatchLimit,
                                        nil];
  
  // Get the token data from the keychain
  CFTypeRef resData = NULL;
  
  // Get the token dictionary from the keychain
  if (SecItemCopyMatching((__bridge_retained CFDictionaryRef) keychainQuery, (CFTypeRef *) &resData) == noErr)
  {
    NSData *resultData = (__bridge_transfer NSData *)resData;
    
    if (resultData)
    {
      NSMutableDictionary *tokenDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:resultData];
      
      if (tokenDictionary) {
        [self setAccessToken:[tokenDictionary objectForKey:@"oauth_token"]
                      secret:[tokenDictionary objectForKey:@"oauth_token_secret"]];
        return YES;
      }
    }
  }
  return NO;
}

#pragma mark - Image Fetching
- (void)fetchImageForHashCode:(NSString *)hashCode withCompletionHandler:(ImgurCompletionHandler)handler {
  MKNetworkOperation *op = [self operationWithURLString:[[Imgur urlForHashCode:hashCode] absoluteString]];
  [op onCompletion:^(MKNetworkOperation *completedOperation) {
    if (handler) {
      handler(nil, @{kImgurDictionaryImageKey : [completedOperation responseData]});
    }
  } onError:^(NSError *error) {
    if (handler) {
      handler(error, nil);
    }
  }];
  [self enqueueOperation:op];
}

#pragma mark - Image Uploading

- (void)authenticateWithCompletionHandler:(ImgurOAuthCompletionHandler)handler {
  self.oauthCompletionHandler = handler;
  
  [self resetOAuthToken];
  
  MKNetworkOperation *reqTokenOp = [self operationWithPath:kImgurRequestTokenPath params:nil httpMethod:@"POST"];
  
  [reqTokenOp onCompletion:^(MKNetworkOperation *completedOperation) {
    [self fillTokenWithResponseBody:[completedOperation responseString] type:RSOAuthRequestToken];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(imgurNeedsAuthorizationForURL:)]) {
      [self.delegate imgurNeedsAuthorizationForURL:[NSURL URLWithString:IMGUR_AUTHORIZE(self.token)]];
    }
  } onError:^(NSError *error) {
    if (handler) {handler(error);}
  }];
  
  [self enqueueSignedOperation:reqTokenOp];
}
- (void)resumeAuthenticationFlowFromURL:(NSURL *)url {
  [self fillTokenWithResponseBody:url.query type:RSOAuthRequestToken];
  
  MKNetworkOperation *reqTokenOp = [self operationWithPath:kImgurAccessTokenPath params:nil httpMethod:@"POST"];
  
  [reqTokenOp onCompletion:^(MKNetworkOperation *completedOperation) {
    [self fillTokenWithResponseBody:[completedOperation responseString] type:RSOAuthAccessToken];
    [self storeOAuthTokenInKeychain];
    if (self.oauthCompletionHandler) self.oauthCompletionHandler(nil);
    self.oauthCompletionHandler = nil;
  } onError:^(NSError *error) {
    if (self.oauthCompletionHandler) self.oauthCompletionHandler(error);
    self.oauthCompletionHandler = nil;
  }];
}

- (void)uploadImageFromURL:(NSURL *)imageURL withParams:(NSDictionary *)parameters andCompletionHandler:(ImgurCompletionHandler)handler {
  NSMutableDictionary *additionalParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
  additionalParameters[@"image"] = [imageURL absoluteString];
  additionalParameters[@"type"] = @"url";
  [self uploadImageWithParameters:additionalParameters andCompletionHandler:handler];
}

- (void)uploadImageFromData:(NSData *)imageData withParams:(NSDictionary *)parameters andCompletionHandler:(ImgurCompletionHandler)handler {
  NSMutableDictionary *additionalParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
  additionalParameters[@"image"] = imageData;
  additionalParameters[@"type"] = @"file";
  [self uploadImageWithParameters:additionalParameters andCompletionHandler:handler];
}

- (void)uploadImageWithParameters:(NSMutableDictionary *)parameters andCompletionHandler:(ImgurCompletionHandler)handler {
  if (self.apiType == ImgurAPITypeAnonymous) {
    parameters[@"key"] = _developerKey;
  }
  
  if (self.apiType == ImgurAPITypeAuthenticated && !self.isAuthenticated) {
    [self authenticateWithCompletionHandler:^(NSError *authError) {
      if (!authError) {
        MKNetworkOperation *op = [self operationWithPath:[self urlForImages] params:parameters httpMethod:@"POST"];
        
        [op onCompletion:^(MKNetworkOperation *completedOperation) {
          //success
          NSError *parseError = nil;
          NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:[completedOperation responseData] options:0 error:&parseError];
          if (handler) {
            handler(parseError, responseDictionary);
          }
        } onError:^(NSError *error) {
          if (handler) {
            handler(error, nil);
          }
        }];
        
        [self enqueueOperation:op];
      }
    }];
  } else {
    
    MKNetworkOperation *op = [self operationWithPath:[self urlForImages] params:parameters httpMethod:@"POST"];
    
    [op onCompletion:^(MKNetworkOperation *completedOperation) {
      //success
      NSError *parseError = nil;
      NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:[completedOperation responseData] options:0 error:&parseError];
      if (handler) {
        handler(parseError, responseDictionary);
      }
    } onError:^(NSError *error) {
      if (handler) {
        handler(error, nil);
      }
    }];
    
    [self enqueueOperation:op];
  }
}

#pragma mark - Helpers
+ (NSURL *)urlForHashCode:(NSString *)hashCode {
  return [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@.jpg", kImgurImageBaseURL, hashCode]];
}

- (NSString *)urlForImages {
  NSString *endPath = nil;
  switch (self.apiType) {
    case ImgurAPITypeAnonymous:
      endPath = @"2/upload.json";
      break;
    case ImgurAPITypeAuthenticated:
      endPath = @"2/account/images.json";
    default:
      break;
  }
  
  return endPath ? endPath : nil;
}

@end
