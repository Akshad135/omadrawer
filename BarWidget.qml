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
  // False until groups.json has been read. Guards the layout heal: running
  // syncShellLayout with an empty list would wipe group entries and restore
  // every grouped plugin onto the bar, and the resulting reload would race
  // the file load again — an infinite wipe/restore flicker loop.
  property bool groupsLoaded: false

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

  // Every drawer group lives in its own bar layout entry `{ id, groupId }`,
  // so each group is an independent bar slot in every section. This instance
  // renders exactly the group named by its entry's groupId (empty for the
  // plain manager entry, which never renders groups).
  readonly property string hostGroupId: (settings && settings.groupId) ? String(settings.groupId) : ""

  // The plugin's own id. `moduleName` is overwritten by the bar with the
  // entry id — unique per group entry — so instance lookups must use this
  // constant instead.
  readonly property string pluginId: "akshad.omadrawer"

  // Absolute path of this plugin's widget, baked into group entries so the
  // bar loads them as custom-QML modules under their unique per-group ids.
  // The bar's drag system addresses entries by id; shared ids would make it
  // move the first matching entry (the invisible host) instead of the group.
  readonly property string widgetSource: {
    var cfg = (bar && bar.omarchyConfigDir) ? String(bar.omarchyConfigDir) : ""
    if (!cfg) {
      var home = Quickshell.env("HOME") || ""
      cfg = home ? home + "/.config/omarchy" : ""
    }
    return cfg ? cfg + "/plugins/akshad.omadrawer/BarWidget.qml" : ""
  }

  readonly property var visibleGroups: {
    var list = []
    if (!root.groupsList) return list
    if (root.hostGroupId === "") return list
    for (var i = 0; i < root.groupsList.length; i++) {
      var g = root.groupsList[i]
      if (g && g.id === root.hostGroupId) {
        list.push(g)
      }
    }
    return list
  }

  readonly property bool isDuplicateSlot: {
    if (!bar || typeof bar.moduleWidgets !== "function") return false
    var widgets = bar.moduleWidgets(root.pluginId)
    if (!Array.isArray(widgets) || widgets.length <= 1) return false
    for (var i = 0; i < widgets.length; i++) {
      if (widgets[i] && widgets[i].hostGroupId === root.hostGroupId) {
        return widgets[i] !== root
      }
    }
    return false
  }

  readonly property bool plainEntryInRight: {
    var layout = root.barLayout
    if (!layout || !Array.isArray(layout.right)) return false
    for (var i = 0; i < layout.right.length; i++) {
      var e = layout.right[i]
      if (typeof e === "object" && e && e.id === "akshad.omadrawer" && !e.groupId) return true
    }
    return false
  }

  readonly property bool isPrimaryInstance: {
    if (root.isDuplicateSlot) return false
    if (root.hostGroupId === "") return root.currentRegion === "right"
    // Fallback: a right-section group host acts as manager (icon, popup, IPC)
    // until the layout sync restores the plain manager entry, so the manager
    // is never lost mid-upgrade.
    return root.currentRegion === "right" && !root.plainEntryInRight
  }

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
      bootstrapProc.running = true
    }
  }

  // FileView.onLoaded never fires for a missing file (quickshell only reports
  // successful loads), so a fresh install would stay empty forever. Probe for
  // the state file after the directory exists and seed the first-run welcome
  // group when it is absent.
  Process {
    id: bootstrapProc
    command: ["test", "-f", root.groupsFilePath]
    onExited: function(code) {
      if (code !== 0) root.loadGroups("")
      groupsFile.reload()
    }
  }

  FileView {
    id: groupsFile
    path: root.groupsFilePath
    watchChanges: true
    printErrors: false
    onLoaded: root.loadGroups(text())
    onFileChanged: reload()
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
    if (!root.groupsLoaded) return
    var res = Logic.reconcileGroupsWithLayout(root.groupsList, root.barLayout)
    if (res && res.changed) {
      root.groupsList = res.groups
      var serialized = Logic.serializeData(res.groups, {
        displayMode: root.displayMode,
        slideDirection: root.slideDirection
      }, root.pluginOrigins)
      groupsFile.setText(serialized)
    }

    // Self-heal the per-group entry model (missing, stale or duplicate slots)
    if (root.isPrimaryInstance && bar && bar.shell && typeof bar.shell.mutateShellConfig === "function") {
      if (Logic.groupsNeedLayoutSync(root.groupsList, root.barLayout, root.widgetSource)) {
        root.syncShellLayout(root.groupsList)
        return
      }
      var dedup = Logic.deduplicateBarLayout(root.barLayout)
      if (dedup && dedup.changed) {
        bar.shell.mutateShellConfig(function(config) {
          if (!config || !config.bar || !config.bar.layout) return
          config.bar.layout = dedup.layout
        })
      }
    }
  }

  onBarLayoutChanged: Qt.callLater(root.reconcileBarLayout)
  onBarChanged: Qt.callLater(root.reconcileBarLayout)

  function syncShellLayout(groups) {
    if (!root.groupsLoaded) return
    if (!bar || !bar.shell || typeof bar.shell.mutateShellConfig !== "function") return

    // 1. Build map of all plugin IDs that are currently in at least one drawer group
    var groupedMap = {}

    for (var i = 0; i < groups.length; i++) {
      var g = groups[i]
      if (g) {
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

      // 5. Rebuild drawer entries: exactly one plain manager entry (right
      //    section only — the invisible host of the IPC handler and the
      //    manager popup) and one entry per group in its own position
      //    section. Group entries carry a unique id (`akshad.omadrawer.<id>`)
      //    and load this widget via the custom-QML mechanism, so the bar's
      //    drag system — which addresses entries by id — can tell every
      //    group apart in every section, even several groups side by side.
      var managerSeen = false
      var widgetSrc = root.widgetSource
      for (var s3 = 0; s3 < sections.length; s3++) {
        var sec3 = sections[s3]
        if (!Array.isArray(config.bar.layout[sec3])) config.bar.layout[sec3] = []

        var groupKeys = {}
        for (var g3 = 0; g3 < groups.length; g3++) {
          var gg = groups[g3]
          if (gg && (gg.position || "right") === sec3) groupKeys[gg.id] = true
        }

        var kept = []
        var seenGroup = {}
        for (var e3 = 0; e3 < config.bar.layout[sec3].length; e3++) {
          var ent = config.bar.layout[sec3][e3]
          var entKey = Logic.drawerEntryKey(ent)
          if (entKey === "") {
            kept.push(ent)
            continue
          }
          if (entKey === "plain") {
            if (sec3 !== "right" || managerSeen) continue
            managerSeen = true
            kept.push({ id: "akshad.omadrawer" })
          } else {
            var eGid = entKey.substring(2)
            if (!groupKeys[eGid] || seenGroup[eGid]) continue
            seenGroup[eGid] = true
            kept.push({
              id: Logic.groupEntryId(eGid),
              type: "qml",
              source: widgetSrc,
              groupId: eGid
            })
          }
        }

        if (sec3 === "right" && !managerSeen) {
          kept.push({ id: "akshad.omadrawer" })
          managerSeen = true
        }
        for (var gk in groupKeys) {
          if (!seenGroup[gk]) {
            kept.push({
              id: Logic.groupEntryId(gk),
              type: "qml",
              source: widgetSrc,
              groupId: gk
            })
          }
        }
        config.bar.layout[sec3] = kept
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

  function requestOpenManager() {
    if (root.isPrimaryInstance) {
      root.open()
      return
    }
    if (!bar || typeof bar.moduleWidgets !== "function") return
    var widgets = bar.moduleWidgets(root.pluginId)
    for (var i = 0; i < widgets.length; i++) {
      var w = widgets[i]
      if (w && w !== root && w.isPrimaryInstance && typeof w.open === "function") {
        w.open()
        return
      }
    }
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
    root.groupsLoaded = true
    Qt.callLater(root.reconcileBarLayout)
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
      // Creating a new group: the transient first-run welcome group has
      // served its purpose and leaves the bar.
      current = current.filter(function(g) { return !Logic.isWelcomeGroup(g) })
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
  implicitWidth: root.isDuplicateSlot ? 0 : barRow.implicitWidth
  implicitHeight: root.isDuplicateSlot ? 0 : barRow.implicitHeight
  width: implicitWidth
  height: implicitHeight
  visible: !root.isDuplicateSlot

  Row {
    id: barRow
    spacing: 0
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

    // Drawer Groups hosted by this instance (exactly one per group entry).
    // There is no manager icon on the bar: the manager popup is reached via
    // `omarchy-shell akshad.omadrawer toggle` or right-clicking a group.
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
        onOpenManager: root.requestOpenManager()
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
        anchorItem: root
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
