//
//  TTMediamosaLogin.h
//  mediamosa-objc
//
//  Created by Ugochukwu Enyioha on 5/22/11.
//  Copyright 2011 Home. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TTMediamosaConfig.h"
#import "TTMediamosaConnect.h"
#import "TTMediamosaAflickaConfig.h"

@interface TTMediamosaLogin : TTMediamosaConnect

-(void) login;
-(void) sendLoginRequest;

@end
