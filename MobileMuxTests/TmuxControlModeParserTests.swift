import Testing
@testable import MobileMux

@Suite("tmux Control Mode Parser")
struct TmuxControlModeParserTests {
    let parser = TmuxControlModeParser()

    @Test("Parses %output events")
    func parseOutput() {
        let event = parser.parse(line: "%output %3 Hello, world!")
        guard case .output(let paneId, let data) = event else {
            Issue.record("Expected .output event")
            return
        }
        #expect(paneId == "%3")
        #expect(data == "Hello, world!")
    }

    @Test("Parses %session-changed events")
    func parseSessionChanged() {
        let event = parser.parse(line: "%session-changed $1 gastown")
        guard case .sessionChanged(let sessionId, let name) = event else {
            Issue.record("Expected .sessionChanged event")
            return
        }
        #expect(sessionId == "$1")
        #expect(name == "gastown")
    }

    @Test("Parses %window-add events")
    func parseWindowAdd() {
        let event = parser.parse(line: "%window-add @2")
        guard case .windowAdd(let windowId) = event else {
            Issue.record("Expected .windowAdd event")
            return
        }
        #expect(windowId == "@2")
    }

    @Test("Parses %window-renamed events")
    func parseWindowRenamed() {
        let event = parser.parse(line: "%window-renamed @0 mayor")
        guard case .windowRenamed(let windowId, let name) = event else {
            Issue.record("Expected .windowRenamed event")
            return
        }
        #expect(windowId == "@0")
        #expect(name == "mayor")
    }

    @Test("Parses %layout-change events")
    func parseLayoutChange() {
        let event = parser.parse(line: "%layout-change @0 a]80x24,0,0,0")
        guard case .layoutChange(let windowId, let layout) = event else {
            Issue.record("Expected .layoutChange event")
            return
        }
        #expect(windowId == "@0")
        #expect(layout == "a]80x24,0,0,0")
    }

    @Test("Parses %exit events")
    func parseExit() {
        let event = parser.parse(line: "%exit client detached")
        guard case .exit(let reason) = event else {
            Issue.record("Expected .exit event")
            return
        }
        #expect(reason == "client detached")
    }

    @Test("Handles unknown lines")
    func parseUnknown() {
        let event = parser.parse(line: "some random output")
        guard case .unknown = event else {
            Issue.record("Expected .unknown event")
            return
        }
    }
}
