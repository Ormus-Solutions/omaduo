import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool initialized: false
  property bool hardware: false
  property bool keyboardOn: false
  property bool portrait: false
  property int portraitTransform: 0
  property bool trackpadOn: true
  property bool screenpadOn: false
  property bool activated: false
  property string dmi: ""
  property string lastError: ""
  property bool pending: actionProc.running

  readonly property string bin: {
    var url = Qt.resolvedUrl("bin/omaduo")
    var s = String(url)
    if (s.indexOf("file://") === 0) s = decodeURIComponent(s.substring(7))
    if (s.indexOf("localhost/") === 0) s = s.substring(9)
    return s
  }

  function applyStatus(raw) {
    var text = String(raw || "").trim()
    if (text === "") {
      lastError = "Empty omaduo status"
      initialized = true
      return
    }
    var parsed
    try { parsed = JSON.parse(text) }
    catch (e) {
      lastError = "Could not parse omaduo status"
      initialized = true
      return
    }
    hardware = parsed.hardware === true
    keyboardOn = parsed.keyboardOn === true
    portrait = parsed.portrait === true
    portraitTransform = parseInt(parsed.portraitTransform, 10) || 0
    trackpadOn = parsed.trackpadOn !== false
    screenpadOn = parsed.screenpadOn === true
    activated = parsed.activated === true
    dmi = String(parsed.dmi || "")
    lastError = parsed.ok === false ? String(parsed.error || "omaduo failed") : ""
    initialized = true
  }

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  function run(cmd, arg) {
    if (actionProc.running || !cmd) return
    var args = [root.bin, String(cmd)]
    if (arg !== undefined && arg !== null && String(arg) !== "") args.push(String(arg))
    actionProc.command = args
    actionProc.running = true
  }

  Component.onCompleted: root.refresh()

  Process {
    id: statusProc
    command: [root.bin, "status"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyStatus(text)
    }
  }

  Process {
    id: actionProc
    running: false
    onExited: root.refresh()
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }
}
