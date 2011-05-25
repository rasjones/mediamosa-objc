//
//  TTMediamosaServer
//  mediamosa-objc
//
//  Created by Ugochukwu Enyioha on 5/22/11.
//  Copyright 2011 Home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTMediamosaAflickaConfig.h"
#import <Three20Network/TTURLRequestDelegate.h>

@interface TTMediamosaServer : NSObject <TTURLRequestDelegate>

- (id)init;
-(void)login;

@end
