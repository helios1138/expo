import Foundation
import Testing

@testable import ExpoAppMetrics

@Suite("JsCrashReport parsing")
struct JsCrashReportParsingTests {
  @Test
  func `parses React Native stack-frame dictionaries`() {
    // Shape that React Native delivers in `RCTJSStackTraceKey`: an array of dictionaries with
    // `methodName`, optional `file`, `lineNumber`, `column`.
    let rawStack: [[String: Any]] = [
      ["methodName": "onPress", "file": "index.bundle", "lineNumber": 42, "column": 7],
      ["methodName": "<anonymous>"],
    ]
    let report = JsCrashReport(
      message: "undefined is not a function",
      name: "TypeError",
      rawStack: rawStack,
      isFatal: true,
      appVersion: "1.0.0",
      timestamp: Date.now
    )

    #expect(report.message == "undefined is not a function")
    #expect(report.name == "TypeError")
    #expect(report.isFatal == true)
    #expect(report.stack.count == 2)

    let first = report.stack.first
    #expect(first?.methodName == "onPress")
    #expect(first?.file == "index.bundle")
    #expect(first?.lineNumber == 42)
    #expect(first?.column == 7)

    let second = report.stack.last
    #expect(second?.methodName == "<anonymous>")
    #expect(second?.file == nil)
    #expect(second?.lineNumber == nil)
    #expect(second?.column == nil)
  }

  @Test
  func `tolerates a nil stack`() {
    let report = JsCrashReport(
      message: "boom",
      name: nil,
      rawStack: nil,
      isFatal: false,
      appVersion: "1.0.0",
      timestamp: Date.now
    )
    #expect(report.stack.isEmpty)
    #expect(report.name == nil)
  }

  @Test
  func `skips malformed frames that lack a method name`() {
    // A frame with no `methodName` carries no useful information; drop it rather than inventing one.
    let rawStack: [[String: Any]] = [
      ["file": "a.js", "lineNumber": 1],
      ["methodName": "good", "file": "b.js", "lineNumber": 2, "column": 3],
    ]
    let report = JsCrashReport(
      message: "boom",
      name: "Error",
      rawStack: rawStack,
      isFatal: true,
      appVersion: "1.0.0",
      timestamp: Date.now
    )
    #expect(report.stack.count == 1)
    #expect(report.stack.first?.methodName == "good")
  }
}
