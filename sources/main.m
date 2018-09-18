#import <TargetConditionals.h>

#if defined(TARGET_IOS)
#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#else
#import <Cocoa/Cocoa.h>
#endif

#if defined(TARGET_IOS)

int main(int argc, char * argv[]) {

#if TARGET_OS_SIMULATOR
#error No simulator support for Metal API.  Must build for a device
#endif

    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}

#elif defined(TARGET_MACOS)

int main(int argc, const char * argv[]) {
    return NSApplicationMain(argc, argv);
}

#endif
