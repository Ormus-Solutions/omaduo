pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "omaduo"

  property var anchorItem: null
  property var hostWidget: null
  property var duo: null
  readonly property var barIdentity: hostWidget || root
  readonly property var svc: duo || (bar && bar.shell ? bar.shell.serviceFor(moduleName) : null)
  readonly property var panelScreen: anchorItem && anchorItem.QsWindow.window
    ? anchorItem.QsWindow.window.screen : null
  readonly property var mainScreen: {
    var best = null
    var screens = Quickshell.screens
    for (var i = 0; i < screens.length; i++) {
      if (!best || screens[i].width * screens[i].height > best.width * best.height)
        best = screens[i]
    }
    return best
  }
  ipcTarget: panelScreen && panelScreen === mainScreen ? moduleName : ""

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.45)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property bool ready: !!svc && svc.initialized === true
  readonly property bool hardware: ready && svc.hardware === true
  property int tabIndex: 0

  onOpenedChanged: {
    if (opened && svc) svc.refresh()
  }

  function portraitLabel() {
    if (!ready || !svc.portrait) return "Landscape"
    if (svc.portraitTransform === 3) return "Portrait (right-up)"
    return "Portrait (left-up)"
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    padding: Style.space(14)
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(640))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onMoveRequested: function(dx, dy) {
        if (dx !== 0) {
          var next = root.tabIndex + (dx > 0 ? 1 : -1)
          if (next < 0) next = 2
          if (next > 2) next = 0
          root.tabIndex = next
        }
      }
      onTextKey: function(t) {
        if (t === "r" || t === "R") { if (root.svc) root.svc.refresh() }
        else if (t === "1") root.tabIndex = 0
        else if (t === "2") root.tabIndex = 1
        else if (t === "3") root.tabIndex = 2
      }
    }

    Flickable {
      id: flick
      anchors.fill: parent
      contentWidth: width
      contentHeight: column.implicitHeight
      clip: false
      boundsBehavior: Flickable.StopAtBounds
      interactive: contentHeight > height
      flickableDirection: Flickable.VerticalFlick

      Column {
        id: column
        width: flick.width
        spacing: Style.space(12)

        PanelHero {
          width: parent.width
          title: "Omaduo"
          meta: !root.hardware
            ? "Not a Zenbook Duo"
            : (root.svc.keyboardOn ? "Keyboard docked" : "Keyboard lifted")
          detail: root.hardware ? root.portraitLabel() : String(root.svc && root.svc.dmi ? root.svc.dmi : "")
          foreground: root.foreground
          fontFamily: root.fontFamily
          iconOpacity: root.hardware ? 1 : 0.45
          iconComponent: Component {
            Text {
              textFormat: Text.PlainText
              text: "󰌢"
              color: root.foreground
              font.pixelSize: Style.font.display
            }
          }
        }

        Row {
          width: parent.width
          spacing: Style.space(6)

          Button {
            width: (parent.width - parent.spacing * 2) / 3
            text: "Layout"
            selected: root.tabIndex === 0
            bordered: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: root.tabIndex = 0
          }
          Button {
            width: (parent.width - parent.spacing * 2) / 3
            text: "Input"
            selected: root.tabIndex === 1
            bordered: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: root.tabIndex = 1
          }
          Button {
            width: (parent.width - parent.spacing * 2) / 3
            text: "Keys"
            selected: root.tabIndex === 2
            bordered: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: root.tabIndex = 2
          }
        }

        StackLayout {
          id: pages
          width: parent.width
          currentIndex: root.tabIndex
          height: currentIndex === 0 ? layoutPage.implicitHeight : (currentIndex === 1 ? inputPage.implicitHeight : keysPage.implicitHeight)

          Column {
            id: layoutPage
            width: pages.width
            spacing: Style.space(12)

            Toggle {
              width: parent.width
              opacity: root.hardware ? 1 : 0.45
              label: "Portrait screens"
              description: "Side-by-side. Super+R. Right-click the bar icon also toggles."
              checked: root.ready && root.svc.portrait
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: if (root.hardware && root.svc) root.svc.run("rotate", "toggle")
            }

            Button {
              width: parent.width
              visible: root.ready && root.svc.portrait
              text: "Flip 90 / 270"
              bordered: true
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: if (root.svc) root.svc.run("rotate", "flip")
            }

            Toggle {
              width: parent.width
              opacity: root.hardware && root.ready && !root.svc.keyboardOn ? 1 : 0.45
              label: "ScreenPad"
              description: root.ready && root.svc.keyboardOn
                ? "Keyboard is on the magnet. ScreenPad stays off."
                : "Bottom OLED. Lift the keyboard to use it. This toggle re-applies layout."
              checked: root.ready && root.svc.screenpadOn
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: if (root.hardware && root.svc && !root.svc.keyboardOn) root.svc.run("layout", "apply")
            }
          }

          Column {
            id: inputPage
            width: pages.width
            spacing: Style.space(12)

            Toggle {
              width: parent.width
              opacity: root.hardware ? 1 : 0.45
              label: "Palm-rest trackpad"
              description: "Keyboard pad plus its mouse node. Super+Alt+T. Stock Omarchy toggle hits the lid digitizer."
              checked: root.ready && root.svc.trackpadOn
              foreground: root.foreground
              fontFamily: root.fontFamily
              onClicked: if (root.hardware && root.svc) root.svc.run("touchpad", "toggle")
            }
          }

          Column {
            id: keysPage
            width: pages.width
            spacing: Style.space(8)

            Text {
              width: parent.width
              textFormat: Text.PlainText
              wrapMode: Text.WordWrap
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              text: root.ready && root.svc.activated
                ? "Hyprland binds are written (omaduo activate)."
                : "These chords already live in ~/.config/hypr/bindings.lua on this machine. omaduo activate writes a marked copy. Not run from this panel."
            }

            Repeater {
              model: [
                "Super+R · portrait",
                "Super+Shift+Alt+R · flip 90/270",
                "Super+Alt+T · palm-rest trackpad",
                "F4 · keyboard backlight",
                "F5 / F6 · lid brightness (mirrors to ScreenPad)"
              ]
              Text {
                required property string modelData
                width: keysPage.width
                textFormat: Text.PlainText
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                text: modelData
              }
            }
          }
        }
      }
    }
  }
}
