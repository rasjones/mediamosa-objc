//
//  MediamosaLogin.m
//  mediamosa-objc
//
//  Created by Ugochukwu Enyioha on 5/22/11.
//  Copyright 2011 Home. All rights reserved.
//

#import "TTMediamosaAflickaConfig.h"
#import "TTMediamosaLogin.h"
#import <Three20Network/TTURLResponse.h>
#import <Three20Network/TTURLRequest.h>
#import <extThree20XML/TTURLXMLResponse.h>
#import <extThree20XML/TTXMLParser.h>
#include <CommonCrypto/CommonDigest.h>
#include <stdlib.h>

#define MEDIAMOSA_LOGIN_CHALLENGE              0
#define MEDIAMOSA_LOGIN_CHALLENGE_RESPONSE     1

NSString *genChallengeResponse(NSString *challenge, NSString *rndString, NSString *password);
NSString *sha1Digest(NSString* input);
NSString *genRandString(NSInteger length);

@implementation TTMediamosaLogin

NSString *sha1Digest(NSString* input)
{
    // TODO: Alter cryptographic protocol to SHA256
    const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:input.length];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, data.length, digest);
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) 
        [output appendFormat:@"%02x", digest[i]];
    return output;
}

NSString *genRandString(int len) 
{
    
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    // arc4random is more secure than rand() as it pulls from /dev/random which has decent entropy
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%c", [letters characterAtIndex: arc4random_uniform([letters length])]];
    }
    
    return randomString;
}

NSString *genChallengeResponse(NSString *challenge, NSString *rndString, NSString *password)    {
    NSString *encString = [NSString stringWithFormat:@"%@:%@:%@", challenge, rndString, password];
    return sha1Digest(encString);
}

-(void) login   {
    self.method = @"login";
    self.methodURL = @"login";
    [self sendLoginRequest];
}

-(void) sendLoginRequest
{
    TTURLRequest *loginRequest = 
        [self prepareRequestForURL:[NSString stringWithFormat:@"%@/%@", MEDIAMOSA_SERVICES_URL, self.methodURL] withAPICall:[NSString stringWithFormat:@"dbus=AUTH DBUS_COOKIE_SHA1 %@", MEDIAMOSA_LOGIN]];
    loginRequest.httpMethod = @"POST";
    loginRequest.cachePolicy = TTURLRequestCachePolicyNoCache;
    loginRequest.userInfo = [NSNumber numberWithInt:MEDIAMOSA_LOGIN_CHALLENGE];
    [loginRequest send];
}

-(void) sendLoginResponse:(NSString *) challenge
{
    NSString *rndString = genRandString(10);
    NSString *challengeResponse = genChallengeResponse(challenge, rndString, MEDIAMOSA_PASSWORD);
    
    TTURLRequest *loginResponse = 
    [self prepareRequestForURL:[NSString stringWithFormat:@"%@/%@",MEDIAMOSA_SERVICES_URL, self.methodURL] withAPICall:[NSString stringWithFormat:@"dbus=DATA %@ %@",rndString, challengeResponse]];
    
    loginResponse.httpMethod = @"POST";
    loginResponse.cachePolicy = TTURLRequestCachePolicyNoCache;
    loginResponse.userInfo = [NSNumber numberWithInt:MEDIAMOSA_LOGIN_CHALLENGE_RESPONSE];
    
    [loginResponse send];
}

- (void)requestDidFinishLoad:(TTURLRequest*)request 
{
    NSInteger requestType = [(NSNumber *) request.userInfo intValue];
    TTURLXMLResponse *response;
    TTXMLParser *dbusElement;
    NSString *dbusResponse = nil, *challenge = nil;
    
    switch (requestType)   {
        case MEDIAMOSA_LOGIN_CHALLENGE:
            NSLog(@"Sending Login Request to: %@", request);
            response = (TTURLXMLResponse *) request.response;
            dbusElement = (TTXMLParser *) [[[[response rootObject] objectForKey:@"items"] objectForKey:@"item"] objectForKey:@"dbus"];
            dbusResponse = [dbusElement objectForXMLNode];
            challenge = [[dbusResponse componentsSeparatedByString:@" "] objectAtIndex:3];
            [self sendLoginResponse:challenge];
            break;
        case MEDIAMOSA_LOGIN_CHALLENGE_RESPONSE:
            NSLog(@"Sending Login Response to: %@", request);
            response = (TTURLXMLResponse *) request.response;
            break;
    }
}

-(void) requestDidFailLoadWithError:(NSError *)error {
    return;
}

@end
