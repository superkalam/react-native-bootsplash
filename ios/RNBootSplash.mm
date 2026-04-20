#import "RNBootSplash.h"

#import <React/RCTUtils.h>

#if RCT_NEW_ARCH_ENABLED
#import <React/RCTSurfaceHostingProxyRootView.h>
#import <React/RCTSurfaceHostingView.h>

static RCTSurfaceHostingProxyRootView *_rootView = nil;
#else
#import <React/RCTRootView.h>

static UIView *_rootView = nil;
#endif

static UIView *_loadingView = nil;
static NSMutableArray<RCTPromiseResolveBlock> *_resolveQueue = [[NSMutableArray alloc] init];
static bool _fade = false;
static bool _nativeHidden = false;
static NSString *_currentText = @"";
static NSString *_lightTextColor = @"";
static NSString *_darkTextColor = @"";
static UILabel *_statusLabel = nil;

@implementation RNBootSplash

RCT_EXPORT_MODULE();

+ (BOOL)requiresMainQueueSetup {
  return NO;
}

- (dispatch_queue_t)methodQueue {
  return dispatch_get_main_queue();
}

+ (bool)isLoadingViewVisible {
  return _loadingView != nil && ![_loadingView isHidden];
}

+ (void)clearResolveQueue {
  while ([_resolveQueue count] > 0) {
    RCTPromiseResolveBlock resolve = [_resolveQueue objectAtIndex:0];
    [_resolveQueue removeObjectAtIndex:0];
    resolve(@(true));
  }
}

+ (void)hideAndClearPromiseQueue {
  if (![self isLoadingViewVisible]) {
    return [RNBootSplash clearResolveQueue];
  }

  if (_fade) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [UIView transitionWithView:_rootView
                        duration:0.250
                         options:UIViewAnimationOptionTransitionCrossDissolve
                      animations:^{
        _loadingView.hidden = YES;
      }
                      completion:^(__unused BOOL finished) {
        [_loadingView removeFromSuperview];
        _loadingView = nil;
        _statusLabel = nil;

        return [RNBootSplash clearResolveQueue];
      }];
    });
  } else {
    _loadingView.hidden = YES;
    [_loadingView removeFromSuperview];
    _loadingView = nil;
    _statusLabel = nil;

    return [RNBootSplash clearResolveQueue];
  }
}

+ (void)initWithStoryboard:(NSString * _Nonnull)storyboardName
                  rootView:(UIView * _Nullable)rootView {
  if (RCTRunningInAppExtension()) {
    return;
  }

  [NSTimer scheduledTimerWithTimeInterval:0.35
                                  repeats:NO
                                    block:^(NSTimer * _Nonnull timer) {
    // wait for native iOS launch screen to fade out
    _nativeHidden = true;

    // hide has been called before native launch screen fade out
    if ([_resolveQueue count] > 0) {
      [self hideAndClearPromiseQueue];
    }
  }];

  if (rootView != nil) {
#ifdef RCT_NEW_ARCH_ENABLED
    _rootView = (RCTSurfaceHostingProxyRootView *)rootView;
#else
    _rootView = (RCTRootView *)rootView;
#endif

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:nil];

    _loadingView = [[storyboard instantiateInitialViewController] view];
    _loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _loadingView.frame = _rootView.bounds;
    _loadingView.center = (CGPoint){CGRectGetMidX(_rootView.bounds), CGRectGetMidY(_rootView.bounds)};
    _loadingView.hidden = NO;

    // Create and add status label
    _statusLabel = [[UILabel alloc] init];
    _statusLabel.textAlignment = NSTextAlignmentCenter;
    _statusLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    _statusLabel.alpha = 1.0;
    _statusLabel.hidden = YES;
    _statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Set text color based on dark mode
    if (@available(iOS 13.0, *)) {
      _statusLabel.textColor = [UIColor labelColor];
    } else {
      _statusLabel.textColor = [UIColor blackColor];
    }
    
    [_loadingView addSubview:_statusLabel];
    
    // Set up constraints for status label
    [NSLayoutConstraint activateConstraints:@[
      [_statusLabel.centerXAnchor constraintEqualToAnchor:_loadingView.centerXAnchor],
      [_statusLabel.bottomAnchor constraintEqualToAnchor:_loadingView.safeAreaLayoutGuide.bottomAnchor constant:-120],
      [_statusLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:_loadingView.leadingAnchor constant:20],
      [_statusLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_loadingView.trailingAnchor constant:-20]
    ]];

#if RCT_NEW_ARCH_ENABLED
    [_rootView disableActivityIndicatorAutoHide:YES];
    [_rootView setLoadingView:_loadingView];
#else
    [_rootView addSubview:_loadingView];
#endif

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onJavaScriptDidLoad)
                                                 name:RCTJavaScriptDidLoadNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onJavaScriptDidFailToLoad)
                                                 name:RCTJavaScriptDidFailToLoadNotification
                                               object:nil];
  }
}

+ (void)onJavaScriptDidLoad {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (void)onJavaScriptDidFailToLoad {
  [self hideAndClearPromiseQueue];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSDictionary *)constantsToExport {
  __block bool darkModeEnabled = false;

  RCTUnsafeExecuteOnMainQueueSync(^{
    UIWindow *window = RCTKeyWindow();
    darkModeEnabled = window != nil && window.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
  });

  return @{
    @"darkModeEnabled": @(darkModeEnabled)
  };
}

- (void)setTextImpl:(NSString *)text {
  if (RCTRunningInAppExtension()) {
    return;
  }
  
  // Handle null text parameter from JavaScript
  if (text == nil) {
    text = @"";
  }
  
  _currentText = text;
  
  dispatch_async(dispatch_get_main_queue(), ^{
    if (_statusLabel != nil && _loadingView != nil && ![_loadingView isHidden]) {
      _statusLabel.text = text;
      _statusLabel.hidden = text.length == 0;
    }
  });
}

- (UIColor *)colorFromHexString:(NSString *)hexString {
  if (hexString == nil || [hexString length] == 0) {
    return nil;
  }

  unsigned rgbValue = 0;
  NSString *colorString = hexString;

  // Remove # if present
  if ([colorString hasPrefix:@"#"]) {
    colorString = [colorString substringFromIndex:1];
  }

  NSScanner *scanner = [NSScanner scannerWithString:colorString];
  [scanner scanHexInt:&rgbValue];

  return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0
                         green:((rgbValue & 0xFF00) >> 8)/255.0
                          blue:(rgbValue & 0xFF)/255.0
                         alpha:1.0];
}

- (void)setTextColorImpl:(NSString *)lightColor darkColor:(NSString *)darkColor {
  if (RCTRunningInAppExtension()) {
    return;
  }

  // Handle null parameters
  if (lightColor == nil) {
    lightColor = @"";
  }
  if (darkColor == nil) {
    darkColor = lightColor; // Use lightColor as fallback
  }

  _lightTextColor = lightColor;
  _darkTextColor = darkColor;

  dispatch_async(dispatch_get_main_queue(), ^{
    if (_statusLabel != nil && _loadingView != nil && ![_loadingView isHidden]) {
      UIWindow *window = RCTKeyWindow();
      BOOL isDarkMode = NO;

      if (@available(iOS 13.0, *)) {
        isDarkMode = window != nil && window.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
      }

      NSString *colorToUse = (isDarkMode && darkColor.length > 0) ? darkColor : lightColor;

      if (colorToUse.length > 0) {
        UIColor *color = [self colorFromHexString:colorToUse];
        if (color != nil) {
          _statusLabel.textColor = color;
        }
      }
    }
  });
}

- (void)hideImpl:(BOOL)fade
         resolve:(RCTPromiseResolveBlock)resolve {
  if (RCTRunningInAppExtension()) {
    return resolve(@(true));
  }

  [_resolveQueue addObject:resolve];
  _fade = fade;

  if (_nativeHidden) {
    return [RNBootSplash hideAndClearPromiseQueue];
  }
}

- (void)isVisibleImpl:(RCTPromiseResolveBlock)resolve {
  resolve(@([RNBootSplash isLoadingViewVisible]));
}

#ifdef RCT_NEW_ARCH_ENABLED

// New architecture

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const facebook::react::ObjCTurboModule::InitParams &)params {
  return std::make_shared<facebook::react::NativeRNBootSplashSpecJSI>(params);
}

- (facebook::react::ModuleConstants<JS::NativeRNBootSplash::Constants::Builder>)getConstants {
  return [self constantsToExport];
}

- (void)hide:(BOOL)fade
     resolve:(RCTPromiseResolveBlock)resolve
      reject:(RCTPromiseRejectBlock)reject {
  [self hideImpl:fade resolve:resolve];
}

- (void)isVisible:(RCTPromiseResolveBlock)resolve
           reject:(RCTPromiseRejectBlock)reject {
  [self isVisibleImpl:resolve];
}

- (void)setText:(NSString *)text {
  [self setTextImpl:text];
}

- (void)setTextColor:(NSString *)lightColor darkColor:(NSString *)darkColor {
  [self setTextColorImpl:lightColor darkColor:darkColor];
}

#else

// Old architecture

RCT_EXPORT_METHOD(hide:(BOOL)fade
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
  [self hideImpl:fade resolve:resolve];
}

RCT_EXPORT_METHOD(isVisible:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
  [self isVisibleImpl:resolve];
}

RCT_EXPORT_METHOD(setText:(NSString *)text) {
  [self setTextImpl:text];
}

RCT_EXPORT_METHOD(setTextColor:(NSString *)lightColor darkColor:(NSString *)darkColor) {
  [self setTextColorImpl:lightColor darkColor:darkColor];
}

#endif

@end
