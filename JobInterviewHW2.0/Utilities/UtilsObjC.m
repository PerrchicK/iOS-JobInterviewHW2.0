//
//  UtilsObjC.m
//  Scenes
//
//  Created by Perry on 17/01/2017.
//  Copyright © 2017 perrchick. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "UtilsObjC.h"

// The DLog macro is used to print logs only when compiled in debug mode and not release
#ifdef DEBUG
#   define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define DLog(...)
#endif

// The ELog macro is used to print to log with an "ERROR" prefix. Only print to log on debug and not in release
#ifdef DEBUG
#   define ELog(fmt, ...) NSLog((@"ERROR: %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define ELog(...)
#endif

@interface UtilsObjC()

@property (nonatomic, assign) SCEnvironment currentEnvironment;

@end

@implementation UtilsObjC

@synthesize currentEnvironment;

// Singleton implementation in Objective-C
__strong static UtilsObjC *_shared;
+ (UtilsObjC *)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[UtilsObjC alloc] init];
    });

    return _shared;
}

- (id)init {
    if (self = [super init]) {
        currentEnvironment = SCEnvironmentUnknown;
    }

    return self;
}

+(SCEnvironment) currentEnvironment {
    // Lazy instantiations of current environment
    if ([UtilsObjC shared].currentEnvironment == SCEnvironmentUnknown) {
        // uninitialized
        if ([[NSUserDefaults standardUserDefaults] stringForKey: @"shouldUseDevEnvironment"] == nil) {
#ifdef DEBUG
            [UtilsObjC shared].currentEnvironment = SCEnvironmentDev; // For now, no matter what, always run on development environment
#else
            [UtilsObjC shared].currentEnvironment = SCEnvironmentProduction;
#endif
        } else {
            [UtilsObjC shared].currentEnvironment = SCEnvironmentDev;
        }
    }

    return [UtilsObjC shared].currentEnvironment;
}

+(BOOL)switchEnvironment:(SCEnvironment) selectedEnvironment {
    [UtilsObjC shared].currentEnvironment = selectedEnvironment;
    switch (selectedEnvironment) {
        case SCEnvironmentProduction:
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"shouldUseDevEnvironment"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            break;
        case SCEnvironmentDev:
            [[NSUserDefaults standardUserDefaults] setObject:@"yes please" forKey:@"shouldUseDevEnvironment"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            break;
        default:
            return NO;
    }

    return YES;
}

/**
 Using conditional compilation flags: https://miqu.me/blog/2016/07/31/xcode-8-new-build-settings-and-analyzer-improvements/
 */
+(BOOL) isRunningReleaseVersion {
#ifdef DEBUG
    return NO;
#else
    return YES;
#endif
}

+(BOOL) isRunningOnSimulator {
#if TARGET_IPHONE_SIMULATOR
    // Querrying the ASL is much slower in the simulator. We need a longer polling interval to keep things repsonsive.
    return YES;
#endif
    return NO;
}

+(void) log:(NSString *) logMessage {
    DLog(@"%@", logMessage);
}

+(FIROptions *) firebaseEnvironmentOptions {
    FIROptions* options;
//    NSString *tempFileName = @"GoogleService-Info.plist";
    NSString *tempFilePath;

#ifdef DEBUG
    if (UtilsObjC.currentEnvironment == SCEnvironmentDev) {
        tempFilePath = [[NSBundle mainBundle] pathForResource:@"GoogleService-Info-dev" ofType:@"plist"];
    } else {
        tempFilePath = [[NSBundle mainBundle] pathForResource:@"GoogleService-Info" ofType:@"plist"];
    }
#else
    tempFilePath = [[NSBundle mainBundle] pathForResource:@"GoogleService-Info" ofType:@"plist"];
#endif

    options = [[FIROptions defaultOptions] initWithContentsOfFile: tempFilePath]; [NSString stringWithContentsOfFile:tempFilePath encoding:NSUTF8StringEncoding error:nil];

    return options;
}

@end
