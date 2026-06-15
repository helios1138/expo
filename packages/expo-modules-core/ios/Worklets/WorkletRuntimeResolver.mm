// Copyright 2025-present 650 Industries. All rights reserved.

#import <ExpoModulesWorklets/WorkletRuntimeResolver.h>
#import <ExpoModulesWorklets/EXWorkletsProvider.h>

@implementation EXWorkletRuntimeResolver

+ (void * _Nullable)uiRuntimePointerWithRuntimePointer:(void *)runtimePointer
                                         holderPointer:(const void *)holderPointer
{
  id<EXWorkletsRuntimeResolving> resolver = (id<EXWorkletsRuntimeResolving>)EXWorkletsProviderRegistry.shared;
  return [resolver uiRuntimePointerWithRuntimePointer:runtimePointer holderPointer:holderPointer];
}

@end
