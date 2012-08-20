//
//  ImgurSpecs.m
//  Imgur
//
//  Created by Brian Michel on 8/19/12.
//  Copyright (c) 2012 Foureyes. All rights reserved.
//

#define DeveloperKey @"e32d305b730a589d4b769c97944d9fb8"
#define ConsumerKey @"4015cca3d185c756e87c32a84b32dfef0503002b7"
#define ConsumerSecret @"46aeff30516e5596d1260db788f7821f"
#define CatImageURLString @"http://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Feral-kitten-eating-adult-cottontail-rabbit.jpg/220px-Feral-kitten-eating-adult-cottontail-rabbit.jpg"

SpecBegin(ImgurSpec)

describe(@"imgur", ^{
  __block Imgur *authenticated = [[Imgur alloc] initWithKey:ConsumerKey andSecret:ConsumerSecret];
  
  it(@"should have test values set", ^{
    expect(DeveloperKey).toNot.beNil;
    expect(ConsumerKey).toNot.beNil;
    expect(ConsumerSecret).toNot.beNil;
  });
  
  beforeAll(^{
    [Expecta setAsynchronousTestTimeout:5];
  });
  
  it(@"should have correct API type set", ^{
    expect(authenticated.apiType).to.equal(ImgurAPITypeAuthenticated);
  });
  
  it(@"should get me an image for a known good hash", ^{
    __block BOOL loaded = NO;
    [authenticated fetchImageForHashCode:@"aqe99" withCompletionHandler:^(NSError *error, NSDictionary *resultsDictionary) {
      expect(error).to.beNil;
      expect(resultsDictionary).toNot.beNil;
      loaded = YES;
    }];
    [$ waitUntil:^{return (BOOL)(loaded == YES);}];
  });
  
  it(@"should fetch site statistics", ^{
    __block BOOL loaded = NO;
    [authenticated fetchSiteStatisticsWithCompletionHandler:^(NSError *error, NSDictionary *statisticsDictionary) {
      expect(error).to.beNil;
      expect(statisticsDictionary).toNot.beNil;
    }];
    [$ waitUntil:^{return (BOOL)(loaded == YES);}];
  });

  it(@"should initialize the completion and error blocks correctly", ^{
    MKNKErrorBlock error = nil;
    MKNKResponseBlock response = nil;
    [authenticated initializeCompletionBlock:&response andErrorBlock:&error forHandler:^(NSError *error, NSDictionary *dictionary) {
      //nothing
    }];
    expect(error).toNot.beNil;
    expect(response).toNot.beNil;
  });
  
  it(@"should fail to delete a hash which is not real", ^{
    __block BOOL loaded = NO;
    [authenticated deleteImageForDeleteHash:@"oefjwf" withCompletionHandler:^(NSError *error, NSDictionary *dictionary) {
      expect(error).toNot.beNil;
      expect(dictionary).to.beNil;
    }];
    [$ waitUntil:^{return (BOOL)(loaded == YES);}];
  });
  
  __block Imgur *unauthenticated = [[Imgur alloc] initWithDeveloperKey:DeveloperKey];
  
  it(@"should have correct API type set", ^{
    expect(unauthenticated.apiType).to.equal(ImgurAPITypeAnonymous);
  });
  
});

SpecEnd
