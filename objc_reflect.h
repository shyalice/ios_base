#pragma once

#import <objc/message.h>
#import <objc/runtime.h>

#include <type_traits>


namespace rt
{
    template < class R = id, class... A >
    inline R msg( id receiver, const char* selector, A... args )
    {
        using fn_t = R ( * )( id, SEL, A... );
        return reinterpret_cast< fn_t >( objc_msgSend )( receiver, sel_registerName( selector ), args... );
    }

    inline id cls( const char* name )
    {
        return reinterpret_cast< id >( objc_getClass( name ) );
    }

    inline id alloc( const char* class_name )
    {
        return msg( cls( class_name ), "alloc" );
    }
} // namespace rt
