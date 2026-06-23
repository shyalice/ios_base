#import "gestures.h"

#import "objc_reflect.h"

@interface ImGuiGestureBinding : NSObject
- ( instancetype )initWithCallback:( imgui::Gestures::callback_t )cb;
- ( void )fire:( UIGestureRecognizer* )recognizer;
@property ( nonatomic, strong, nullable ) UITapGestureRecognizer* recognizer;
@end

@implementation ImGuiGestureBinding {
    imgui::Gestures::callback_t m_callback;
}
- ( instancetype )initWithCallback:( imgui::Gestures::callback_t )cb
{
    if ( !( self = [super init] ) )
        return nil;
    m_callback = std::move( cb );
    return self;
}
- ( void )fire:( UIGestureRecognizer* )recognizer
{
    if ( m_callback )
        m_callback( );
}
@end

namespace imgui
{
    void Gestures::attach( UIView* host )
    {
        m_pHost = host;
        if ( !m_pBindings )
        {
            m_pBindings = static_cast< NSMutableArray* >( rt::msg( rt::alloc( "NSMutableArray" ), "init" ) );
        }
    }

    void Gestures::on( int fingers, int taps, callback_t cb )
    {
        if ( !m_pHost || !cb )
            return;

        ImGuiGestureBinding* binding = [[ImGuiGestureBinding alloc] initWithCallback:std::move( cb )];

        id rec = rt::msg( rt::alloc( "UITapGestureRecognizer" ),
                          "initWithTarget:action:",
                          static_cast< id >( binding ), sel_registerName( "fire:" ) );
        rt::msg< void >( rec, "setNumberOfTapsRequired:", static_cast< NSUInteger >( taps ) );
        rt::msg< void >( rec, "setNumberOfTouchesRequired:", static_cast< NSUInteger >( fingers ) );
        binding.recognizer = static_cast< UITapGestureRecognizer* >( rec );

        rt::msg< void >( m_pHost, "addGestureRecognizer:", rec );
        rt::msg< void >( m_pBindings, "addObject:", static_cast< id >( binding ) );
    }

    void Gestures::detachAll( )
    {
        if ( !m_pHost || !m_pBindings )
            return;
        NSUInteger count = rt::msg< NSUInteger >( m_pBindings, "count" );
        for ( NSUInteger i = 0; i < count; i++ )
        {
            id b = rt::msg( m_pBindings, "objectAtIndex:", i );
            id rec = rt::msg( b, "recognizer" );
            if ( rec )
                rt::msg< void >( m_pHost, "removeGestureRecognizer:", rec );
        }
        rt::msg< void >( m_pBindings, "removeAllObjects" );
        m_pHost = nil;
    }
} // namespace imgui
