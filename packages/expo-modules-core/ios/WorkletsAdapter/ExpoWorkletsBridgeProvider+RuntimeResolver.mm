// Copyright 2025-present 650 Industries. All rights reserved.

// Lives in its own translation unit: `StableApi.h` fully defines
// `worklets::Serializable`, which collides with the internal worklets headers
// included by `ExpoWorkletsBridgeProvider.mm`.

#import "ExpoWorkletsBridgeProvider.h"
#import <ExpoModulesWorklets/EXWorkletsProvider.h>

#include <memory>
#include <jsi/jsi.h>
#include <worklets/Compat/StableApi.h>

namespace jsi = facebook::jsi;

@interface ExpoWorkletsBridgeProvider (RuntimeResolver) <EXWorkletsRuntimeResolving>
@end

@implementation ExpoWorkletsBridgeProvider (RuntimeResolver)

- (void * _Nullable)uiRuntimePointerWithRuntimePointer:(void *)runtimePointer
                                         holderPointer:(const void *)holderPointer
{
  jsi::Runtime &rt = *reinterpret_cast<jsi::Runtime *>(runtimePointer);
  const jsi::Value &holderValue = *reinterpret_cast<const jsi::Value *>(holderPointer);

  if (!holderValue.isObject()) {
    return nullptr;
  }

  jsi::Object holder = holderValue.getObject(rt);
  std::shared_ptr<worklets::WorkletRuntime> workletRuntime = worklets::getWorkletRuntimeFromHolder(rt, holder);
  if (!workletRuntime) {
    return nullptr;
  }

  jsi::Runtime &uiRuntime = worklets::getJSIRuntimeFromWorkletRuntime(workletRuntime);
  return &uiRuntime;
}

@end
