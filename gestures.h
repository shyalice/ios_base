#pragma once

#import <UIKit/UIKit.h>
#include <functional>

namespace imgui
{

    class Gestures
    {
    public:
        using callback_t = std::function< void( ) >;

        Gestures( ) = default;
        Gestures( const Gestures& ) = delete;
        Gestures& operator=( const Gestures& ) = delete;

        void attach( UIView* host );
        void on( int fingers, int taps, callback_t cb );
        void detachAll( );

    private:
        UIView* m_pHost = nil;
        NSMutableArray* m_pBindings = nil;
    };

} // namespace imgui
