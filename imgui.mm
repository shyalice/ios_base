#import "imgui.h"

#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

#include <chrono>
#include <cmath>

#import "imgui/backends/imgui_impl_metal.h"
#import "imgui/imgui.h"
#import "imgui/imgui_internal.h"
#import "objc_reflect.h"

@interface ImGuiView ( ) {
    CAMetalLayer* m_pMetalLayer;
    id< MTLDevice > m_pDevice;
    id< MTLCommandQueue > m_pCommandQueue;
    CADisplayLink* m_pDisplayLink;
    CGSize m_szDrawable;
    float m_fNativeScale;
    float m_fFbScale;
    BOOL m_bImGuiReady;
    BOOL m_bInteractive;
    BOOL m_bMenuVisible;
}
@end

@implementation ImGuiView

+ ( Class )layerClass
{
    return rt::cls( "CAMetalLayer" );
}

- ( instancetype )initWithFrame:( CGRect )frame
{
    if ( !( self = [super initWithFrame:frame] ) )
        return nil;

    m_pDevice = MTLCreateSystemDefaultDevice( );
    m_pCommandQueue = rt::msg( static_cast< id >( m_pDevice ), "newCommandQueue" );
    m_pMetalLayer = static_cast< CAMetalLayer* >( rt::msg( self, "layer" ) );
    
    m_fNativeScale = rt::msg< CGFloat >( rt::msg( rt::cls( "UIScreen" ), "mainScreen" ), "nativeScale" );
    if ( m_fNativeScale <= 0.0f ) m_fNativeScale = 2.0f;
    
    m_fFbScale = 2.0f;
    m_szDrawable = CGSizeMake( frame.size.width * m_fNativeScale, frame.size.height * m_fNativeScale );
    
    m_bImGuiReady = NO;
    m_bInteractive = NO;
    m_bMenuVisible = NO;

    NSLog( @"[imgui::ImGuiView] init" );

    id clear_color = rt::msg( rt::cls( "UIColor" ), "clearColor" );
    rt::msg< void >( self, "setOpaque:", NO );
    rt::msg< void >( self, "setBackgroundColor:", clear_color );
    rt::msg< void >( self, "setUserInteractionEnabled:", YES );
    rt::msg< void >( self, "setMultipleTouchEnabled:", YES );
    rt::msg< void >( self, "setContentScaleFactor:", static_cast< CGFloat >( m_fNativeScale ) );

    rt::msg< void >( m_pMetalLayer, "setDevice:", static_cast< id >( m_pDevice ) );
    rt::msg< void >( m_pMetalLayer, "setPixelFormat:", static_cast< NSUInteger >( MTLPixelFormatBGRA8Unorm ) );
    rt::msg< void >( m_pMetalLayer, "setFramebufferOnly:", YES );
    rt::msg< void >( m_pMetalLayer, "setOpaque:", NO );
    
    rt::msg< void >( m_pMetalLayer, "setContentsScale:", static_cast< CGFloat >( m_fNativeScale ) );
    rt::msg< void >( m_pMetalLayer, "setDrawableSize:", m_szDrawable );
    
    rt::msg< void >( m_pMetalLayer, "setAllowsEdgeAntialiasing:", NO );
    rt::msg< void >( m_pMetalLayer, "setMinificationFilter:", static_cast< id >( kCAFilterNearest ) );
    rt::msg< void >( m_pMetalLayer, "setMagnificationFilter:", static_cast< id >( kCAFilterNearest ) );

    rt::msg< void >( self, "setupImGui" );
    rt::msg< void >( self, "startDisplayLink" );
    return self;
}

- ( void )dealloc
{
    rt::msg< void >( m_pDisplayLink, "invalidate" );
    ImGui_ImplMetal_Shutdown( );
}

- ( void )startDisplayLink
{
    m_pDisplayLink = static_cast< CADisplayLink* >( rt::msg( rt::cls( "CADisplayLink" ), "displayLinkWithTarget:selector:", static_cast< id >( self ), sel_registerName( "renderFrame" ) ) );
    
    BOOL responds = rt::msg< BOOL >( static_cast< id >( m_pDisplayLink ), "respondsToSelector:", sel_registerName( "setPreferredFrameRateRange:" ) );
    if ( responds )
    {
        CAFrameRateRange range = CAFrameRateRangeMake( 60.0f, 120.0f, 120.0f );
        rt::msg< void >( m_pDisplayLink, "setPreferredFrameRateRange:", range );
    } else
    {
        rt::msg< void >( m_pDisplayLink, "setPreferredFramesPerSecond:", static_cast< NSInteger >( 120 ) );
    }
    id run_loop = rt::msg( rt::cls( "NSRunLoop" ), "mainRunLoop" );
    rt::msg< void >( m_pDisplayLink, "addToRunLoop:forMode:", run_loop, NSRunLoopCommonModes );
}

- ( void )layoutSubviews
{
    [super layoutSubviews];
    CGRect bounds = rt::msg< CGRect >( self, "bounds" );
    m_szDrawable = CGSizeMake( bounds.size.width * m_fNativeScale, bounds.size.height * m_fNativeScale );
    rt::msg< void >( self, "setContentScaleFactor:", static_cast< CGFloat >( m_fNativeScale ) );
    rt::msg< void >( m_pMetalLayer, "setContentsScale:", static_cast< CGFloat >( m_fNativeScale ) );
    rt::msg< void >( m_pMetalLayer, "setDrawableSize:", m_szDrawable );
}

- ( void )setupImGui
{
    IMGUI_CHECKVERSION( );
    ImGui::CreateContext( );

    ImGuiIO& io = ImGui::GetIO( );
    io.IniFilename = nullptr;
    io.LogFilename = nullptr;
    io.ConfigFlags |= ImGuiConfigFlags_NavNoCaptureKeyboard;
    io.MouseDrawCursor = false;

    ImFontConfig font_cfg;
    font_cfg.RasterizerDensity = m_fFbScale;
    io.Fonts->AddFontDefault( &font_cfg );

    ImGuiStyle& style = ImGui::GetStyle( );
    ImGui::StyleColorsDark( &style );
    style.AntiAliasedLines = true;
    style.AntiAliasedLinesUseTex = true;
    style.AntiAliasedFill = true;

    ImGui_ImplMetal_Init( m_pDevice );
    m_bImGuiReady = YES;
    
    NSLog( @"[imgui::ImGuiView] imgui ready" );
}

- ( void )setInteractive:( BOOL )interactive
{
    m_bInteractive = interactive;
    m_bMenuVisible = interactive;
}

- ( BOOL )isInteractive
{
    return m_bInteractive;
}

- ( UIView* )hitTest:( CGPoint )point withEvent:( UIEvent* )event
{
    if ( !m_bInteractive )
        return nil;
    return [super hitTest:point withEvent:event];
}

- ( void )feedTouches:( NSSet< UITouch* >* )touches event:( UIEvent* )event
{
    if ( !m_bImGuiReady )
        return;
    ImGuiIO& io = ImGui::GetIO( );

    id all_touches = rt::msg( event, "allTouches" );
    id any_touch = rt::msg( all_touches, "anyObject" );
    if ( any_touch )
    {
        CGPoint pt = rt::msg< CGPoint >( any_touch, "locationInView:", static_cast< id >( self ) );
        
        float touch_scale = m_fNativeScale / m_fFbScale;
        io.MousePos = ImVec2( pt.x * touch_scale, pt.y * touch_scale );
    }

    BOOL down = NO;
    id all_objects = rt::msg( all_touches, "allObjects" );
    NSUInteger count = rt::msg< NSUInteger >( all_objects, "count" );
    for ( NSUInteger i = 0; i < count; i++ )
    {
        id t = rt::msg( all_objects, "objectAtIndex:", i );
        NSInteger phase = rt::msg< NSInteger >( t, "phase" );
        if ( phase != UITouchPhaseEnded && phase != UITouchPhaseCancelled )
        {
            down = YES;
            break;
        }
    }
    io.MouseDown[ 0 ] = down;
}

- ( void )touchesBegan:( NSSet< UITouch* >* )touches withEvent:( UIEvent* )event
{
    rt::msg< void >( self, "feedTouches:event:", touches, event );
}
- ( void )touchesMoved:( NSSet< UITouch* >* )touches withEvent:( UIEvent* )event
{
    rt::msg< void >( self, "feedTouches:event:", touches, event );
}
- ( void )touchesEnded:( NSSet< UITouch* >* )touches withEvent:( UIEvent* )event
{
    rt::msg< void >( self, "feedTouches:event:", touches, event );
}
- ( void )touchesCancelled:( NSSet< UITouch* >* )touches withEvent:( UIEvent* )event
{
    rt::msg< void >( self, "feedTouches:event:", touches, event );
}

- ( void )renderFrame
{
    if ( !m_bImGuiReady )
        return;
    CGSize drawable_px = rt::msg< CGSize >( m_pMetalLayer, "drawableSize" );
    if ( drawable_px.width <= 0 || drawable_px.height <= 0 )
        return;

    id drawable = rt::msg( m_pMetalLayer, "nextDrawable" );
    if ( !drawable )
        return;

    MTLRenderPassDescriptor* pass = rt::msg< MTLRenderPassDescriptor* >( rt::cls( "MTLRenderPassDescriptor" ), "renderPassDescriptor" );
    pass.colorAttachments[ 0 ].texture = rt::msg( drawable, "texture" );
    pass.colorAttachments[ 0 ].loadAction = MTLLoadActionClear;
    pass.colorAttachments[ 0 ].storeAction = MTLStoreActionStore;
    pass.colorAttachments[ 0 ].clearColor = MTLClearColorMake( 0, 0, 0, 0 );

    ImGuiIO& io = ImGui::GetIO( );
    
    io.DisplaySize = ImVec2( static_cast< float >( drawable_px.width ) / m_fFbScale,
                             static_cast< float >( drawable_px.height ) / m_fFbScale );
    io.DisplayFramebufferScale = ImVec2( m_fFbScale, m_fFbScale );
    
    static auto last_time = std::chrono::steady_clock::now( );
    auto now = std::chrono::steady_clock::now( );
    io.DeltaTime = std::chrono::duration< float >( now - last_time ).count( );
    last_time = now;

    id cmd = rt::msg( m_pCommandQueue, "commandBuffer" );
    id enc = rt::msg( cmd, "renderCommandEncoderWithDescriptor:", pass );

    ImGui_ImplMetal_NewFrame( pass );
    ImGui::NewFrame( );

    rt::msg< void >( self, "drawMenu" );

    ImGui::Render( );
    ImGui_ImplMetal_RenderDrawData( ImGui::GetDrawData( ), static_cast< id< MTLCommandBuffer > >( cmd ), static_cast< id< MTLRenderCommandEncoder > >( enc ) );

    rt::msg< void >( enc, "endEncoding" );
    rt::msg< void >( cmd, "presentDrawable:", drawable );
    rt::msg< void >( cmd, "commit" );
}

- ( void )drawMenu
{
    if ( !m_bMenuVisible )
        return;

    ImGuiIO& io = ImGui::GetIO( );
    ImGuiWindow* existing = ImGui::FindWindowByName( "imgui" );
    if ( !existing )
    {
        ImGui::SetNextWindowPos( ImVec2( ( io.DisplaySize.x - 460.f ) * 0.5f, ( io.DisplaySize.y - 320.f ) * 0.5f ), ImGuiCond_FirstUseEver );
    }
    ImGui::SetNextWindowSize( ImVec2( 460.f, 320.f ), ImGuiCond_FirstUseEver );

    bool open = m_bMenuVisible;
    ImGui::Begin( "imgui", &open );
    ImGui::Text( "imgui overlay" );
    ImGui::Separator( );
    ImGui::Text( "display: %.0f x %.0f", io.DisplaySize.x, io.DisplaySize.y );
    ImGui::Text( "fb scale: %.1f", io.DisplayFramebufferScale.x );
    ImGui::Text( "fps:     %.1f", io.Framerate );
    ImGui::End( );
    m_bMenuVisible = open;
}

@end
