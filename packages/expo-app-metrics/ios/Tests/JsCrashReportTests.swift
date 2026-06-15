import Foundation
import Testing

@testable import ExpoAppMetrics

@Suite("JsCrashReport")
struct JsCrashReportTests {
  @Test
  func `builds a crash report from a parsed JS error`() {
    let report = JsCrashReport(
      name: "TypeError",
      message: "undefined is not a function",
      stack: [
        JsCrashReport.StackFrame(file: "index.bundle", methodName: "onPress", lineNumber: 42, column: 7),
        JsCrashReport.StackFrame(file: nil, methodName: "<anonymous>", lineNumber: nil, column: nil),
      ],
      isFatal: true,
      appVersion: "1.0.0",
      timestamp: Date.now
    )

    #expect(report.name == "TypeError")
    #expect(report.message == "undefined is not a function")
    #expect(report.isFatal == true)
    #expect(report.stack.count == 2)
    #expect(report.stack.first?.methodName == "onPress")
    #expect(report.stack.first?.lineNumber == 42)
    #expect(report.stack.last?.lineNumber == nil)
  }

  @Test
  func `round-trips through JSON`() {
    let report = JsCrashReport(
      name: "Error",
      message: "boom",
      stack: [JsCrashReport.StackFrame(file: "app.js", methodName: "f", lineNumber: 1, column: 2)],
      isFatal: true,
      appVersion: "2.3.4",
      timestamp: Date(timeIntervalSince1970: 1_700_000_000)
    )

    let json = try #require(encodeAsJSONString(report))
    let decoded = try #require(decodeFromJSONString(JsCrashReport.self, from: json))

    #expect(decoded.name == "Error")
    #expect(decoded.message == "boom")
    #expect(decoded.appVersion == "2.3.4")
    #expect(decoded.isFatal == true)
    #expect(decoded.stack.first?.column == 2)
    #expect(decoded.timestamp == Date(timeIntervalSince1970: 1_700_000_000))
  }

  @Test
  func `preserves a missing error name`() {
    let report = JsCrashReport(
      name: nil,
      message: "anonymous failure",
      stack: [],
      isFatal: false,
      appVersion: "1.0.0",
      timestamp: Date.now
    )

    let json = try #require(encodeAsJSONString(report))
    let decoded = try #require(decodeFromJSONString(JsCrashReport.self, from: json))

    #expect(decoded.name == nil)
    #expect(decoded.isFatal == false)
    #expect(decoded.stack.isEmpty)
  }
}
