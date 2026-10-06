//
//  LocalizationHelper.h
//  Selene
//
//  Created by True砖家 on 2024/6/30.
//  Copyright © 2024 True砖家 on Bilibili. All rights reserved.
//

#ifndef LocalizationHelper_h
#define LocalizationHelper_h

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LocalizationHelper : NSObject

+ (NSString *)resolvedLanguageForPreferredLanguages:(NSArray<NSString *> *)languages;
+ (NSInteger)languagePreference;
+ (void)setLanguagePreference:(NSInteger)preference;
+ (NSString *)currentLanguage;
+ (NSString *)localizedFormatForKey:(NSString *)key;

// Method to get localized string with format arguments
+ (NSString *)localizedStringForKey:(NSString *)key, ... NS_FORMAT_FUNCTION(1,2);

@end

NS_ASSUME_NONNULL_END

#endif /* LocalizationHelper_h */
