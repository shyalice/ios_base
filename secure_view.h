#pragma once

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SecureView : UIView

+ ( instancetype )build;

@property ( nonatomic, readonly ) UIView* hostView;

@end

NS_ASSUME_NONNULL_END
