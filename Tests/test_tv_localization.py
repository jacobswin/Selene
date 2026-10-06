"""Exercise the production language resolver and localized format contracts."""
import json
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory() as directory:
    directory = Path(directory)
    main = directory / 'main.m'
    main.write_text(r'''
#import <Foundation/Foundation.h>
#import "LocalizationHelper.h"
int main(void) {
    @autoreleasepool {
        id previous = [NSUserDefaults.standardUserDefaults objectForKey:@"MoonlightPlusAppLanguage"];
        NSArray *choices = @[@"zh-Hans", @"zh-Hant", @"en"];
        for (NSInteger preference = 1; preference <= 3; preference++) {
            [LocalizationHelper setLanguagePreference:preference];
            if (LocalizationHelper.languagePreference != preference ||
                ![LocalizationHelper.currentLanguage isEqualToString:choices[preference - 1]]) { return 2; }
        }
        [LocalizationHelper setLanguagePreference:0];
        if (![LocalizationHelper.currentLanguage isEqualToString:
            [LocalizationHelper resolvedLanguageForPreferredLanguages:NSLocale.preferredLanguages]]) { return 3; }
        [LocalizationHelper setLanguagePreference:99];
        if (LocalizationHelper.languagePreference != 0) { return 4; }
        if (previous) {
            [NSUserDefaults.standardUserDefaults setObject:previous forKey:@"MoonlightPlusAppLanguage"];
        } else {
            [NSUserDefaults.standardUserDefaults removeObjectForKey:@"MoonlightPlusAppLanguage"];
        }
        NSArray *cases = @[
            @[@[@"en"], @"en"], @[@[@"en-GB"], @"en"],
            @[@[@"zh-Hans-CN"], @"zh-Hans"], @[@[@"zh-CN"], @"zh-Hans"],
            @[@[@"zh-SG"], @"zh-Hans"], @[@[@"zh"], @"zh-Hans"],
            @[@[@"zh-Hant-TW"], @"zh-Hant"], @[@[@"zh-TW"], @"zh-Hant"],
            @[@[@"zh-HK"], @"zh-Hant"], @[@[@"zh-MO"], @"zh-Hant"],
            @[@[@"zh-Hans-HK"], @"zh-Hans"], @[@[@"zh-Hant-CN"], @"zh-Hant"],
            @[@[@"ja-JP", @"zh-Hans"], @"en"], @[@[@"fr-FR"], @"en"],
            @[@[@"de-DE"], @"en"], @[@[], @"en"]
        ];
        for (NSArray *test in cases) {
            NSString *actual = [LocalizationHelper resolvedLanguageForPreferredLanguages:test[0]];
            if (![actual isEqualToString:test[1]]) { NSLog(@"%@ -> %@",test[0],actual); return 1; }
        }
    }
    return 0;
}
''')
    executable = directory / 'language-test'
    subprocess.run([
        '/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang',
        '-fobjc-arc', '-framework', 'Foundation',
        '-I', str(ROOT / 'Selene/Localization'),
        str(main), str(ROOT / 'Selene/Localization/LocalizationHelper.m'),
        '-o', str(executable)
    ], check=True)
    subprocess.run([str(executable)], check=True)

catalog = json.loads((ROOT / 'Selene/Localization/Localizable.xcstrings').read_text())['strings']
# Test user-visible paths that introduced formatted messages and previously mixed languages.
keys = ['Language', 'Follow System', 'Settings', 'Video', 'Audio', 'On', 'Device capabilities',
        'Left/right to switch areas · Select to edit · Back to close',
        'Host rejected the request (status %d). Kept %.1f Mbps.',
        'Saved AV1 is unavailable on this device. Switched to %@.',
        'HEVC: %@ · AV1: %@',
        'Requested bitrate: %.1f Mbps · Received bitrate: %.1f Mbps\nNegotiated format: %@\n%@',
        'Enter exact bitrate (Mbps)', 'AV1 unavailable', 'Retry in SDR from the main screen']
formats = re.compile(r'%(?:\d+\$)?[-+ #0]*(?:\d+)?(?:\.\d+)?(?:ll|l|z)?[@diufFeEgGs]')
for key in keys:
    expected = formats.findall(key)
    for language in ('en', 'zh-Hans', 'zh-Hant'):
        value = catalog[key].get('localizations', {}).get(language, {}).get('stringUnit', {}).get('value')
        if language == 'en' and value is None:
            value = key  # English is the catalog source language.
        assert value, (key, language)
        assert formats.findall(value) == expected, (key, language, value)
print('PASS: saved language choices, system selection, invalid preference, 16 regional/fallback cases, three-language UI coverage and formatted arguments')
