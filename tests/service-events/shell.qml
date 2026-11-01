// Checks how Service.qml decides when to read the Duo status.
// Run from the repo root: tests/service-events/run.sh
// Prints one PASS or FAIL line and exits 0 on pass, 1 on fail.
import QtQuick
import Quickshell

ShellRoot {
  Service { id: svc }

  Component.onCompleted: {
    var cases = [
      ["monitoradded", true],
      ["monitoraddedv2", true],
      ["monitorremoved", true],
      ["monitorremovedv2", true],
      ["configreloaded", true],
      ["activewindow", false],
      ["workspacev2", false],
      ["", false]
    ]
    var failures = []
    try {
      for (var i = 0; i < cases.length; i++) {
        if (svc.isStatusEvent(cases[i][0]) !== cases[i][1]) failures.push(cases[i][0] || "(empty)")
      }
      if (!(svc.fallbackIntervalMs >= 10000)) failures.push("fallbackIntervalMs=" + svc.fallbackIntervalMs)
    } catch (e) {
      failures.push(String(e))
    }
    if (failures.length === 0) {
      console.log("PASS service-events: " + cases.length + " event names, fallback " + svc.fallbackIntervalMs + " ms")
      Qt.exit(0)
    } else {
      console.log("FAIL service-events: " + failures.join(", "))
      Qt.exit(1)
    }
  }
}
