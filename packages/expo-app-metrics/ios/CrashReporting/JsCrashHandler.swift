// Copyright 2025-present 650 Industries. All rights reserved.

import Foundation
import React

/// Captures fatal JavaScript crashes by installing an `RCTFatalHandler`.
///
/// In a release/TestFlight build, an unhandled JS exception is routed by `RCTExceptionsManager`
/// through `RCTFatal`, which calls the process-global fatal handler and then aborts. We install our
/// own handler to record the crash before that abort, then chain to whatever handler was installed
/// before us (RN's default, or another SDK such as expo-updates) so termination behavior is
/// unchanged. The `NSError` carries the parsed JS stack under `RCTJSStackTraceKey` and the message
/// in its localized description (the data MetricKit can't surface for an RN crash).
///
/// Install is explicit (opt-in) rather than automatic, and idempotent.
enum JsCrashHandler {
  /// RN prefixes the fatal error's description with this; we strip it to recover the bare message.
  private static let messagePrefix = "Unhandled JS Exception: "

  nonisolated(unsafe) private static var previousFatalHandler: RCTFatalHandler?
  nonisolated(unsafe) private static var isInstalled = false

  /// Installs the fatal handler. Safe to call more than once; only the first call takes effect.
  static func install() {
    guard !isInstalled else {
      return
    }
    isInstalled = true

    previousFatalHandler = RCTGetFatalHandler()
    RCTSetFatalHandler { error in
      if let error {
        handleFatal(error: error as NSError)
      }
      // Chain to the handler we replaced so RN's (or another SDK's) abort/logging still runs.
      previousFatalHandler?(error)
    }
  }

  private static func handleFatal(error: NSError) {
    let rawStack = error.userInfo[RCTJSStackTraceKey] as? [[String: Any]]
    JsCrashRecorder.record(
      message: strippedMessage(from: error.localizedDescription),
      name: nil,
      rawStack: rawStack,
      isFatal: true
    )
  }

  /// Recovers the bare JS message from RN's error description, dropping the `RCTFatal` prefix when
  /// present. Internal (not private) so it can be unit-tested without a live `RCTFatal`.
  static func strippedMessage(from description: String) -> String {
    if description.hasPrefix(messagePrefix) {
      return String(description.dropFirst(messagePrefix.count))
    }
    return description
  }
}
