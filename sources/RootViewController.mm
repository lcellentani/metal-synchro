
#import "RootViewController.h"
#import "Renderer.h"

@implementation RootViewController
{
    MTKView *_view;
    
    Renderer *_renderer;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _view = (MTKView *)self.view;
    _view.device = MTLCreateSystemDefaultDevice();
    _view.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
    
    if(!_view.device) {
        NSLog(@"Metal is not supported on this device");
        return;
    }

    _renderer = [[Renderer alloc] initWithMetalKitView:_view];
    if(!_renderer) {
        NSLog(@"Renderer failed initialization");
        return;
    }
    
    [_renderer mtkView:_view drawableSizeWillChange:_view.drawableSize];
    
    _view.delegate = _renderer;
}

#if defined(TARGET_IOS)
- (BOOL)prefersStatusBarHidden {
    return YES;
}
#endif

@end
