#import "SceneDelegate.h"
#import "StreamFrameViewController.h"
#import <GameController/GameController.h>
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST && !TARGET_OS_VISION && __has_include(<UIKit/UISceneAccessory.h>)
#import <UIKit/UISceneAccessory.h>
#import <UIKit/UISceneAccessoryRegistration.h>
#define VL_HAS_EXTERNAL_DISPLAY_ACCESSORY 1
#else
#define VL_HAS_EXTERNAL_DISPLAY_ACCESSORY 0
#endif
#if TARGET_OS_TV
#import "MainFrameViewController.h"
#import "SettingsViewController.h"
#import "SWRevealViewController.h"
#endif

NSNotificationName const SeleneTvOSRemoteMenuTappedNotification = @"SeleneTvOSRemoteMenuTappedNotification";
NSNotificationName const SeleneTvOSRemotePlayPauseTappedNotification = @"SeleneTvOSRemotePlayPauseTappedNotification";

@interface SeleneControllerRootViewController : GCEventViewController <UIGestureRecognizerDelegate>

- (instancetype)initWithContentViewController:(UIViewController *)contentViewController;

@end

@implementation SeleneControllerRootViewController {
    UIViewController *_contentViewController;
}

- (instancetype)initWithContentViewController:(UIViewController *)contentViewController {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _contentViewController = contentViewController;
        self.controllerUserInteractionEnabled = TARGET_OS_TV ? YES : NO;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        self.controllerUserInteractionEnabled = TARGET_OS_TV ? YES : NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.controllerUserInteractionEnabled = TARGET_OS_TV ? YES : NO;
#if TARGET_OS_TV
    // The focus environment can remain in the navigation container during a
    // non-focusable stream. Capture Menu above that container before its pop.
    UITapGestureRecognizer *streamMenu = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openStreamMenu:)];
    streamMenu.allowedPressTypes = @[@(UIPressTypeMenu)];
    streamMenu.delegate = self;
    [self.view addGestureRecognizer:streamMenu];
#endif
    if (!_contentViewController || _contentViewController.parentViewController == self) {
        return;
    }

    [self addChildViewController:_contentViewController];
    _contentViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_contentViewController.view];
    [NSLayoutConstraint activateConstraints:@[
        [_contentViewController.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_contentViewController.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_contentViewController.view.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_contentViewController.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
    [_contentViewController didMoveToParentViewController:self];

}

#if TARGET_OS_TV
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceivePress:(UIPress *)press {
    StreamFrameViewController *stream = [StreamFrameViewController sharedInstance];
    return press.type == UIPressTypeMenu && stream.viewIfLoaded.window == self.view.window &&
        stream.mainFrameViewcontroller.isStreaming && !stream.presentedViewController &&
        !stream.mainFrameViewcontroller.settingsExpandedInStreamView;
}
- (void)openStreamMenu:(UITapGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [[StreamFrameViewController sharedInstance] showTVStreamMenu];
    }
}
// Menu screens use UIKit focus for Siri Remote navigation. Streaming keeps
// its own GCEventViewController and raw game-controller input handling.
- (NSArray<id<UIFocusEnvironment>> *)preferredFocusEnvironments {
    return _contentViewController ? @[_contentViewController] : [super preferredFocusEnvironments];
}
#endif

- (UIViewController *)childViewControllerForStatusBarStyle {
    return _contentViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return _contentViewController;
}

- (UIViewController *)childViewControllerForHomeIndicatorAutoHidden {
    return _contentViewController;
}

- (UIViewController *)childViewControllerForScreenEdgesDeferringSystemGestures {
    return _contentViewController;
}

#if !TARGET_OS_TV
- (UIViewController *)childViewControllerForPointerLock {
    return _contentViewController;
}
#endif

- (BOOL)shouldAutorotate {
    return _contentViewController.shouldAutorotate;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return _contentViewController.supportedInterfaceOrientations;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return _contentViewController.preferredInterfaceOrientationForPresentation;
}

@end

API_AVAILABLE(ios(13.0), tvos(13.0))
@implementation SceneDelegate

static __weak UIView *_sharedStreamVideoRenderView = nil;
static __weak UIView *_localRenderContainer = nil;
static UIViewAutoresizing _localRenderAutoresizingMask;
static UIWindow *_externalSceneWindow = nil;
#if VL_HAS_EXTERNAL_DISPLAY_ACCESSORY
static UISceneAccessoryRegistration *_externalDisplayAccessoryRegistration API_AVAILABLE(ios(27.0));
#endif

static BOOL VLIsExternalDisplaySession(UISceneSession *session) {
    if (@available(iOS 16.0, tvOS 16.0, *)) {
        if ([session.role isEqualToString:UIWindowSceneSessionRoleExternalDisplayNonInteractive]) {
            return YES;
        }
    }
    return [session.role isEqualToString:UIWindowSceneSessionRoleExternalDisplay];
}

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    if ([session.role isEqualToString:UIWindowSceneSessionRoleApplication]) {
#if TARGET_OS_TV
        SettingsViewController *tvOSSettingsViewController = nil;
#endif
        self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
        NSString *storyboardName;
#if TARGET_OS_TV
        storyboardName = @"Main";
#else
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            storyboardName = @"iPad";
        } else {
            storyboardName = @"iPhone";
        }
#endif
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
        UIViewController *initialViewController = [storyboard instantiateInitialViewController];
#if TARGET_OS_TV
        if ([initialViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *frontNavigationController = (UINavigationController *)initialViewController;
            SettingsViewController *settingsViewController = [[SettingsViewController alloc] init];
            tvOSSettingsViewController = settingsViewController;
            SWRevealViewController *revealViewController = [[SWRevealViewController alloc] initWithRearViewController:settingsViewController
                                                                                                   frontViewController:frontNavigationController];
            UIViewController *topViewController = frontNavigationController.topViewController;
            if ([topViewController isKindOfClass:[MainFrameViewController class]]) {
                MainFrameViewController *mainFrameViewController = (MainFrameViewController *)topViewController;
                mainFrameViewController.settingsViewController = settingsViewController;
                settingsViewController.mainFrameViewController = mainFrameViewController;
                [revealViewController setDelegate:mainFrameViewController];
                revealViewController.bounceBackOnOverdraw = NO;
            }
            initialViewController = revealViewController;
        }
#endif
        self.window.rootViewController = [[SeleneControllerRootViewController alloc] initWithContentViewController:initialViewController];
        [self.window makeKeyAndVisible];
#if VL_HAS_EXTERNAL_DISPLAY_ACCESSORY
        if (@available(iOS 27.0, *)) {
            UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
                initWithName:@"Selene External Display"
                sessionRole:UIWindowSceneSessionRoleExternalDisplayNonInteractive];
            configuration.delegateClass = SceneDelegate.class;
            UISceneAccessory *accessory = [UISceneAccessory externalNonInteractiveSceneAccessoryWithConfiguration:configuration];
            _externalDisplayAccessoryRegistration = [self.window.rootViewController registerSceneAccessory:accessory];
        }
#endif
#if TARGET_OS_TV
        // SWReveal keeps the rear controller unloaded until it is revealed.
        // Preheat the SwiftUI settings hierarchy without consuming its
        // launch-time settings snapshot; the first real reveal consumes it.
        [tvOSSettingsViewController loadViewIfNeeded];
        tvOSSettingsViewController.view.frame = self.window.bounds;
        [tvOSSettingsViewController.view setNeedsLayout];
        [tvOSSettingsViewController.view layoutIfNeeded];
        if (@available(tvOS 14.0, *)) {
            [tvOSSettingsViewController refreshSwiftUISettingsGeometry];
        }
#endif
        Log(LOG_I, @"SceneDelegate: Main app scene connected.");

    } else if (VLIsExternalDisplaySession(session)) {
        Log(LOG_I, @"SceneDelegate: External display scene connecting for screen: %@", ((UIWindowScene *)scene).screen.description);
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        _externalSceneWindow = [[UIWindow alloc] initWithWindowScene:windowScene];
        UIViewController *externalVC = [[UIViewController alloc] init];
        externalVC.view.backgroundColor = [UIColor blackColor]; // Set a default background
        _externalSceneWindow.rootViewController = externalVC;

        [SceneDelegate attachExternalDisplayRenderViewIfReady];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ScreenChanged" object:windowScene];
    }
}


+ (void)attachExternalDisplayRenderViewIfReady {
    NSAssert(NSThread.isMainThread, @"External display routing must run on the main thread");
    UIView *renderView = _sharedStreamVideoRenderView;
    UIView *container = _externalSceneWindow.rootViewController.view;
    if (!renderView || !container || renderView.superview == container) {
        return;
    }
    renderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    renderView.frame = container.bounds;
    [container addSubview:renderView];
    _externalSceneWindow.hidden = NO;
    Log(LOG_I, @"SceneDelegate: Stream attached to external display.");
}

+ (void)restoreLocalRenderView {
    UIView *renderView = _sharedStreamVideoRenderView;
    UIView *container = _localRenderContainer;
    if (renderView && container && renderView.superview != container) {
        renderView.autoresizingMask = _localRenderAutoresizingMask;
        renderView.frame = container.bounds;
        [container insertSubview:renderView atIndex:0];
        Log(LOG_I, @"SceneDelegate: Stream restored to local display.");
    }
    _externalSceneWindow.hidden = YES;
}

+ (void)setExternalDisplayRenderView:(UIView *)renderView localContainer:(UIView *)localContainer {
    NSAssert(NSThread.isMainThread, @"External display routing must run on the main thread");
    if (!renderView || !localContainer) {
        return;
    }
    if (_sharedStreamVideoRenderView != renderView) {
        [self restoreLocalRenderView];
        _localRenderAutoresizingMask = renderView.autoresizingMask;
    }
    _sharedStreamVideoRenderView = renderView;
    _localRenderContainer = localContainer;
    [self attachExternalDisplayRenderViewIfReady];
}

+ (void)clearExternalDisplayRenderView:(UIView *)renderView {
    NSAssert(NSThread.isMainThread, @"External display routing must run on the main thread");
    if (!renderView || _sharedStreamVideoRenderView != renderView) {
        return;
    }
    [self restoreLocalRenderView];
    _sharedStreamVideoRenderView = nil;
    _localRenderContainer = nil;
}

+ (BOOL)isExternalDisplayRenderView:(UIView *)renderView {
    return renderView && renderView == _sharedStreamVideoRenderView &&
        _externalSceneWindow && !_externalSceneWindow.hidden &&
        renderView.superview == _externalSceneWindow.rootViewController.view;
}

- (void)sceneDidBecomeActive:(UIScene *)scene {
#if TARGET_OS_TV
    if (scene == self.window.windowScene &&
        [self.window.rootViewController isKindOfClass:[SeleneControllerRootViewController class]]) {
        [self.window.rootViewController setNeedsFocusUpdate];
        [self.window.rootViewController updateFocusIfNeeded];
    }
#endif
}

- (void)sceneDidDisconnect:(UIScene *)scene {
    Log(LOG_I, @"SceneDelegate: Scene disconnected: %@, role: %@", scene.title, scene.session.role);

    if (VLIsExternalDisplaySession(scene.session)) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            if (_externalSceneWindow == windowScene.windows.firstObject) { // Compare with the window from the disconnecting scene
                [SceneDelegate restoreLocalRenderView];
                _externalSceneWindow = nil;
                Log(LOG_I, @"SceneDelegate: External display scene fully disconnected and cleaned up.");
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ScreenChanged" object:windowScene];
            } else {
                Log(LOG_W, @"SceneDelegate: Disconnecting scene is not the one holding our _externalSceneWindow.");
            }
        } else {
            Log(LOG_W, @"SceneDelegate: Disconnecting scene is not a UIWindowScene.");
        }
    }
}

@end
