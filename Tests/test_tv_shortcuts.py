"""Exercise the production explicit-key sender with a fake Moonlight transport."""
from pathlib import Path
import subprocess,tempfile
s=(Path(__file__).resolve().parents[1]/'Selene/Input/KeyboardSupport.m').read_text()
state=s.split('static BOOL seleneInputSuspended')[1].split('+ (BOOL)sendKeyEventForPress:')[0]
program=r'''
#import <Foundation/Foundation.h>
#undef TARGET_OS_TV
#define TARGET_OS_TV 1
#define KEY_ACTION_DOWN 3
#define KEY_ACTION_UP 4
#define MODIFIER_ALT 4
#define MODIFIER_META 8
#define MODIFIER_CTRL 2
#define MODIFIER_SHIFT 1
static NSMutableArray *events;
int LiSendKeyboardEvent(short key, char action, char modifiers) {
 [events addObject:@[@((unsigned short)key),@(action),@(modifiers)]]; return 0;
}
@interface KeyboardSupport:NSObject
+ (void)releaseAllKeys;
+ (void)setForwardingSuspended:(BOOL)value;
+ (void)performShortcut:(NSArray*)keys completion:(void(^)(void))completion;
@end
static BOOL seleneInputSuspended'''+state+r'''
@end
int main() { @autoreleasepool {
 events=[NSMutableArray new];
 [KeyboardSupport setForwardingSuspended:YES];
 SeleneSendKeyboardEvent(0x8041,KEY_ACTION_DOWN,0); assert(events.count==0);
 __block BOOL done=NO;
 [KeyboardSupport performShortcut:@[@0xA4,@0x09] completion:^{done=YES;}];
 while(!done) [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
 NSArray *expected=@[@[@0x80A4,@3,@4],@[@0x8009,@3,@4],@[@0x8009,@4,@4],@[@0x80A4,@4,@0]];
 assert([events isEqual:expected]);
 [events removeAllObjects];done=NO;
 [KeyboardSupport performShortcut:@[@0x5B] completion:^{done=YES;}];
 [KeyboardSupport releaseAllKeys];
 while(!done) [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
 assert(events.count==2); // cancellation released the key; timer does not duplicate it
 [KeyboardSupport setForwardingSuspended:NO];
 [events removeAllObjects]; SeleneSendKeyboardEvent(0x8041,KEY_ACTION_DOWN,0);
 [KeyboardSupport setForwardingSuspended:YES]; assert(events.count==2);
 puts("PASS: ordinary input suspension, explicit Alt+Tab ordering, modifier release and cancelled-key cleanup");
 } return 0; }
'''
with tempfile.TemporaryDirectory() as directory:
 p=Path(directory)/'keys.m';p.write_text(program);binary=Path(directory)/'keys'
 subprocess.run(['/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang','-fobjc-arc','-fblocks','-framework','Foundation',str(p),'-o',str(binary)],check=True)
 subprocess.run([str(binary)],check=True)
