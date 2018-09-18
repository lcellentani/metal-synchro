#if defined(TARGET_IOS) || defined(TARGET_TVOS)
@import UIKit;
#define PlatformViewController UIViewController
#else
#import<AppKit/AppKit.h>
#define PlatformViewController NSViewController
#endif

@interface RootViewController : PlatformViewController

@end
