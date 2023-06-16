#import "ExpoDevLauncherBridgeDelegateHandler.h"
#import "EXDevLauncherController.h"

#import <React/RCTBundleURLProvider.h>
#import <React/RCTRuntimeExecutorFromBridge.h>
#import "RCTAppSetupUtils.h"

#ifdef RCT_NEW_ARCH_ENABLED
#import <memory>

#import <React/CoreModulesPlugins.h>
#import <React/RCTFabricSurfaceHostingProxyRootView.h>
#import <React/RCTSurfacePresenter.h>
#import <React/RCTSurfacePresenterBridgeAdapter.h>
#import <ReactCommon/RCTTurboModuleManager.h>
#import <react/config/ReactNativeConfig.h>
#import <React/RCTCxxBridgeDelegate.h>


#import <react/renderer/runtimescheduler/RuntimeScheduler.h>
#import <react/renderer/runtimescheduler/RuntimeSchedulerCallInvoker.h>
#import <React-RCTAppDelegate/RCTAppDelegate.h>

@interface DevClientAppDelegate () <RCTTurboModuleManagerDelegate> {
  std::shared_ptr<const facebook::react::ReactNativeConfig> _reactNativeConfig;
  facebook::react::ContextContainer::Shared _contextContainer;
}
@end

#endif

@interface DevClientAppDelegate () <RCTCxxBridgeDelegate> {
  std::shared_ptr<facebook::react::RuntimeScheduler> _runtimeScheduler;
}
@end

@implementation DevClientAppDelegate

#if RCT_NEW_ARCH_ENABLED
- (instancetype)init
{
  if (self = [super init]) {
    _contextContainer = std::make_shared<facebook::react::ContextContainer const>();
    _reactNativeConfig = std::make_shared<facebook::react::EmptyReactNativeConfig const>();
    _contextContainer->insert("ReactNativeConfig", _reactNativeConfig);
  }
  return self;
}
#endif

- (RCTBridge *)createBridgeAndSetAdapterWithLaunchOptions:(NSDictionary * _Nullable)launchOptions {
  self.bridge = [self createBridgeWithDelegate:self launchOptions:launchOptions];

#ifdef RCT_NEW_ARCH_ENABLED
  self.bridgeAdapter = [[RCTSurfacePresenterBridgeAdapter alloc] initWithBridge:self.bridge
                                                               contextContainer:_contextContainer];
  self.bridge.surfacePresenter = self.bridgeAdapter.surfacePresenter;

  [self unstable_registerLegacyComponents];
#endif

  return self.bridge;
}

#pragma mark - RCTCxxBridgeDelegate
- (std::unique_ptr<facebook::react::JSExecutorFactory>)jsExecutorFactoryForBridge:(RCTBridge *)bridge
{
#if RCT_NEW_ARCH_ENABLED
  _runtimeScheduler = std::make_shared<facebook::react::RuntimeScheduler>(RCTRuntimeExecutorFromBridge(bridge));
  std::shared_ptr<facebook::react::CallInvoker> callInvoker =
      std::make_shared<facebook::react::RuntimeSchedulerCallInvoker>(_runtimeScheduler);
  self.turboModuleManager = [[RCTTurboModuleManager alloc] initWithBridge:bridge delegate:self jsInvoker:callInvoker];
  _contextContainer->erase("RuntimeScheduler");
  _contextContainer->insert("RuntimeScheduler", _runtimeScheduler);
  return RCTAppSetupDefaultJsExecutorFactory(bridge, self.turboModuleManager, _runtimeScheduler);
#else
  if (self.runtimeSchedulerEnabled) {
    _runtimeScheduler = std::make_shared<facebook::react::RuntimeScheduler>(RCTRuntimeExecutorFromBridge(bridge));
  }
  return RCTAppSetupJsExecutorFactoryForOldArch(bridge, _runtimeScheduler);
#endif
}

@end
