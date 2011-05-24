//
//  TTMediamosaConnect.h
//  mediamosa-objc
//
//  Created by Ugochukwu Enyioha on 5/22/11.
//  Copyright 2011 Home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Three20Network/TTURLResponse.h>
#import <Three20Network/TTURLRequest.h>
#import <extThree20XML/TTURLXMLResponse.h>

@interface TTMediamosaConnect : NSObject    {

@protected
    NSString *method;
    NSString *methodURL;
}


@property (nonatomic, retain) NSString *method;
@property (nonatomic, retain) NSString *methodURL;


-(TTURLRequest *) prepareRequestForURL:(NSString *)url withAPICall:(NSString *) apiCall;

@end
