#pragma once

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OverlayLoader : NSObject

+ ( instancetype )shared;
- ( void )showMenu;
- ( void )hideMenu;

@end

NS_ASSUME_NONNULL_END
