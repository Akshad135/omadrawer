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
  property var expandedGroups: ({})
  property bool popupOpen: false

  function open() { popupOpen = true }
  function close() { popupOpen = false }
  function toggle() { popupOpen = !popupOpen }

  function isGroupExpanded(groupId) {
    return expandedGroups[groupId] === true
  }

  function toggleGroupExpanded(groupId) {
    var next = {}
    for (var k in expandedGroups) next[k] = expandedGroups[k]
    next[groupId] = !next[groupId]
    expandedGroups = next
  }

  function setGroupExpanded(groupId, val) {
    var next = {}
    for (var k in expandedGroups) next[k] = expandedGroups[k]
    next[groupId] = (val === true)
    expandedGroups = next
  }

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

  function syncShellLayout(groups) {
    if (!bar || !bar.shell || typeof bar.shell.mutateShellConfig !== "function") return
    var groupedMap = {}
    for (var i = 0; i < groups.length; i++) {
      var g = groups[i]
      if (g && g.plugins && Array.isArray(g.plugins)) {
        for (var j = 0; j < g.plugins.length; j++) {
          groupedMap[g.plugins[j]] = true
        }
      }
    }

    bar.shell.mutateShellConfig(function(config) {
      if (!config || !config.bar || !config.bar.layout) return
      var sections = ["left", "center", "right"]
      for (var s = 0; s < sections.length; s++) {
        var sec = sections[s]
        var list = config.bar.layout[sec]
        if (Array.isArray(list)) {
          var filtered = list.filter(function(entry) {
            var id = typeof entry === "string" ? entry : (entry && entry.id ? entry.id : "")
            if (id === "akshad.omadrawer") return true
            return !groupedMap[id]
          })
          if (filtered.length !== list.length) {
            config.bar.layout[sec] = filtered
          }
        }
      }
    })
  }

  function loadGroups(raw) {
    var parsed = Logic.parseGroups(raw)
    root.groupsList = parsed
    if (!raw || raw.trim().length === 0) {
      root.saveAllGroups(parsed)
    } else {
      Qt.callLater(function() { root.syncShellLayout(parsed) })
    }
  }

  function saveAllGroups(list) {
    root.groupsList = list
    var serialized = Logic.serializeGroups(list)
    groupsFile.setText(serialized)
    Qt.callLater(function() { root.syncShellLayout(list) })
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

  // ------------------------------------------------------------- Top Bar UI Layout
  implicitWidth: barRow.implicitWidth
  implicitHeight: barRow.implicitHeight
  width: implicitWidth
  height: implicitHeight

  Row {
    id: barRow
    spacing: 0
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

    // 1. OmaDrawer Manager Icon Button
    WidgetButton {
      id: managerButton
      bar: root.bar
      text: "󰏖"
      active: root.popupOpen
      useActiveColor: true
      activeColor: root.colAccent
      tooltipText: "OmaDrawer Manager (" + (root.groupsList ? root.groupsList.length : 0) + " groups)"

      onPressed: function(buttonCode) {
        root.toggle()
      }
    }

    // 2. Active Drawer Groups on Top Bar
    Repeater {
      model: root.groupsList

      DrawerGroupItem {
        required property var modelData
        groupData: modelData
        bar: root.bar
        expanded: root.isGroupExpanded(modelData.id)
        onToggleExpanded: root.toggleGroupExpanded(modelData.id)
        onOpenManager: root.open()
      }
    }
  }

  // ------------------------------------------------------------- Popup Drawer Manager
  KeyboardPanel {
    id: popup
    anchorItem: managerButton
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
    function toggleGroup(groupId: string): void { root.toggleGroupExpanded(groupId) }
    function reload(): void { root.refreshPlugins() }
  }

  Component.onCompleted: {
    ensureDirProc.running = true
  }
}
