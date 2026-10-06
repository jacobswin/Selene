//
//  LocalizationHelper.m
//  Selene
//
//  Created by True砖家 on 2024/6/30.
//  Copyright © 2024 True砖家 on Bilibili. All rights reserved.
//

#import "LocalizationHelper.h"
#import <TargetConditionals.h>

@implementation LocalizationHelper

+ (NSString *)resolvedLanguageForPreferredLanguages:(NSArray<NSString *> *)languages {
    NSDictionary *parts = [NSLocale componentsFromLocaleIdentifier:languages.firstObject ?: @"en"];
    NSString *language = [parts[NSLocaleLanguageCode] lowercaseString];
    if (![language isEqualToString:@"zh"]) { return @"en"; }
    NSString *script = parts[NSLocaleScriptCode];
    NSString *region = [parts[NSLocaleCountryCode] uppercaseString];
    if ([script isEqualToString:@"Hant"] ||
        (script.length == 0 && [@[@"TW", @"HK", @"MO"] containsObject:region ?: @""])) {
        return @"zh-Hant";
    }
    return @"zh-Hans";
}

+ (NSInteger)languagePreference {
    NSInteger value = [NSUserDefaults.standardUserDefaults integerForKey:@"MoonlightPlusAppLanguage"];
    return value >= 0 && value <= 3 ? value : 0;
}
+ (void)setLanguagePreference:(NSInteger)preference {
    preference = preference >= 0 && preference <= 3 ? preference : 0;
    [NSUserDefaults.standardUserDefaults setInteger:preference forKey:@"MoonlightPlusAppLanguage"];
    [NSNotificationCenter.defaultCenter postNotificationName:@"MoonlightPlusLanguageDidChange" object:nil];
}
+ (NSString *)currentLanguage {
    NSInteger preference = self.languagePreference;
    return preference ? @[@"zh-Hans", @"zh-Hant", @"en"][preference - 1] :
        [self resolvedLanguageForPreferredLanguages:NSLocale.preferredLanguages];
}
+ (NSString *)localizedFormatForKey:(NSString *)key {
#if TARGET_OS_TV
    NSString *language = self.currentLanguage;
    NSString *path = [NSBundle.mainBundle pathForResource:language ofType:@"lproj"];
    NSBundle *bundle = path ? [NSBundle bundleWithPath:path] : nil;
    NSString *value = [bundle localizedStringForKey:key value:key table:@"Localizable"];
    if (value == nil || [value isEqualToString:key]) {
        NSString *englishPath = [NSBundle.mainBundle pathForResource:@"en" ofType:@"lproj"];
        NSBundle *english = englishPath ? [NSBundle bundleWithPath:englishPath] : nil;
        value = [english localizedStringForKey:key value:key table:@"Localizable"];
    }
    return value ?: key;
#else
    return NSLocalizedStringFromTable(key, @"Localizable", nil);
#endif
}


+ (NSString *)localizedStringForKey:(NSString *)key, ... {
    va_list args;
    va_start(args, key);

    NSString *format = [self localizedFormatForKey:key];
    NSString *result = [[NSString alloc] initWithFormat:format arguments:args];

    va_end(args);
    return result;
}

@end
