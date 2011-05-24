//
//  TTMediamosaConfig.h
//  mediamosa-objc
//
//  Created by Ugochukwu Enyioha on 5/22/11.
//  Copyright 2011 Home. All rights reserved.
//

#ifdef __APPLE__
#include "TargetConditionals.h"
#endif

#define STAGE

#ifdef STAGE

#define MEDIAMOSA_URL           @"http://MEDIAMOSA_DOMAIN"
#define MEDIAMOSA_SERVICES_URL  @"http://MEDIAMOSA_SERVICES_URL"
#define MEDIAMOSA_LOGIN         @"LOGIN"
#define MEDIAMOSA_PASSWORD      @"PASSWORD"

#endif

#ifdef DEV

#define MEDIAMOSA_URL           @"http://MEDIAMOSA_DOMAIN"
#define MEDIAMOSA_SERVICES_URL  @"http://MEDIAMOSA_SERVICES_URL"
#define MEDIAMOSA_LOGIN         @"LOGIN"
#define MEDIAMOSA_PASSWORD      @"PASSWORD"

#endif
