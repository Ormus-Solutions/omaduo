import QtQuick
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omaduo"

  readonly property var duo: bar && bar.shell ? bar.shell.serviceFor(moduleName) : null
  readonly property bool ready: !!duo && duo.initialized === true
  readonly property bool hardware: ready && duo.hardware === true
  readonly property bool portrait: ready && duo.portrait === true
  readonly property bool keyboardOn: ready && duo.keyboardOn === true

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
    if ("duo" in target) target.duo = root.duo
  }

  function open() { if (panelLoader.item) panelLoader.item.open() }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function toggle() { if (panelLoader.item) panelLoader.item.toggle() }

  onBarChanged: Qt.callLater(injectPanel)
  onSettingsChanged: Qt.callLater(injectPanel)
  onDuoChanged: Qt.callLater(injectPanel)
  Component.onCompleted: Qt.callLater(injectPanel)

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: root.injectPanel()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.portrait ? "󰑴" : "󰌢"
    active: root.hardware && !root.keyboardOn
    dimmed: !root.hardware || root.keyboardOn
    tooltipText: !root.hardware
      ? "Omaduo — not a Zenbook Duo"
      : (root.keyboardOn
        ? "Omaduo — keyboard docked, ScreenPad off"
        : (root.portrait
          ? "Omaduo — portrait. Click for panel, right-click landscape"
          : "Omaduo — ScreenPad live. Click for panel, right-click portrait"))
    onPressed: function(b) {
      if (b === Qt.RightButton && root.duo) root.duo.run("rotate", "toggle")
      else if (b === Qt.MiddleButton && root.duo) root.duo.run("touchpad", "toggle")
      else root.toggle()
    }
  }
}
