import Testing

@testable import ExpoAppMetrics

@Suite("JsCrashHandler")
struct JsCrashHandlerTests {
  @Test
  func `strips React Native's fatal-exception prefix from the message`() {
    let stripped = JsCrashHandler.strippedMessage(from: "Unhandled JS Exception: undefined is not a function")
    #expect(stripped == "undefined is not a function")
  }

  @Test
  func `leaves a message without the prefix unchanged`() {
    #expect(JsCrashHandler.strippedMessage(from: "some other error") == "some other error")
  }
}
