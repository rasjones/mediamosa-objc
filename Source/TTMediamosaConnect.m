//
//  MediamosaConnect.m
//  mediamosa-objc
//
//  Created by Ugochukwu Enyioha on 5/22/11.
//  Copyright 2011 Home. All rights reserved.
//

#import "TTMediamosaConnect.h"

@interface TTMediamosaConnect (/* private */)

@end

@implementation TTMediamosaConnect

@synthesize method = _method, methodURL = _methodURL;

-(TTURLRequest *) prepareRequestForURL:(NSString *)url withAPICall:(NSString *) apiCall
{
    TTURLRequest *request = [TTURLRequest requestWithURL:url delegate:self];
    
    request.httpBody = [apiCall dataUsingEncoding:NSUTF8StringEncoding];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    request.shouldHandleCookies = YES;
    request.response = [[[TTURLXMLResponse alloc] init] autorelease];
    
    return request;
}

@end
