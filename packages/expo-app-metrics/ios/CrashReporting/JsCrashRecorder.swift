// Copyright 2025-present 650 Industries. All rights reserved.

import Foundation

/// Entry point for JavaScript crashes captured at the React Native layer.
///
/// For now this only logs the report. Storage is deliberately deferred until we settle on how a JS
/// crash should be persisted and surfaced on a session. The fatal-handler install and any soft-error
/// path funnel through here, so when persistence lands there's a single place to add it.
enum JsCrashRecorder {
  /// Builds a `JsCrashReport` from React Native's error data and records it.
  ///
  /// - Parameters:
  ///   - message: the error message (RN's localized description, minus its prefix).
  ///   - name: the JS error constructor name, when known.
  ///   - rawStack: the untyped `RCTJSStackTraceKey` frames, as RN delivers them.
  ///   - isFatal: whether the error terminated the process.
  static func record(message: String, name: String?, rawStack: [[String: Any]]?, isFatal: Bool) {
    let report = JsCrashReport(
      message: message,
      name: name,
      rawStack: rawStack,
      isFatal: isFatal,
      appVersion: AppInfo.current.appVersion ?? "unknown",
      timestamp: Date.now
    )
    record(report)
  }

  /// Records an already-built report. Logging only, for now.
  static func record(_ report: JsCrashReport) {
    logger.warn("[AppMetrics] Captured JavaScript crash:\n\(report)")
  }
}
