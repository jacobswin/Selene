//
//  FixedTintImageView.m
//  Selene
//
//  Created by True砖家 on 2025/6/1.
//  Copyright © 2025 True砖家 @ Bilibili. All rights reserved.
//

#import "FixedTintImageView.h"


@interface FixedTintButton()
@property (nonatomic, strong) UIColor *fixedTintColor;
@end

@implementation FixedTintButton

- (void)tintColorDidChange {
    [super tintColorDidChange];
    // 强制 tint 保持固定颜色
    if (self.fixedTintColor) {
        [self setImage:[self.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        self.tintColor = self.fixedTintColor;
    }
}

- (void)setTintColor:(UIColor *)tintColor {
    _fixedTintColor = tintColor;
    [super setTintColor:tintColor];
}

@end



@interface FixedTintImageView ()
@property (nonatomic, strong) UIColor *fixedTintColor;
@end

@implementation FixedTintImageView

- (instancetype)initWithImage:(UIImage *)image {
    self = [super initWithImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    if (self) {
        // _fixedTintColor = [UIColor systemBlueColor]; // 默认颜色
        if(_fixedTintColor != nil) [super setTintColor:_fixedTintColor];
    }
    return self;
}

- (void)setTintColor:(UIColor *)tintColor {
    if(tintColor != nil){
        _fixedTintColor = tintColor;
        [super setTintColor:tintColor];
    }
}

- (void)tintColorDidChange {
    // 保持你固定的颜色，忽略系统的暗淡变更
    if(_fixedTintColor != nil) [super setTintColor:_fixedTintColor];
}

@end
