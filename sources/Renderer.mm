#import "Renderer.h"
#import "Sprite.h"

#include <math.h>

#include "Boid.h"
#include "Swarm.h"
#include "rand.h"

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
    
    std::size_t _totalBoidsCount;
    std::vector<boids::Boid> mBoids;
    boids::Swarm* mSwarm;
    bool simulationReady;
    vector_float4 _boldColor;
    vector_float4 _targetColor;
}

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView {
    self = [super init];
    if(self) {
        _device = mtkView.device;
        _commandQueue = [_device newCommandQueue];
        _inFlightSemaphore = dispatch_semaphore_create(cMaxBuffersInFlight);
        
        [self setupPipelinesUsingMetalKitView:mtkView];
        
        [self setupImGui];
        
        simulationReady = false;
        
        _frameIndex = 0;
        _startupTime = CACurrentMediaTime();
        _lastTime = CACurrentMediaTime();
        _currentTime = 0;
    }
    return self;
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    _viewportSize.x = size.width;
    _viewportSize.y = size.height;
    
    [self prepareSimulation:size];
}

- (void)drawInMTKView:(nonnull MTKView *)view {
    dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);
    _currentBuffer = (_currentBuffer + 1) % cMaxBuffersInFlight;
    
    _lastTime = _currentTime;
    _currentTime = CACurrentMediaTime() - _startupTime;
    float elapsed = _currentTime - _lastTime;
    
    float t0 = CACurrentMediaTime() - _startupTime;
    [self simulateWithElapsedTime:elapsed drawableSize:_viewportSize];
    float t1 = CACurrentMediaTime() - _startupTime;
    
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
        ImGui::Text("Frame Time: %f ms", elapsed);
        ImGui::Text("Simulation Time: %f ms", (t1 - t0));
        ImGui::Text("Vertices: %lu", _totalSpriteVertexCount);
        ImGui::Text("boids: %lu", _totalBoidsCount);
        ImGui::Separator();
        float steerigWeight = mSwarm->GetSteeringWeight();
        if (ImGui::SliderFloat("Steering", &steerigWeight, 0.0f, 1.0f)) {
            mSwarm->SetSteeringWeight(steerigWeight);
        }
        float separationWeight = mSwarm->GetSeparationWeight();
        if (ImGui::SliderFloat("Separation", &separationWeight, 0.0f, 1.0f)) {
            mSwarm->SetSeparationWeight(separationWeight);
        }
        float cohesionWeight = mSwarm->GetCohesionWeight();
        if (ImGui::SliderFloat("Cohesion", &cohesionWeight, 0.0f, 1.0f)) {
            mSwarm->SetChoesionWeight(cohesionWeight);
        }
        float alignmentWeight = mSwarm->GetAlignmentWeight();
        if (ImGui::SliderFloat("Alighment", &alignmentWeight, 0.0f, 1.0f)) {
            mSwarm->SetAlignmentWeight(alignmentWeight);
        }
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

- (void)prepareSimulation:(CGSize)size {
    if (simulationReady) {
        return;
    }
    
    const float w = size.width;
    const float h = size.height;
    const float cx = w * 0.5f;
    const float cy = h * 0.5f;
    
    const vec3 cInitialPositions[] {
        { -100.0f, -100.0f, 0.0f },
        { w + 100.0f, -100.0f, 0.0f },
        { -100.0f, h + 100.0f, 0.0f },
        { w + 100.0f, h + 100.0f, 0.0f }
    };
    
    float offset = w * 0.1f;
    _totalBoidsCount = 128;
    for(std::size_t n = 0; n < _totalBoidsCount; n++) {
        int ii = boids::random::get(0, 3);
        auto pos = cInitialPositions[ii];
        float dx = boids::random::get(0, 100) > 50 ? -1.0f : 1.0f;
        float xx = boids::random::get(-20.0f, 20.0f);
        pos.x() = pos.x() + dx * xx;
        float dy = boids::random::get(0, 100) > 50 ? 1.0f : -1.0f;
        float yy = boids::random::get(-20.0f, 20.0f);
        pos.y() = pos.y() + dy * yy;
        
        float vx = boids::random::get(10.0f, 300.0f);
        float vy = boids::random::get(10.0f, 300.0f);
        mBoids.emplace_back(pos, vec3(vx, vy, 0.0f));
    }

    mSwarm = new boids::Swarm(mBoids);
    mSwarm->SetMaximumVelocity(300.0f);
    mSwarm->SetMaximumAcceleration(100.0f);
    mSwarm->SetChoesionWeight(0.7f);
    mSwarm->SetAlignmentWeight(0.2f);
    mSwarm->SetSteeringWeight(0.85f);
    mSwarm->SetSeparationWeight(0.8f);
    
    offset = boids::random::get(50.0f, 200.0f);
    mSwarm->AddSteeringTarget(vec3(cx + offset, cy + offset, 0.0f));
    offset = boids::random::get(50.0f, 200.0f);
    mSwarm->AddSteeringTarget(vec3(cx - offset, cy + offset, 0.0f));
    offset = boids::random::get(50.0f, 200.0f);
    mSwarm->AddSteeringTarget(vec3(cx + offset, cy - offset, 0.0f));
    offset = boids::random::get(50.0f, 200.0f);
    mSwarm->AddSteeringTarget(vec3(cx - offset, cy - offset, 0.0f));
    mSwarm->AddSteeringTarget(vec3(cx, cy, 0.0f));
    
    _totalSpriteVertexCount = Sprite.verticesCount * (mBoids.size() + mSwarm->GetSteeringTargetsCount());
    NSUInteger spriteVertexBufferSize = _totalSpriteVertexCount * sizeof(PositionColorVertexFormat);
    for(NSUInteger bufferIndex = 0; bufferIndex < cMaxBuffersInFlight; bufferIndex++) {
        _vertexBuffers[bufferIndex] = [_device newBufferWithLength:spriteVertexBufferSize options:MTLResourceStorageModeShared];
    }
    
    _boldColor.x = 1.0;
    _boldColor.y = 0.0;
    _boldColor.z = 0.0;
    _boldColor.w = 1.0;
    
    _targetColor.x = 0.0;
    _targetColor.y = 1.0;
    _targetColor.z = 0.0;
    _targetColor.w = 1.0;
    
    
    simulationReady = true;
}

- (void)simulateWithElapsedTime:(float)elapsedTime drawableSize:(vector_uint2)drawableSize {
    if (!simulationReady) {
        return;
    }
    
    mSwarm->Simulate(elapsedTime);
    
    float halfWidth = drawableSize.x * 0.5f;
    float halfHeight = drawableSize.y * 0.5f;
    
    PositionColorVertexFormat *currentSpriteVertices = (PositionColorVertexFormat *)_vertexBuffers[_currentBuffer].contents;
    NSUInteger currentVertex = _totalSpriteVertexCount - 1;
    
    for(std::size_t n = 0; n < mSwarm->GetSteeringTargetsCount(); n++) {
        auto targetPosition = mSwarm->GetSteeringTargetAtIndex(n);
        for(NSInteger vertexOfSprite = Sprite.verticesCount - 1; vertexOfSprite >= 0 ; vertexOfSprite--) {
            currentSpriteVertices[currentVertex].position.x = (Sprite.vertices[vertexOfSprite].position.x + targetPosition.x()) - halfWidth;
            currentSpriteVertices[currentVertex].position.y = (Sprite.vertices[vertexOfSprite].position.y + targetPosition.y()) - halfHeight;
            currentSpriteVertices[currentVertex].color = _targetColor;
            currentVertex--;
        }
    }
    
    for(auto& boid : mBoids) {
        auto boidPosition = boid.mPosition;
        for(NSInteger vertexOfSprite = Sprite.verticesCount - 1; vertexOfSprite >= 0 ; vertexOfSprite--) {
            currentSpriteVertices[currentVertex].position.x = (Sprite.vertices[vertexOfSprite].position.x + boidPosition.x()) - halfWidth;
            currentSpriteVertices[currentVertex].position.y = (Sprite.vertices[vertexOfSprite].position.y + boidPosition.y()) - halfHeight;
            currentSpriteVertices[currentVertex].color = _boldColor;
            currentVertex--;
        }
    }
}

@end
