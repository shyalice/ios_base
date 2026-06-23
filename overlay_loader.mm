#import "overlay_loader.h"

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import "gestures.h"
#import "imgui.h"
#import "objc_reflect.h"
#import "secure_view.h"

@interface OverlayLoader ( ) {
    UIWindow* m_pHostWindow;
    SecureView* m_pSecure;
    ImGuiView* m_pOverlay;
    imgui::Gestures m_gestures;
    BOOL m_bSecureEnabled;
    int m_iInstallTries;
}
@end

@implementation OverlayLoader

+ ( instancetype )shared
{
    static OverlayLoader* s_instance = nil;
    static dispatch_once_t once;
    dispatch_once( &once, ^{
      s_instance = rt::msg< OverlayLoader* >( rt::msg( rt::cls( "OverlayLoader" ), "alloc" ), "init" );
    } );
    return s_instance;
}

+ ( void )load
{
    [super load];
    dispatch_after( dispatch_time( DISPATCH_TIME_NOW, static_cast< int64_t >( 3.0 * NSEC_PER_SEC ) ),
                    dispatch_get_main_queue( ), ^{
                      rt::msg< void >( rt::msg( rt::cls( "OverlayLoader" ), "shared" ), "install" );
                    } );
}

- ( UIWindow* )pickHostKeyWindow
{
    id app = rt::msg( rt::cls( "UIApplication" ), "sharedApplication" );
    id windows = rt::msg( app, "windows" );
    NSUInteger count = rt::msg< NSUInteger >( windows, "count" );
    for ( NSUInteger i = 0; i < count; i++ )
    {
        id w = rt::msg( windows, "objectAtIndex:", i );
        BOOL is_key = rt::msg< BOOL >( w, "isKeyWindow" );
        id root = rt::msg( w, "rootViewController" );
        if ( is_key && root )
            return static_cast< UIWindow* >( w );
    }
    for ( NSUInteger i = 0; i < count; i++ )
    {
        id w = rt::msg( windows, "objectAtIndex:", i );
        if ( rt::msg( w, "rootViewController" ) )
            return static_cast< UIWindow* >( w );
    }
    return nil;
}

- ( void )install
{
    if ( m_pOverlay )
        return;
    m_iInstallTries++;

    UIWindow* host = rt::msg< UIWindow* >( self, "pickHostKeyWindow" );
    if ( !host )
    {
        if ( m_iInstallTries < 30 )
        {
            dispatch_after( dispatch_time( DISPATCH_TIME_NOW, static_cast< int64_t >( 1.0 * NSEC_PER_SEC ) ),
                            dispatch_get_main_queue( ), ^{
                              rt::msg< void >( self, "install" );
                            } );
        }
        return;
    }
    m_pHostWindow = host;
    CGRect host_bounds = rt::msg< CGRect >( host, "bounds" );

    id overlay_alloc = rt::msg( rt::cls( "ImGuiView" ), "alloc" );
    m_pOverlay = static_cast< ImGuiView* >( rt::msg( overlay_alloc, "initWithFrame:", host_bounds ) );

    rt::msg< void >( self, "applyOverlayGeometryInParent:", static_cast< id >( host ) );
    rt::msg< void >( static_cast< id >( host ), "addSubview:", static_cast< id >( m_pOverlay ) );
    rt::msg< void >( static_cast< id >( host ), "bringSubviewToFront:", static_cast< id >( m_pOverlay ) );
    m_bSecureEnabled = NO;

    NSLog( @"[imgui::OverlayLoader] install" );

    rt::msg< void >( self, "setupGestures" );
}

- ( void )disableClippingFromView:( UIView* )view
{
    UIView* cur = view;
    for ( int i = 0; cur && i < 8; i++ )
    {
        rt::msg< void >( static_cast< id >( cur ), "setClipsToBounds:", NO );
        id layer = rt::msg( static_cast< id >( cur ), "layer" );
        rt::msg< void >( layer, "setMasksToBounds:", NO );
        cur = static_cast< UIView* >( rt::msg( static_cast< id >( cur ), "superview" ) );
    }
}

- ( void )applyOverlayGeometryInParent:( UIView* )parent
{
    CGRect host_bounds = rt::msg< CGRect >( m_pHostWindow, "bounds" );

    rt::msg< void >( self, "disableClippingFromView:", static_cast< id >( parent ) );
    rt::msg< void >( static_cast< id >( m_pHostWindow ), "setClipsToBounds:", NO );
    id host_layer = rt::msg( static_cast< id >( m_pHostWindow ), "layer" );
    rt::msg< void >( host_layer, "setMasksToBounds:", NO );

    rt::msg< void >( static_cast< id >( m_pOverlay ), "setTransform:", CGAffineTransformIdentity );
    rt::msg< void >( static_cast< id >( m_pOverlay ), "setFrame:", host_bounds );
    rt::msg< void >( static_cast< id >( m_pOverlay ), "setBounds:", host_bounds );
    rt::msg< void >( static_cast< id >( m_pOverlay ), "setAutoresizingMask:", static_cast< NSUInteger >( 0 ) );
}

- ( void )setupGestures
{
    m_gestures.attach( m_pHostWindow );
    m_gestures.on( 3, 2, [ self ] { rt::msg< void >( self, "toggleMenu" ); } );
    m_gestures.on( 2, 2, [ self ] { rt::msg< void >( self, "toggleSecure" ); } );
    m_gestures.on( 1, 3, [ self ] { rt::msg< void >( self, "toggleMenu" ); } );
}

- ( void )toggleMenu
{
    BOOL next = !rt::msg< BOOL >( static_cast< id >( m_pOverlay ), "isInteractive" );
    rt::msg< void >( static_cast< id >( m_pOverlay ), "setInteractive:", next );
    if ( next )
    {
        if ( m_bSecureEnabled && m_pSecure )
        {
            rt::msg< void >( static_cast< id >( m_pHostWindow ), "bringSubviewToFront:", static_cast< id >( m_pSecure ) );
            id parent = rt::msg( static_cast< id >( m_pOverlay ), "superview" );
            rt::msg< void >( parent, "bringSubviewToFront:", static_cast< id >( m_pOverlay ) );
        } else
        {
            rt::msg< void >( static_cast< id >( m_pHostWindow ), "bringSubviewToFront:", static_cast< id >( m_pOverlay ) );
        }
    }
}

- ( void )toggleSecure
{
    if ( !m_pSecure )
    {
        m_pSecure = rt::msg< SecureView* >( rt::cls( "SecureView" ), "build" );
        CGRect host_b = rt::msg< CGRect >( m_pHostWindow, "bounds" );
        rt::msg< void >( static_cast< id >( m_pSecure ), "setFrame:", host_b );
        rt::msg< void >( static_cast< id >( m_pSecure ), "setAutoresizingMask:",
                         static_cast< NSUInteger >( UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight ) );
        rt::msg< void >( static_cast< id >( m_pHostWindow ), "addSubview:", static_cast< id >( m_pSecure ) );
        rt::msg< void >( static_cast< id >( m_pSecure ), "setHidden:", YES );
        rt::msg< void >( static_cast< id >( m_pSecure ), "layoutIfNeeded" );
    }
    m_bSecureEnabled = !m_bSecureEnabled;
    rt::msg< void >( static_cast< id >( m_pSecure ), "setHidden:", !m_bSecureEnabled );
    if ( m_bSecureEnabled )
        rt::msg< void >( static_cast< id >( m_pHostWindow ), "bringSubviewToFront:", static_cast< id >( m_pSecure ) );

    UIView* parent = m_bSecureEnabled ? m_pSecure.hostView : static_cast< UIView* >( m_pHostWindow );
    rt::msg< void >( static_cast< id >( m_pOverlay ), "removeFromSuperview" );
    rt::msg< void >( self, "applyOverlayGeometryInParent:", static_cast< id >( parent ) );
    rt::msg< void >( static_cast< id >( parent ), "addSubview:", static_cast< id >( m_pOverlay ) );
    rt::msg< void >( static_cast< id >( parent ), "bringSubviewToFront:", static_cast< id >( m_pOverlay ) );
}

- ( void )showMenu
{
    rt::msg< void >( static_cast< id >( m_pOverlay ), "setInteractive:", YES );
}
- ( void )hideMenu
{
    rt::msg< void >( static_cast< id >( m_pOverlay ), "setInteractive:", NO );
}

@end
