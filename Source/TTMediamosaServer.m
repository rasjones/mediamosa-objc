//
// TTMediamosaServer
//  mediamosa-objc
//
//  Created by Ugochukwu Enyioha on 5/22/11.
//  Copyright 2011 Home. All rights reserved.
//

#import "TTMediamosaAflickaConfig.h"
#import <Three20Network/TTURLResponse.h>
#import <Three20Network/TTURLRequest.h>
#import <extThree20XML/TTURLXMLResponse.h>
#import <extThree20XML/TTXMLParser.h>
#include <CommonCrypto/CommonDigest.h>
#import "TTMediamosaServer.h"
#include <stdlib.h>

#define MEDIAMOSA_LOGIN_CHALLENGE              0
#define MEDIAMOSA_LOGIN_CHALLENGE_RESPONSE     1
#define MEDIAMOSA_API_REQUEST                  2

NSString *genChallengeResponse(NSString *challenge, NSString *rndString, NSString *password);
NSString *sha1Digest(NSString* input);
NSString *genRandString(NSInteger length);

@interface TTMediamosaServer (/* private */)

@property (nonatomic, retain) NSString *method;
@property (nonatomic, retain) NSString *methodURL;
@property (nonatomic, retain) id<TTURLRequestDelegate> delegate;

-(void) login;
-(void) sendLoginRequest;

@end

@implementation TTMediamosaServer

@synthesize method = _method, methodURL = _methodURL, delegate = _delegate;

- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

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
    
    NSString *output2 = [[[NSString alloc] initWithBytes:digest length:CC_SHA1_DIGEST_LENGTH encoding:NSUTF8StringEncoding] autorelease];
    
    return output;
}

-(NSString*)urlEscape:(NSString *)unencodedString {
	NSString *s = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                      (CFStringRef)unencodedString,
                                                                      NULL,
                                                                      (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                      kCFStringEncodingUTF8);
	return [s autorelease]; // Due to the 'create rule' we own the above and must autorelease it
}

// Put a query string onto the end of a url
-(NSString*)addQueryStringToUrl:(NSString *)url params:(NSDictionary *)params {
   	NSMutableArray *parts = [NSMutableArray array];
	if (params) {
        for (id key in params) {
            id value = [params objectForKey:key];
            if ([value isKindOfClass:[NSArray class]]) {
                for (id item in value) {
                    NSString *part = [NSString stringWithFormat: @"%@=%@", 
                                      [self urlEscape:key], [self urlEscape:item]];
                    [parts addObject:part];
                }
            } else {
                NSString *part = [NSString stringWithFormat: @"%@=%@", 
                                  [self urlEscape:key], [self urlEscape:value]];
                [parts addObject:part];
            }		
        }
    }
    
	return [NSString stringWithFormat:@"%@?%@", url, [parts componentsJoinedByString: @"&"]];
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

-(TTURLRequest *) prepareRequestForURL:(NSString *)url params:(id) apiCall delegate:(id<TTURLRequestDelegate>)delegate
{
    NSString *apiString;
    TTURLRequest *request;
    NSMutableData *apiData = [NSMutableData data];
    
    
    request = [TTURLRequest requestWithURL:url delegate:delegate];
    
    if ([apiCall isKindOfClass:[NSString class]])    {
        [apiData appendData:[apiCall dataUsingEncoding:NSUTF8StringEncoding]];
    } else if ([apiCall isKindOfClass:[NSDictionary class]])    {
        for (id key in apiCall)   {
            apiString = [NSString stringWithFormat:@"%@=\"%@\"", key, [apiCall objectForKey:key]];
            [apiData appendData:[apiString dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
    
    request.httpBody = apiData;
    
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    request.shouldHandleCookies = YES;
    request.response = [[[TTURLXMLResponse alloc] init] autorelease];
    
    return request;
}

-(void) sendLoginRequest
{
    TTURLRequest *loginRequest = 
    [self prepareRequestForURL:[NSString stringWithFormat:@"%@/%@", MEDIAMOSA_SERVICES_URL, @"login"] params:[NSString stringWithFormat:@"dbus=AUTH DBUS_COOKIE_SHA1 %@", MEDIAMOSA_LOGIN] delegate:self];
    loginRequest.httpMethod = @"POST";
    loginRequest.cachePolicy = TTURLRequestCachePolicyNoCache;
    loginRequest.userInfo = [NSNumber numberWithInt:MEDIAMOSA_LOGIN_CHALLENGE];
    [loginRequest sendSynchronously];
}

-(void) login
{
    [self sendLoginRequest];
}

-(void) sendLoginResponse:(NSString *) challenge
{
    NSString *rndString = genRandString(10);
    NSString *challengeResponse = genChallengeResponse(challenge, rndString, MEDIAMOSA_PASSWORD);
    
    TTURLRequest *loginResponse = 
    [self prepareRequestForURL:[NSString stringWithFormat:@"%@/%@",MEDIAMOSA_SERVICES_URL, @"login"] params:[NSString stringWithFormat:@"dbus=DATA %@ %@",rndString, challengeResponse] delegate:self];
    
    loginResponse.httpMethod = @"POST";
    loginResponse.cachePolicy = TTURLRequestCachePolicyNoCache;
    loginResponse.userInfo = [NSNumber numberWithInt:MEDIAMOSA_LOGIN_CHALLENGE_RESPONSE];
    
    [loginResponse sendSynchronously];
}

- (void)requestDidFinishLoad:(TTURLRequest*)request 
{
    NSInteger requestType = [(NSNumber *) request.userInfo intValue];
    TTURLXMLResponse *response;
    TTXMLParser *dbusElement;
    NSString *dbusResponse = nil, *challenge = nil;
    
    switch (requestType)   {
        case MEDIAMOSA_LOGIN_CHALLENGE:
            response = (TTURLXMLResponse *) request.response;
            dbusElement = (TTXMLParser *) [[[[response rootObject] objectForKey:@"items"] objectForKey:@"item"] objectForKey:@"dbus"];
            dbusResponse = [(TTXMLParser *) dbusElement objectForXMLNode];
            challenge = [[dbusResponse componentsSeparatedByString:@" "] objectAtIndex:3];
            [self sendLoginResponse:challenge];
            break;
        case MEDIAMOSA_LOGIN_CHALLENGE_RESPONSE:
            response = (TTURLXMLResponse *) request.response;
            break;
    }
}

-(void) requestDidFailLoadWithError:(NSError *)error {
    // invoke the delegate as an error occured
    return;
}

-(TTURLRequest *) urlForInvokingAPIEndpoint:(NSString *) endpoint method:(NSString *)aMethod params:(NSDictionary *) params delegate:(id<TTURLRequestDelegate>)delegate
{
    TTURLRequest *apiRequest;
    
    
    
    if ([aMethod isEqualToString:@"GET"]) {
        apiRequest = [self prepareRequestForURL:
                      [self addQueryStringToUrl:[NSString stringWithFormat:@"%@/%@",
                                                 MEDIAMOSA_SERVICES_URL, endpoint] params:params] 
                                         params:nil 
                                       delegate:delegate];
    } else if ([aMethod isEqualToString:@"POST"])   {
        apiRequest = [self prepareRequestForURL:[NSString stringWithFormat:@"%@/%@",MEDIAMOSA_SERVICES_URL, endpoint] params:params delegate:delegate];
    }

    apiRequest.httpMethod = aMethod;
    apiRequest.cachePolicy = TTURLRequestCachePolicyNoCache;
    return apiRequest;
}

@end
