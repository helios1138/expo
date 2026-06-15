// Copyright 2025-present 650 Industries. All rights reserved.

import Foundation

/// A JavaScript crash captured at the React Native layer.
///
/// Deliberately a separate type from `CrashReport` (the MetricKit/native shape): the two have almost
/// nothing in common. A native crash is a Mach exception + signal + native call-stack tree over a
/// payload *window*; a JS crash is a message, name, and parsed JS stack (file / line / column) at a
/// single *point in time*. Forcing them into one struct would leave half the fields perpetually nil.
public struct JsCrashReport: Codable, Sendable {
  /// Error constructor name (e.g. "TypeError"), when the JS error carried one.
  public let name: String?

  /// Error message.
  public let message: String

  /// Parsed JavaScript stack, innermost frame first. Mirrors React Native's `RCTJSStackTraceKey`.
  public let stack: [StackFrame]

  /// Whether the error terminated the process (a fatal JS exception routed through `RCTFatal`) or
  /// was recovered (e.g. caught by an error boundary, or reported as a soft exception).
  public let isFatal: Bool

  /// App version at the time of the crash.
  public let appVersion: String

  /// When the crash occurred. Unlike MetricKit there's no payload window: a JS error happens at one
  /// instant, captured synchronously as it propagates.
  public let timestamp: Date

  public init(
    name: String?,
    message: String,
    stack: [StackFrame],
    isFatal: Bool,
    appVersion: String,
    timestamp: Date
  ) {
    self.name = name
    self.message = message
    self.stack = stack
    self.isFatal = isFatal
    self.appVersion = appVersion
    self.timestamp = timestamp
  }

  /// One frame of a JavaScript stack, mirroring React Native's `RCTJSStackTraceKey` entries.
  public struct StackFrame: Codable, Sendable {
    public let file: String?
    public let methodName: String
    public let lineNumber: Int?
    public let column: Int?

    public init(file: String?, methodName: String, lineNumber: Int?, column: Int?) {
      self.file = file
      self.methodName = methodName
      self.lineNumber = lineNumber
      self.column = column
    }
  }
}

// MARK: - React Native parsing

extension JsCrashReport {
  /// Builds a report from the raw error data React Native hands us (via `RCTJSStackTraceKey` and the
  /// fatal `NSError`). `rawStack` is the untyped `[[String: Any]]` RN produces; frames without a
  /// `methodName` carry nothing useful and are dropped. Numeric fields arrive boxed as `NSNumber`.
  init(
    message: String,
    name: String?,
    rawStack: [[String: Any]]?,
    isFatal: Bool,
    appVersion: String,
    timestamp: Date
  ) {
    let frames = (rawStack ?? []).compactMap { StackFrame(rawFrame: $0) }
    self.init(
      name: name,
      message: message,
      stack: frames,
      isFatal: isFatal,
      appVersion: appVersion,
      timestamp: timestamp
    )
  }
}

extension JsCrashReport.StackFrame {
  /// Parses one React Native stack-frame dictionary. Returns `nil` when there's no `methodName`;
  /// such a frame has no actionable content, so it's dropped rather than kept with a placeholder.
  init?(rawFrame: [String: Any]) {
    guard let methodName = rawFrame["methodName"] as? String else {
      return nil
    }
    self.init(
      file: rawFrame["file"] as? String,
      methodName: methodName,
      lineNumber: (rawFrame["lineNumber"] as? NSNumber)?.intValue,
      column: (rawFrame["column"] as? NSNumber)?.intValue
    )
  }
}

// MARK: - CustomStringConvertible

extension JsCrashReport: CustomStringConvertible {
  public var description: String {
    var lines = ["[JsCrashReport] \(isFatal ? "fatal" : "non-fatal") \(name ?? "Error"): \(message)"]
    lines.append("  App version: \(appVersion)")
    for frame in stack {
      let location = [frame.lineNumber, frame.column]
        .compactMap { $0 }
        .map(String.init)
        .joined(separator: ":")
      let suffix = location.isEmpty ? "" : " (\(frame.file ?? "?"):\(location))"
      lines.append("    at \(frame.methodName)\(suffix)")
    }
    return lines.joined(separator: "\n")
  }
}
