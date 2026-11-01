import QtQuick
import Quickshell
import Quickshell.Hyprland
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

  // Each status read starts Python and hyprctl (about 0.3 s of CPU), so the
  // service reads on events, not on a fast clock. Keyboard attach and detach
  // reach Hyprland as monitor events, because the layout script turns eDP-2
  // off and on. The timer is a fallback for changes without an event, such as
  // a rotate started by another tool.
  readonly property int fallbackIntervalMs: 10000

  function isStatusEvent(name) {
    var n = String(name || "")
    return n.indexOf("monitoradded") === 0 || n.indexOf("monitorremoved") === 0 || n === "configreloaded"
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event && root.isStatusEvent(event.name)) root.refresh()
    }
  }

  Timer {
    interval: root.fallbackIntervalMs
    running: true
    repeat: true
    onTriggered: root.refresh()
  }
}
