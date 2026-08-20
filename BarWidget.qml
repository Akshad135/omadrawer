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
  property var pluginOrigins: ({})
  property var expandedGroups: ({})
  property string displayMode: "icon" // "icon" | "name" | "both"
  property string slideDirection: "right" // fallback
  property bool popupOpen: false

  readonly property string currentRegion: {
    var p = root.parent
    while (p) {
      if (p.region !== undefined && typeof p.region === "string" && p.region.length > 0) {
        return p.region
      }
      p = p.parent
    }
    return "right"
  }

  readonly property var visibleGroups: {
    var list = []
    if (!root.groupsList) return list
    for (var i = 0; i < root.groupsList.length; i++) {
      var g = root.groupsList[i]
      var pos = g && g.position ? g.position : "right"
      if (pos === root.currentRegion) {
        list.push(g)
      }
    }
    return list
  }

  readonly property bool isPrimaryInstance: root.currentRegion === "right"

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
    if (key === "displayMode") {
      root.displayMode = val
    } else if (key === "slideDirection") {
      root.slideDirection = val
    }
    var serialized = Logic.serializeData(root.groupsList, { 
      displayMode: root.displayMode, 
      slideDirection: root.slideDirection 
    }, root.pluginOrigins)
    groupsFile.setText(serialized)
  }

  // ------------------------------------------------------------- Appearance
  readonly property color colForeground: Color.foreground
  readonly property color colAccent: Color.accent
  readonly property color colDim: Qt.darker(Color.foreground, 1.45)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/omarchy/plugins/akshad.omadrawer"
  readonly property string groupsFilePath: stateDir + "/groups.json"

  // ------------------------------------------------------------- Persistence & Layout
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

  readonly property var barLayout: {
    if (bar && bar.barConfig && bar.barConfig.layout) {
      return bar.barConfig.layout
    }
    if (bar && bar.layoutConfig) {
      return bar.layoutConfig
    }
    if (bar && bar.shell && bar.shell.shellConfig && bar.shell.shellConfig.bar && bar.shell.shellConfig.bar.layout) {
      return bar.shell.shellConfig.bar.layout
    }
    return null
  }

  function reconcileBarLayout() {
    var res = Logic.reconcileGroupsWithLayout(root.groupsList, root.barLayout)
    if (res && res.changed) {
      root.groupsList = res.groups
      var serialized = Logic.serializeData(res.groups, {
        displayMode: root.displayMode,
        slideDirection: root.slideDirection
      }, root.pluginOrigins)
      groupsFile.setText(serialized)
    }
  }

  onBarLayoutChanged: Qt.callLater(root.reconcileBarLayout)
  onBarChanged: Qt.callLater(root.reconcileBarLayout)

  function syncShellLayout(groups) {
    if (!bar || !bar.shell || typeof bar.shell.mutateShellConfig !== "function") return

    // 1. Build map of all plugin IDs that are currently in at least one drawer group
    var groupedMap = {}
    var requiredSections = { "right": true } // "right" is the default manager home

    for (var i = 0; i < groups.length; i++) {
      var g = groups[i]
      if (g) {
        var gPos = g.position || "right"
        requiredSections[gPos] = true
        if (g.plugins && Array.isArray(g.plugins)) {
          for (var j = 0; j < g.plugins.length; j++) {
            var pid = String(g.plugins[j]).trim()
            if (pid) groupedMap[pid] = true
          }
        }
      }
    }

    var originsCopy = {}
    for (var ok in root.pluginOrigins) {
      originsCopy[ok] = root.pluginOrigins[ok]
    }

    bar.shell.mutateShellConfig(function(config) {
      if (!config) return
      if (!Array.isArray(config.plugins)) config.plugins = []
      if (!config.bar || !config.bar.layout) return

      var disabledMap = {}
      if (Array.isArray(config.disabledPlugins)) {
        for (var d = 0; d < config.disabledPlugins.length; d++) {
          disabledMap[config.disabledPlugins[d]] = true
        }
      }

      // 2. Ensure all grouped plugins are present in config.plugins so BarWidgetRegistry keeps them active
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

      // 3. Scan all sections (left, center, right) to capture origins before removing grouped plugins
      var sections = ["left", "center", "right"]
      var placedOnBar = {}

      for (var s = 0; s < sections.length; s++) {
        var secName = sections[s]
        var list = config.bar.layout[secName]
        if (Array.isArray(list)) {
          for (var k = 0; k < list.length; k++) {
            var item = list[k]
            var itemId = typeof item === "string" ? item : (item && item.id ? item.id : "")
            if (itemId && itemId !== "akshad.omadrawer") {
              placedOnBar[itemId] = secName
              if (groupedMap[itemId]) {
                originsCopy[itemId] = secName
              }
            }
          }
        }
      }

      // 4. Remove all grouped plugins from bar.layout sections
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

      // 5. Ensure akshad.omadrawer is present in all sections that require it and deduplicate in each section
      for (var s3 = 0; s3 < sections.length; s3++) {
        var sec3 = sections[s3]
        if (!Array.isArray(config.bar.layout[sec3])) config.bar.layout[sec3] = []
        var seenDrawer = false
        config.bar.layout[sec3] = config.bar.layout[sec3].filter(function(e) {
          var eid = typeof e === "string" ? e : (e && e.id ? e.id : "")
          if (eid === "akshad.omadrawer") {
            if (!requiredSections[sec3]) return false
            if (seenDrawer) return false
            seenDrawer = true
            return true
          }
          return true
        })

        if (requiredSections[sec3] && !seenDrawer) {
          config.bar.layout[sec3].push({ id: "akshad.omadrawer" })
        }
      }

      // 6. Restore un-grouped plugins back to their ORIGINAL origin sections
      for (var cp = 0; cp < config.plugins.length; cp++) {
        var cEntry = config.plugins[cp]
        var cId = typeof cEntry === "string" ? cEntry : (cEntry && cEntry.id ? cEntry.id : "")
        if (!cId || cId === "akshad.omadrawer" || groupedMap[cId] || disabledMap[cId]) continue

        if (!placedOnBar[cId]) {
          var destSec = originsCopy[cId] || "right"
          if (!Array.isArray(config.bar.layout[destSec])) config.bar.layout[destSec] = []
          
          var newEntry = typeof cEntry === "object" ? JSON.parse(JSON.stringify(cEntry)) : { id: cId }
          config.bar.layout[destSec].push(newEntry)
          placedOnBar[cId] = destSec
          delete originsCopy[cId]
        }
      }
    })

    root.pluginOrigins = originsCopy
    var serialized = Logic.serializeData(groups, { 
      displayMode: root.displayMode, 
      slideDirection: root.slideDirection 
    }, originsCopy)
    groupsFile.setText(serialized)
  }

  function loadGroups(raw) {
    var data = Logic.parseData(raw)
    root.groupsList = data.groups
    root.pluginOrigins = data.pluginOrigins || {}
    if (data.settings) {
      if (data.settings.displayMode) root.displayMode = data.settings.displayMode
      if (data.settings.slideDirection) root.slideDirection = data.settings.slideDirection
    }
    if (!raw || raw.trim().length === 0) {
      root.saveAllGroups(data.groups)
    }
  }

  function saveAllGroups(list) {
    root.groupsList = list
    var serialized = Logic.serializeData(list, { 
      displayMode: root.displayMode, 
      slideDirection: root.slideDirection 
    }, root.pluginOrigins)
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

    // 1. OmaDrawer Manager Icon Button (Hosted on right / primary section)
    WidgetButton {
      id: managerButton
      visible: root.isPrimaryInstance
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

    // 2. Active Drawer Groups in this Specific Bar Section
    Repeater {
      model: root.visibleGroups

      DrawerGroupItem {
        required property var modelData
        groupData: modelData
        bar: root.bar
        displayMode: root.displayMode
        slideDirection: modelData.direction || "right"
        expanded: root.isGroupExpanded(modelData.id)
        onToggleExpanded: root.toggleGroupExpanded(modelData.id)
        onOpenManager: root.open()
      }
    }
  }

  // ------------------------------------------------------------- Popup Drawer Manager (Loaded only on primary instance)
  Loader {
    id: popupLoader
    active: root.isPrimaryInstance
    sourceComponent: Component {
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
    }
  }

  // ------------------------------------------------------------- IPC Handler (Loaded ONLY on primary instance to prevent duplicates)
  Loader {
    id: ipcLoader
    active: root.isPrimaryInstance
    sourceComponent: Component {
      IpcHandler {
        target: "akshad.omadrawer"

        function open(): void { root.open() }
        function close(): void { root.close() }
        function toggle(): void { root.toggle() }
        function toggleGroup(groupId: string): void { root.toggleGroupExpanded(groupId) }
        function reload(): void { root.refreshPlugins() }
      }
    }
  }

  Component.onCompleted: {
    ensureDirProc.running = true
  }
}
