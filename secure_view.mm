#import "secure_view.h"

#import "objc_reflect.h"

#import <objc/runtime.h>

@implementation SecureView {
    UITextField* m_pField;
    UIView* m_pHost;
    int m_iResolveTries;
}

+ ( instancetype )build
{
    id allocated = rt::msg( rt::cls( "SecureView" ), "alloc" );
    return static_cast< SecureView* >( rt::msg( allocated, "initWithFrame:", CGRectZero ) );
}

- ( instancetype )initWithFrame:( CGRect )frame
{
    if ( !( self = [super initWithFrame:frame] ) )
        return nil;

    id clear_color = rt::msg( rt::cls( "UIColor" ), "clearColor" );

    rt::msg< void >( self, "setBackgroundColor:", clear_color );
    rt::msg< void >( self, "setOpaque:", NO );
    rt::msg< void >( self, "setUserInteractionEnabled:", YES );
    rt::msg< void >( self, "setAutoresizingMask:",
                     static_cast< NSUInteger >( UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight ) );

    id field_alloc = rt::msg( rt::cls( "UITextField" ), "alloc" );
    m_pField = static_cast< UITextField* >( rt::msg( field_alloc, "initWithFrame:", frame ) );
    rt::msg< void >( m_pField, "setSecureTextEntry:", YES );
    rt::msg< void >( m_pField, "setUserInteractionEnabled:", YES );
    rt::msg< void >( m_pField, "setBackgroundColor:", clear_color );
    rt::msg< void >( m_pField, "setOpaque:", NO );
    rt::msg< void >( m_pField, "setAutoresizingMask:",
                     static_cast< NSUInteger >( UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight ) );
    rt::msg< void >( self, "addSubview:", static_cast< id >( m_pField ) );
    m_iResolveTries = 0;

    return self;
}

- ( UIView* )secureCanvasInView:( UIView* )view depth:( int )depth
{
    if ( !view || depth > 8 )
        return nil;

    NSString* class_name = NSStringFromClass( [view class] );
    if ( [class_name rangeOfString:@"Canvas"].location != NSNotFound ||
         [class_name rangeOfString:@"Layout"].location != NSNotFound ||
         [class_name rangeOfString:@"Content"].location != NSNotFound )
    {
        if ( view != m_pField && view != self )
            return view;
    }

    id subviews = rt::msg( static_cast< id >( view ), "subviews" );
    NSUInteger count = rt::msg< NSUInteger >( subviews, "count" );
    for ( NSUInteger i = 0; i < count; i++ )
    {
        UIView* child = static_cast< UIView* >( rt::msg( subviews, "objectAtIndex:", i ) );
        UIView* found = [self secureCanvasInView:child depth:depth + 1];
        if ( found )
            return found;
    }
    return nil;
}

- ( UIView* )secureCanvasFromLayerDelegate
{
    id layer = rt::msg( m_pField, "layer" );
    id sublayers = rt::msg( layer, "sublayers" );
    id first_sub = rt::msg( sublayers, "firstObject" );
    return static_cast< UIView* >( rt::msg( first_sub, "delegate" ) );
}

- ( void )resolveHostIfNeeded
{
    if ( m_pHost )
        return;

    m_iResolveTries++;
    UIView* host = [self secureCanvasInView:m_pField depth:0];
    if ( !host )
        host = [self secureCanvasFromLayerDelegate];
    if ( !host )
        return;

    m_pHost = host;
    id clear_color = rt::msg( rt::cls( "UIColor" ), "clearColor" );
    rt::msg< void >( static_cast< id >( m_pHost ), "setUserInteractionEnabled:", YES );
    rt::msg< void >( static_cast< id >( m_pHost ), "setBackgroundColor:", clear_color );
    rt::msg< void >( static_cast< id >( m_pHost ), "setOpaque:", NO );
}

- ( void )layoutSubviews
{
    [super layoutSubviews];

    CGRect bounds = rt::msg< CGRect >( self, "bounds" );
    rt::msg< void >( m_pField, "setFrame:", bounds );
    rt::msg< void >( m_pField, "layoutIfNeeded" );

    [self resolveHostIfNeeded];
    if ( m_pHost )
    {
        rt::msg< void >( static_cast< id >( m_pHost ), "setFrame:", bounds );
        rt::msg< void >( static_cast< id >( m_pHost ), "setBounds:", bounds );
        rt::msg< void >( static_cast< id >( m_pHost ), "setClipsToBounds:", NO );
    }
}

- ( UIView* )hostView
{
    rt::msg< void >( self, "layoutIfNeeded" );
    [self resolveHostIfNeeded];
    if ( m_pHost )
        return m_pHost;
    if ( m_pField )
        return m_pField;
    return self;
}

- ( UIView* )hitTest:( CGPoint )point withEvent:( UIEvent* )event
{
    UIView* hit = [super hitTest:point withEvent:event];
    if ( hit == self || hit == m_pHost || hit == m_pField )
        return nil;
    return hit;
}

@end
