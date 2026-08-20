import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.Commons
import qs.Ui
import "DrawerLogic.js" as Logic

BarWidget {
  id: root
  moduleName: "akshad.omadrawer"

  // ------------------------------------------------------------- State & Settings
  property var groupsList: []
  property bool popupOpen: false

  function open() { popupOpen = true }
  function close() { popupOpen = false }
  function toggle() { popupOpen = !popupOpen }

  // ------------------------------------------------------------- Appearance
  readonly property color colForeground: Color.foreground
  readonly property color colAccent: Color.accent
  readonly property color colDim: Qt.darker(Color.foreground, 1.45)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/omarchy/plugins/akshad.omadrawer"
  readonly property string groupsFilePath: stateDir + "/groups.json"

  // ------------------------------------------------------------- Persistence
  Process {
    id: ensureDirProc
    command: ["mkdir", "-p", root.stateDir]
    onExited: function(code) {
      groupsFile.reload()
    }
  }

  FileView {
    id: groupsFile
    path: root.groupsFilePath
    watchChanges: true
    printErrors: false
    onLoaded: root.loadGroups(text())
  }

  function loadGroups(raw) {
    var parsed = Logic.parseGroups(raw)
    root.groupsList = parsed
    if (!raw || raw.trim().length === 0) {
      root.saveAllGroups(parsed)
    }
  }

  function saveAllGroups(list) {
    root.groupsList = list
    var serialized = Logic.serializeGroups(list)
    groupsFile.setText(serialized)
  }

  function saveGroup(groupData) {
    var current = root.groupsList ? root.groupsList.slice() : []
    var foundIndex = -1
    for (var i = 0; i < current.length; i++) {
      if (current[i].id === groupData.id) {
        foundIndex = i
        break
      }
    }
    if (foundIndex !== -1) {
      current[foundIndex] = groupData
    } else {
      current.push(groupData)
    }
    root.saveAllGroups(current)
  }

  function deleteGroup(groupId) {
    var current = root.groupsList ? root.groupsList.slice() : []
    var next = []
    for (var i = 0; i < current.length; i++) {
      if (current[i].id !== groupId) {
        next.push(current[i])
      }
    }
    root.saveAllGroups(next)
  }

  function refreshPlugins() {
    groupsFile.reload()
  }

  // ------------------------------------------------------------- Top Bar UI Icon
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  visible: button.visible

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰏖"
    active: root.popupOpen
    useActiveColor: true
    activeColor: colAccent
    tooltipText: "OmaDrawer (" + (root.groupsList ? root.groupsList.length : 0) + " groups)"

    onPressed: function(b) {
      root.toggle()
    }
  }

  // ------------------------------------------------------------- Popup Drawer Manager
  KeyboardPanel {
    id: popup
    anchorItem: button
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: Style.space(420)
    contentHeight: Style.space(510)

    onOpenChanged: {
      if (root.popupOpen !== popup.open) {
        root.popupOpen = popup.open
      }
    }

    DrawerManagerView {
      id: managerView
      host: root
      anchors.fill: parent
    }
  }

  // ------------------------------------------------------------- IPC Handler
  IpcHandler {
    target: "akshad.omadrawer"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function reload(): void { root.refreshPlugins() }
  }

  Component.onCompleted: {
    ensureDirProc.running = true
  }
}
