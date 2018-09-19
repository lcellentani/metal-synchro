#import "Renderer.h"
#import "Sprite.h"

#include <math.h>

#include "imgui.h"
#include "imgui_impl_metal.h"
#if TARGET_OS_OSX
#include "imgui_impl_osx.h"
#endif

static const NSUInteger cMaxBuffersInFlight = 3;

@implementation Renderer {
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    
    dispatch_semaphore_t _inFlightSemaphore;
    id<MTLBuffer> _vertexBuffers[cMaxBuffersInFlight];
    NSUInteger _currentBuffer;
    
    id<MTLRenderPipelineState> _pipelineState;
    
    vector_uint2 _viewportSize;
    NSArray<Sprite *> *_sprites;
    
    CFTimeInterval _startupTime;
    CFTimeInterval _lastTime;
    float _currentTime;
    NSUInteger _frameIndex;
    
    NSUInteger _totalSpriteVertexCount;
    
    float angle;
    float speed;
    float maxSpeed;
    float dirX;
    float dirY;
}

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView {
    self = [super init];
    if(self) {
        _device = mtkView.device;
        _commandQueue = [_device newCommandQueue];
        _inFlightSemaphore = dispatch_semaphore_create(cMaxBuffersInFlight);
        
        [self setupPipelinesUsingMetalKitView:mtkView];
        
        [self setupImGui];
        
        [self generateSprites];
        
        _totalSpriteVertexCount = Sprite.verticesCount * _sprites.count;
        NSUInteger spriteVertexBufferSize = _totalSpriteVertexCount * sizeof(PositionColorVertexFormat);
        for(NSUInteger bufferIndex = 0; bufferIndex < cMaxBuffersInFlight; bufferIndex++) {
            _vertexBuffers[bufferIndex] = [_device newBufferWithLength:spriteVertexBufferSize options:MTLResourceStorageModeShared];
        }
        
        _frameIndex = 0;
        _startupTime = CACurrentMediaTime();
        _lastTime = CACurrentMediaTime();
        _currentTime = 0;
        
        angle = 30.0;
        speed = 200.0f;
        maxSpeed = 500.0f;
        dirX = 1.0f;
        dirY = 1.0f;
    }
    return self;
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
}

- (void)drawInMTKView:(nonnull MTKView *)view {
    dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);
    _currentBuffer = (_currentBuffer + 1) % cMaxBuffersInFlight;
    
    _lastTime = _currentTime;
    _currentTime = CACurrentMediaTime() - _startupTime;
    float elapsed = _currentTime - _lastTime;
    
    [self simulateWithElapsedTime:elapsed drawableSize:_viewportSize];
    
    [self updateImGuiUsingView:view];
    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";
    
    __block dispatch_semaphore_t block_sema = _inFlightSemaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
        dispatch_semaphore_signal(block_sema);
    }];
    
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    if(renderPassDescriptor != nil) {
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderEncoder";
        
        [renderEncoder pushDebugGroup:@"Draw scene"];
        
        [renderEncoder setCullMode:MTLCullModeBack];
        [renderEncoder setRenderPipelineState:_pipelineState];
        [renderEncoder setVertexBuffer:_vertexBuffers[_currentBuffer] offset:0 atIndex:VertexInputLocationPosition];
        [renderEncoder setVertexBytes:&_viewportSize length:sizeof(_viewportSize) atIndex:VertexInputLocationViewportSize];
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:_totalSpriteVertexCount];
        
        [renderEncoder popDebugGroup];
        
        [renderEncoder pushDebugGroup:@"Draw ImGui"];
        
        ImGui_ImplMetal_NewFrame(renderPassDescriptor);
#if TARGET_OS_OSX
        ImGui_ImplOSX_NewFrame(view);
#endif
        ImGui::NewFrame();
        
        ImGui::SetNextWindowPos(ImVec2(5.0f, 5.0f), ImGuiSetCond_FirstUseEver);
        ImGui::Begin("Global Params", nullptr, ImVec2(_viewportSize.x * 0.5f, _viewportSize.y * 0.2f), -1.f, ImGuiWindowFlags_AlwaysAutoResize);
        ImGui::Text("Time: %f ms", elapsed);
        ImGui::End();
        
        ImGui::Render();
        ImDrawData *drawData = ImGui::GetDrawData();
        ImGui_ImplMetal_RenderDrawData(drawData, commandBuffer, renderEncoder);
        
        [renderEncoder popDebugGroup];
        
        [renderEncoder endEncoding];
        
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    
    [commandBuffer commit];
}

- (void)setupPipelinesUsingMetalKitView:(nonnull MTKView *)mtkView {
    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
    id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];
    id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.label = @"MyPipeline";
    pipelineStateDescriptor.sampleCount = mtkView.sampleCount;
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
    pipelineStateDescriptor.depthAttachmentPixelFormat = mtkView.depthStencilPixelFormat;
    pipelineStateDescriptor.stencilAttachmentPixelFormat = mtkView.depthStencilPixelFormat;
    NSError *error = NULL;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    if (!_pipelineState) {
        NSLog(@"Failed to created pipeline state, error %@", error);
    }
}

- (void)setupImGui {
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    (void)ImGui::GetIO();
    
    ImGui_ImplMetal_Init(_device);
    
    ImGui::StyleColorsDark();
}

- (void)updateImGuiUsingView:(nonnull MTKView *)view {
    ImGuiIO &io = ImGui::GetIO();
    io.DisplaySize.x = view.bounds.size.width;
    io.DisplaySize.y = view.bounds.size.height;
    
#if TARGET_OS_OSX
    CGFloat framebufferScale = view.window.screen.backingScaleFactor ?: NSScreen.mainScreen.backingScaleFactor;
#else
    CGFloat framebufferScale = view.window.screen.scale ?: UIScreen.mainScreen.scale;
#endif
    io.DisplayFramebufferScale = ImVec2(framebufferScale, framebufferScale);
    
    io.DeltaTime = 1 / float(view.preferredFramesPerSecond ?: 60);
}

- (void)generateSprites {
    NSMutableArray *sprites = [[NSMutableArray alloc] initWithCapacity:1];
    
    vector_float2 spritePosition;
    spritePosition.x = 0.0;
    spritePosition.y = 0.0;

    vector_float4 sprite_color;
    sprite_color.x = 1.0;
    sprite_color.y = 0.0;
    sprite_color.z = 0.0;
    sprite_color.w = 1.0;
    
    Sprite * sprite = [Sprite new];
    sprite.position = spritePosition;
    sprite.color =sprite_color;
    
    [sprites addObject:sprite];
    
    _sprites = sprites;
}

- (void)simulateWithElapsedTime:(float)elapsedTime drawableSize:(vector_uint2)drawableSize {
    PositionColorVertexFormat *currentSpriteVertices = (PositionColorVertexFormat *)_vertexBuffers[_currentBuffer].contents;
    NSUInteger currentVertex = _totalSpriteVertexCount - 1;
    NSUInteger spriteIdx = 0;

    float limitX = drawableSize.x * 0.5;
    float limitY = drawableSize.y * 0.5;
    
    float a = angle / 180.0 * M_PI;
    
    float x = _sprites[spriteIdx].position.x + ((elapsedTime * speed * cosf(a)) * dirX);
    float y = _sprites[spriteIdx].position.y + ((elapsedTime * speed * sinf(a)) * dirY);
    
    bool changeSpeed = false;
    if (x < -limitX) {
        x = -limitX;
        dirX = -dirX;
        changeSpeed = true;
    }
    if (x > limitX) {
        x = limitX;
        dirX = -dirX;
        changeSpeed = true;
    }
    if (y < -limitY) {
        y = -limitY;
        dirY = -dirY;
        changeSpeed = true;
    }
    if (y > limitY) {
        y = limitY;
        dirY = -dirY;
        changeSpeed = true;
    }
    if (changeSpeed) {
        speed += speed * 0.1f;
        if (speed > maxSpeed) {
            speed = maxSpeed;
        }
    }
    
    vector_float2 position;
    position.x = x;
    position.y = y;
                                                
    _sprites[spriteIdx].position = position;
    
    for(NSInteger vertexOfSprite = Sprite.verticesCount - 1; vertexOfSprite >= 0 ; vertexOfSprite--) {
        currentSpriteVertices[currentVertex].position = Sprite.vertices[vertexOfSprite].position + _sprites[spriteIdx].position;
        currentSpriteVertices[currentVertex].color = _sprites[spriteIdx].color;
        currentVertex--;
    }
}

@end
