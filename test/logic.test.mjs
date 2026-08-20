// DrawerLogic.js unit tests. Run with: node test/logic.test.mjs or npm test
import fs from "node:fs"
import path from "node:path"
import { fileURLToPath } from "node:url"

const dir = path.dirname(fileURLToPath(import.meta.url))
const src = fs.readFileSync(path.join(dir, "..", "DrawerLogic.js"), "utf8")
  .replace(/\.pragma\s+library/g, "")

// QML JS modules export via bare functions/vars; expose them through a sandbox.
const sandbox = {}
const Logic = new Function(src + `
  return {
    KNOWN_PLUGINS, EXCLUDED_PLUGIN_IDS, PRESET_ICONS,
    isExcludedPlugin, findPluginMeta, generateGroupId,
    parseData, serializeData, getDefaultGroups,
    isWelcomeGroup, drawerEntryKey, groupEntryId,
    reconcileGroupsWithLayout, deduplicateBarLayout, groupsNeedLayoutSync
  }
`).call(sandbox)

let passed = 0
let failed = 0

function check(name, actual, expected) {
  const a = JSON.stringify(actual)
  const e = JSON.stringify(expected)
  if (a === e) {
    passed++
    console.log("  ok  " + name)
  } else {
    failed++
    console.log("FAIL  " + name + "\n      expected " + e + "\n      actual   " + a)
  }
}

console.log("== isExcludedPlugin ==")
check("Excludes self plugin (akshad.omadrawer)", Logic.isExcludedPlugin("akshad.omadrawer"), true)
check("Excludes per-group entry ids", Logic.isExcludedPlugin("akshad.omadrawer.group-mt1rctap-atwk"), true)
check("Excludes omarchy.indicators", Logic.isExcludedPlugin("omarchy.indicators"), true)
check("Excludes indicators suffix", Logic.isExcludedPlugin("indicators"), true)
check("Allows regular plugins (omarchy.clock)", Logic.isExcludedPlugin("omarchy.clock"), false)
check("Allows 3rd party plugins (akshad135.wordle)", Logic.isExcludedPlugin("akshad135.wordle"), false)
check("Handles empty/null cleanly", Logic.isExcludedPlugin(""), true)

console.log("\n== findPluginMeta ==")
const menuMeta = Logic.findPluginMeta("omarchy.menu")
check("omarchy.menu resolves exact logo & font", { name: menuMeta.name, icon: menuMeta.icon, fontFamily: menuMeta.fontFamily }, { name: "Menu", icon: "\ue900", fontFamily: "omarchy" })

const wsMeta = Logic.findPluginMeta("omarchy.workspaces")
check("omarchy.workspaces resolves icon", { name: wsMeta.name, icon: wsMeta.icon }, { name: "Workspaces", icon: "󰮯" })

const wordleMeta = Logic.findPluginMeta("akshad135.wordle")
check("akshad135.wordle resolves 'W' icon", { name: wordleMeta.name, icon: wordleMeta.icon }, { name: "Wordle", icon: "W" })

const sweepMeta = Logic.findPluginMeta("jankeesvw.omasweeper")
check("jankeesvw.omasweeper resolves flag icon", { name: sweepMeta.name, icon: sweepMeta.icon }, { name: "Omasweeper", icon: "⚑" })

// Dynamic Manifest lookup mock
const mockRegistry = {
  installedPlugins: {
    "my.custom.plugin": {
      __sourceDir: "/home/user/.config/omarchy/plugins/my.custom.plugin",
      name: "Custom Super Widget",
      icon: "assets/icon.svg",
      barWidget: { displayName: "Super Widget", category: "Productivity" }
    }
  }
}
const customMeta = Logic.findPluginMeta("my.custom.plugin", mockRegistry)
check("Custom plugin resolves manifest SVG and displayName", {
  name: customMeta.name,
  category: customMeta.category,
  iconUrl: customMeta.iconUrl
}, {
  name: "Super Widget",
  category: "Productivity",
  iconUrl: "file:///home/user/.config/omarchy/plugins/my.custom.plugin/assets/icon.svg"
})

console.log("\n== parseData & serializeData ==")
const defaultGroups = Logic.getDefaultGroups()
check("Default state is the welcome group only", { count: defaultGroups.length, welcome: defaultGroups[0].welcome, plugins: defaultGroups[0].plugins.length }, { count: 1, welcome: true, plugins: 0 })
check("Empty persisted groups list falls back to the welcome stub", (() => {
  const e = Logic.parseData(JSON.stringify({ groups: [], settings: {} }))
  return { count: e.groups.length, welcome: e.groups[0].welcome }
})(), { count: 1, welcome: true })
check("Welcome group is recognized", Logic.isWelcomeGroup(defaultGroups[0]), true)
check("Real groups are not welcome groups", Logic.isWelcomeGroup({ id: "g1", plugins: [] }), false)
const testGroups = [
  {
    id: "group-test-1",
    name: "Games",
    icon: "󰌌",
    position: "right",
    direction: "right",
    plugins: ["akshad135.wordle", "jankeesvw.omasweeper"]
  }
]
const testSettings = { displayMode: "both", slideDirection: "right" }
const testOrigins = { "akshad135.wordle": "right" }

const serialized = Logic.serializeData(testGroups, testSettings, testOrigins)
const parsed = Logic.parseData(serialized)

check("Serialized and parsed groups match", parsed.groups, testGroups)
check("Serialized and parsed settings match", parsed.settings, testSettings)
check("Serialized and parsed origins match", parsed.pluginOrigins, testOrigins)

// Legacy Array format fallback test
const legacyJson = JSON.stringify(testGroups)
const parsedLegacy = Logic.parseData(legacyJson)
check("Legacy raw array JSON formats properly", parsedLegacy.groups, testGroups)

console.log("\n== drawerEntryKey & groupEntryId ==")
const canonicalSource = "/home/user/.config/omarchy/plugins/akshad.omadrawer/BarWidget.qml"
const canonicalEntry = (gid) => ({ id: Logic.groupEntryId(gid), type: "qml", source: canonicalSource, groupId: gid })
check("groupEntryId builds unique per-group id", Logic.groupEntryId("g1"), "akshad.omadrawer.g1")
check("Plain host entry keys as plain", Logic.drawerEntryKey({ id: "akshad.omadrawer" }), "plain")
check("Legacy group entry keys by groupId", Logic.drawerEntryKey({ id: "akshad.omadrawer", groupId: "g1" }), "g:g1")
check("Canonical group entry keys by groupId", Logic.drawerEntryKey(canonicalEntry("g1")), "g:g1")
check("Unique-id entry without groupId derives its key", Logic.drawerEntryKey({ id: "akshad.omadrawer.g1" }), "g:g1")
check("Foreign entries have no drawer key", Logic.drawerEntryKey("omarchy.clock"), "")
check("Foreign entries have no drawer key (object)", Logic.drawerEntryKey({ id: "omarchy.menu" }), "")

console.log("\n== reconcileGroupsWithLayout ==")
// Test 1: Dragging a group's own entry from left to center
const leftGroups = [{ id: "g1", name: "LeftGroup", position: "left", plugins: [] }]
const movedToCenterLayout = {
  left: ["omarchy.menu"],
  center: [{ id: "akshad.omadrawer", groupId: "g1" }],
  right: [{ id: "akshad.omadrawer" }]
}
const rec1 = Logic.reconcileGroupsWithLayout(leftGroups, movedToCenterLayout)
check("Reconciles left to center drag", { changed: rec1.changed, position: rec1.groups[0].position }, { changed: true, position: "center" })

// Test 2: Dragging a group's own entry to right, next to the plain manager entry
const movedToRightLayout = {
  left: ["omarchy.menu"],
  center: [],
  right: [{ id: "akshad.omadrawer" }, { id: "akshad.omadrawer", groupId: "g1" }]
}
const rec2 = Logic.reconcileGroupsWithLayout(leftGroups, movedToRightLayout)
check("Reconciles left to right drag next to manager", { changed: rec2.changed, position: rec2.groups[0].position }, { changed: true, position: "right" })

// Test 3: Same side reordering does not alter positions
const sameSideLayout = {
  left: ["omarchy.clock", { id: "akshad.omadrawer", groupId: "g1" }],
  center: [],
  right: [{ id: "akshad.omadrawer" }]
}
const rec3 = Logic.reconcileGroupsWithLayout(leftGroups, sameSideLayout)
check("Same side reorder does not change group position", rec3.changed, false)

// Test 4: The plain manager entry alone never drags groups (independence)
const managerOnlyLayout = {
  left: ["omarchy.menu"],
  center: [],
  right: [{ id: "akshad.omadrawer" }]
}
const rec4 = Logic.reconcileGroupsWithLayout(leftGroups, managerOnlyLayout)
check("Plain manager entry does not move groups", rec4.changed, false)

// Test 5: Only the dragged group follows its entry; others stay put
const twoGroups = [
  { id: "g1", position: "left", plugins: [] },
  { id: "g2", position: "left", plugins: [] }
]
const splitLayout = {
  left: [{ id: "akshad.omadrawer", groupId: "g2" }],
  center: [{ id: "akshad.omadrawer", groupId: "g1" }],
  right: [{ id: "akshad.omadrawer" }]
}
const rec5 = Logic.reconcileGroupsWithLayout(twoGroups, splitLayout)
check("Only dragged group moves", { changed: rec5.changed, positions: rec5.groups.map(g => g.position) }, { changed: true, positions: ["center", "left"] })

console.log("\n== deduplicateBarLayout ==")
const duplicateLayout = {
  left: [],
  center: [],
  right: ["omarchy.tray", "akshad.omadrawer", "akshad.omadrawer", "omarchy.clock"]
}
const dedup = Logic.deduplicateBarLayout(duplicateLayout)
check("Deduplicates duplicate plain slots in right section", dedup.changed, true)
check("Right section length after deduplication is 3", dedup.layout.right.length, 3)

// Plain manager + per-group entries must all survive in the same section
const coexistingLayout = {
  left: [],
  center: [],
  right: [
    { id: "akshad.omadrawer" },
    { id: "akshad.omadrawer", groupId: "g1" },
    { id: "akshad.omadrawer", groupId: "g2" }
  ]
}
const dedupCo = Logic.deduplicateBarLayout(coexistingLayout)
check("Manager and per-group entries coexist without dedup", dedupCo.changed, false)
check("Coexisting section keeps all three drawer entries", dedupCo.layout.right.length, 3)

// Same groupId duplicated within a section is still cleaned
const dupGroupLayout = {
  left: [],
  center: [],
  right: [
    { id: "akshad.omadrawer" },
    { id: "akshad.omadrawer", groupId: "g1" },
    { id: "akshad.omadrawer", groupId: "g1" }
  ]
}
const dedupDg = Logic.deduplicateBarLayout(dupGroupLayout)
check("Duplicate group entries are deduplicated", dedupDg.changed, true)
check("Duplicate group section keeps manager plus one group entry", dedupDg.layout.right.length, 2)

const cleanLayout = {
  left: [{ id: "akshad.omadrawer", groupId: "g1" }],
  center: [],
  right: [{ id: "akshad.omadrawer" }]
}
const dedup2 = Logic.deduplicateBarLayout(cleanLayout)
check("Clean layout reports no duplicate changes", dedup2.changed, false)

// Canonical unique-id entries dedup identically to legacy ones
const dedupCanonical = Logic.deduplicateBarLayout({
  left: [],
  center: [],
  right: [canonicalEntry("g1"), canonicalEntry("g1"), { id: "akshad.omadrawer" }]
})
check("Canonical duplicate group entries are deduplicated", dedupCanonical.changed, true)
check("Canonical dedup keeps manager plus one group entry", dedupCanonical.layout.right.length, 2)

console.log("\n== groupsNeedLayoutSync ==")
const syncedLayout = {
  left: [canonicalEntry("g1")],
  center: [],
  right: [{ id: "akshad.omadrawer" }]
}
check("Perfect per-group layout needs no sync", Logic.groupsNeedLayoutSync(leftGroups, syncedLayout, canonicalSource), false)

const missingGroupEntry = {
  left: ["omarchy.menu"],
  center: [],
  right: [{ id: "akshad.omadrawer" }]
}
check("Missing group entry needs sync", Logic.groupsNeedLayoutSync(leftGroups, missingGroupEntry, canonicalSource), true)

const missingManager = {
  left: [canonicalEntry("g1")],
  center: [],
  right: []
}
check("Missing plain manager entry in right needs sync", Logic.groupsNeedLayoutSync(leftGroups, missingManager, canonicalSource), true)

const staleEntry = {
  left: [canonicalEntry("g1"), canonicalEntry("stale")],
  center: [],
  right: [{ id: "akshad.omadrawer" }]
}
check("Stale group entry needs sync", Logic.groupsNeedLayoutSync(leftGroups, staleEntry, canonicalSource), true)

const plainInLeft = {
  left: [canonicalEntry("g1"), { id: "akshad.omadrawer" }],
  center: [],
  right: [{ id: "akshad.omadrawer" }]
}
check("Plain entry in left section needs sync", Logic.groupsNeedLayoutSync(leftGroups, plainInLeft, canonicalSource), true)

// Shape checks: the same key sets can still need a rewrite when entries are
// legacy shared-id, missing the custom-QML source, or missing groupId.
const legacyEntry = {
  left: [{ id: "akshad.omadrawer", groupId: "g1" }],
  center: [],
  right: [{ id: "akshad.omadrawer" }]
}
check("Legacy shared-id group entry needs sync", Logic.groupsNeedLayoutSync(leftGroups, legacyEntry, canonicalSource), true)

const wrongSource = {
  left: [{ id: Logic.groupEntryId("g1"), type: "qml", source: "/somewhere/else/BarWidget.qml", groupId: "g1" }],
  center: [],
  right: [{ id: "akshad.omadrawer" }]
}
check("Group entry with wrong widget source needs sync", Logic.groupsNeedLayoutSync(leftGroups, wrongSource, canonicalSource), true)

const missingType = {
  left: [{ id: Logic.groupEntryId("g1"), source: canonicalSource, groupId: "g1" }],
  center: [],
  right: [{ id: "akshad.omadrawer" }]
}
check("Group entry missing custom-QML type needs sync", Logic.groupsNeedLayoutSync(leftGroups, missingType, canonicalSource), true)

const missingGroupIdField = {
  left: [{ id: Logic.groupEntryId("g1"), type: "qml", source: canonicalSource }],
  center: [],
  right: [{ id: "akshad.omadrawer" }]
}
check("Unique-id entry without groupId field needs sync", Logic.groupsNeedLayoutSync(leftGroups, missingGroupIdField, canonicalSource), true)

// Empty widgetSource skips only the source comparison (unit-test convenience)
check("Canonical shape passes with empty widgetSource", Logic.groupsNeedLayoutSync(leftGroups, syncedLayout, ""), false)
check("Source mismatch ignored when widgetSource is empty", Logic.groupsNeedLayoutSync(leftGroups, wrongSource, ""), false)

console.log("\n-----------------------------------------")
console.log(`Results: ${passed} passed, ${failed} failed`)
if (failed > 0) process.exit(1)

