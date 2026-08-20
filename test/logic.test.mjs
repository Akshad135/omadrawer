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
    parseData, serializeData, getDefaultGroups, reconcileGroupsWithLayout
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

console.log("\n== reconcileGroupsWithLayout ==")
// Test 1: Dragging a group from left to center
const leftGroups = [{ id: "g1", name: "LeftGroup", position: "left", plugins: [] }]
const movedToCenterLayout = {
  left: ["omarchy.menu"],
  center: ["akshad.omadrawer"],
  right: ["akshad.omadrawer"]
}
const rec1 = Logic.reconcileGroupsWithLayout(leftGroups, movedToCenterLayout)
check("Reconciles left to center drag", { changed: rec1.changed, position: rec1.groups[0].position }, { changed: true, position: "center" })

// Test 2: Dragging a group from left to right (where manager also exists)
const movedToRightLayout = {
  left: ["omarchy.menu"],
  center: [],
  right: [{ id: "akshad.omadrawer" }]
}
const rec2 = Logic.reconcileGroupsWithLayout(leftGroups, movedToRightLayout)
check("Reconciles left to right drag", { changed: rec2.changed, position: rec2.groups[0].position }, { changed: true, position: "right" })

// Test 3: Same side reordering does not alter positions
const sameSideLayout = {
  left: ["omarchy.clock", "akshad.omadrawer"],
  center: [],
  right: ["akshad.omadrawer"]
}
const rec3 = Logic.reconcileGroupsWithLayout(leftGroups, sameSideLayout)
check("Same side reorder does not change group position", rec3.changed, false)

console.log("\n-----------------------------------------")
console.log(`Results: ${passed} passed, ${failed} failed`)
if (failed > 0) process.exit(1)

