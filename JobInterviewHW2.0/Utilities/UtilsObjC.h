//
//  UtilsObjC.h
//  Scenes
//
//  Created by Perry on 17/01/2017.
//  Copyright © 2017 Nikolai Volodin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Firebase.h"

typedef enum SCEnvironment {
    SCEnvironmentUnknown,
    SCEnvironmentProduction,
    SCEnvironmentDev,
} SCEnvironment;

@interface UtilsObjC : NSObject

/**
 Using conditional compilation flags: https://miqu.me/blog/2016/07/31/xcode-8-new-build-settings-and-analyzer-improvements/
 */
+(BOOL) isRunningReleaseVersion;
+(BOOL) isRunningOnSimulator;

+(void) log:(NSString *) logMessage;

/**
 This method is written in ObjC because it uses compilation flags to ensure that AppStore versions will run only on production environment.
 */
// compilation flags: https://oleb.net/blog/2013/04/compiler-warnings-for-objective-c-developers/
+(FIROptions *) firebaseEnvironmentOptions;

+(BOOL) switchEnvironment: (SCEnvironment) selectedEnvironment;
+(SCEnvironment) currentEnvironment;

@end
