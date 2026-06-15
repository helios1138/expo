// Copyright 2025-present 650 Industries. All rights reserved.

// Defines `WorkletRuntimeInstaller::resolveUIRuntimePointer` in its own
// translation unit: `StableApi.h` fully defines `worklets::Serializable`, which
// collides with the internal worklets headers included by
// `WorkletRuntimeInstaller.cpp`. Resolving through the stable API functions also
// runs `getNativeState` inside libworklets.so, so the `WorkletRuntimeHolder`
// typeinfo matches the one used when the holder was created.

#include "WorkletRuntimeInstaller.h"

#if WORKLETS_ENABLED
#include <worklets/Compat/StableApi.h>
#endif

namespace jni = facebook::jni;
namespace jsi = facebook::jsi;

namespace expo {

jlong WorkletRuntimeInstaller::resolveUIRuntimePointer(
  jni::alias_ref<jni::JClass>,
  jni::alias_ref<JavaScriptObject::javaobject> uiRuntimeHolder
) noexcept {
#if WORKLETS_ENABLED
  auto *holder = uiRuntimeHolder->cthis();
  jsi::Runtime &runtime = holder->getRuntime();
  std::shared_ptr<jsi::Object> holderObject = holder->get();

  std::shared_ptr<worklets::WorkletRuntime> workletRuntime =
    worklets::getWorkletRuntimeFromHolder(runtime, *holderObject);
  if (!workletRuntime) {
    return 0;
  }

  jsi::Runtime &uiRuntime = worklets::getJSIRuntimeFromWorkletRuntime(workletRuntime);
  return reinterpret_cast<jlong>(&uiRuntime);
#else
  return 0;
#endif
}

} // namespace expo
