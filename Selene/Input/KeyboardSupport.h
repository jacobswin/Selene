//
//  KeyboardSupport.h
//  Moonlight
//
//  Created by Diego Waxemberg on 8/25/18.
//  Copyright © 2018 Moonlight Game Streaming Project. All rights reserved.
//

#import <Foundation/Foundation.h>

int SeleneSendKeyboardEvent(short keyCode, char action, char modifiers);

@interface KeyboardSupport : NSObject
+ (BOOL)forwardingSuspended;
+ (void)setForwardingSuspended:(BOOL)suspended;
+ (void)releaseAllKeys;
+ (void)performShortcut:(NSArray<NSNumber *> *)keys completion:(void (^)(void))completion;

struct KeyEvent {
    u_short keycode;
    u_short modifierKeycode;
    u_char modifier;
};

+ (BOOL)sendKeyEventForPress:(UIPress*)press down:(BOOL)down API_AVAILABLE(ios(13.4));
+ (BOOL)sendKeyEvent:(UIKey*)key down:(BOOL)down API_AVAILABLE(ios(13.4));
+ (struct KeyEvent) translateKeyEvent:(unichar) inputChar withModifierFlags:(UIKeyModifierFlags)modifierFlags;

@end
