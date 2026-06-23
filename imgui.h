#pragma once

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImGuiView : UIView

- ( void )setInteractive:( BOOL )interactive;
- ( BOOL )isInteractive;

@end

NS_ASSUME_NONNULL_END
