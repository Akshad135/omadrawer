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
  property string slideDirection: "right" // "right" | "left"
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

  function updateSetting(key, val) {
    if (key === "slideDirection") {
      root.slideDirection = val
    }
    var serialized = Logic.serializeData(root.groupsList, { slideDirection: root.slideDirection })
    groupsFile.setText(serialized)
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

    // 1. Build map of all plugin IDs that are currently in at least one drawer group
    var groupedMap = {}
    for (var i = 0; i < groups.length; i++) {
      var g = groups[i]
      if (g && g.plugins && Array.isArray(g.plugins)) {
        for (var j = 0; j < g.plugins.length; j++) {
          var pid = String(g.plugins[j]).trim()
          if (pid) groupedMap[pid] = true
        }
      }
    }

    bar.shell.mutateShellConfig(function(config) {
      if (!config) return
      if (!Array.isArray(config.plugins)) config.plugins = []
      if (!config.bar || !config.bar.layout) return

      // Disabled plugins list
      var disabledMap = {}
      if (Array.isArray(config.disabledPlugins)) {
        for (var d = 0; d < config.disabledPlugins.length; d++) {
          disabledMap[config.disabledPlugins[d]] = true
        }
      }

      // 2. Ensure all grouped plugins are present in config.plugins
      var existingPluginIds = {}
      for (var p = 0; p < config.plugins.length; p++) {
        var pEntry = config.plugins[p]
        var pId = typeof pEntry === "string" ? pEntry : (pEntry && pEntry.id ? pEntry.id : "")
        if (pId) existingPluginIds[pId] = true
      }

      for (var gid in groupedMap) {
        if (!existingPluginIds[gid]) {
          config.plugins.push({ id: gid })
          existingPluginIds[gid] = true
        }
      }

      if (!existingPluginIds["akshad.omadrawer"]) {
        config.plugins.push({ id: "akshad.omadrawer" })
        existingPluginIds["akshad.omadrawer"] = true
      }

      // 3. Find which plugins are currently placed in any bar section (left, center, right)
      var sections = ["left", "center", "right"]
      var placedOnBar = {}
      for (var s = 0; s < sections.length; s++) {
        var sec = sections[s]
        var list = config.bar.layout[sec]
        if (Array.isArray(list)) {
          for (var k = 0; k < list.length; k++) {
            var item = list[k]
            var itemId = typeof item === "string" ? item : (item && item.id ? item.id : "")
            if (itemId) placedOnBar[itemId] = true
          }
        }
      }

      // 4. Remove all grouped plugins from bar.layout so they only live inside their drawer
      for (var s2 = 0; s2 < sections.length; s2++) {
        var sec2 = sections[s2]
        var list2 = config.bar.layout[sec2]
        if (Array.isArray(list2)) {
          config.bar.layout[sec2] = list2.filter(function(entry) {
            var entryId = typeof entry === "string" ? entry : (entry && entry.id ? entry.id : "")
            if (entryId === "akshad.omadrawer") return true
            if (groupedMap[entryId]) {
              delete placedOnBar[entryId]
              return false
            }
            return true
          })
        }
      }

      // 5. Restore un-grouped plugins back to bar.layout.right
      if (!Array.isArray(config.bar.layout.right)) config.bar.layout.right = []

      // Locate insertion index near akshad.omadrawer
      var drawerIndex = -1
      for (var r = 0; r < config.bar.layout.right.length; r++) {
        var rEntry = config.bar.layout.right[r]
        var rId = typeof rEntry === "string" ? rEntry : (rEntry && rEntry.id ? rEntry.id : "")
        if (rId === "akshad.omadrawer") {
          drawerIndex = r
          break
        }
      }

      var insertPos = drawerIndex !== -1 ? drawerIndex + 1 : config.bar.layout.right.length

      // Check all plugins in config.plugins
      for (var cp = 0; cp < config.plugins.length; cp++) {
        var cEntry = config.plugins[cp]
        var cId = typeof cEntry === "string" ? cEntry : (cEntry && cEntry.id ? cEntry.id : "")
        if (!cId || cId === "akshad.omadrawer" || groupedMap[cId] || disabledMap[cId]) continue

        if (!placedOnBar[cId]) {
          var newEntry = typeof cEntry === "object" ? JSON.parse(JSON.stringify(cEntry)) : { id: cId }
          config.bar.layout.right.splice(insertPos, 0, newEntry)
          placedOnBar[cId] = true
          insertPos++
        }
      }
    })
  }

  function loadGroups(raw) {
    var data = Logic.parseData(raw)
    root.groupsList = data.groups
    if (data.settings && data.settings.slideDirection) {
      root.slideDirection = data.settings.slideDirection
    }
    if (!raw || raw.trim().length === 0) {
      root.saveAllGroups(data.groups)
    } else {
      Qt.callLater(function() { root.syncShellLayout(data.groups) })
    }
  }

  function saveAllGroups(list) {
    root.groupsList = list
    var serialized = Logic.serializeData(list, { slideDirection: root.slideDirection })
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
        slideDirection: root.slideDirection
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
