.pragma library

// Complete official catalogue of Omarchy 1st-party plugins and known 3rd-party widgets
var KNOWN_PLUGINS = [
  // ------------------------------------------------------------- 1st-Party Omarchy Plugins
  { id: "omarchy.menu", name: "Menu", icon: "\ue900", fontFamily: "omarchy", category: "System", desc: "Application launcher & terminal shortcut" },
  { id: "omarchy.workspaces", name: "Workspaces", icon: "󰮯", category: "System", desc: "Hyprland workspace switcher & pager" },
  { id: "omarchy.system-update", name: "System Update", icon: "󰚰", category: "System", desc: "Package & system update status" },
  { id: "omarchy.keyboard-layout", name: "Keyboard", icon: "󰌌", category: "Hardware", desc: "Keyboard layout switcher" },
  { id: "omarchy.microphone", name: "Microphone", icon: "󰍬", category: "Media", desc: "Mic input state & mute toggle" },
  { id: "omarchy.clock", name: "Clock", icon: "󰥔", category: "Utilities", desc: "Time, calendar & life progress" },
  { id: "omarchy.weather", name: "Weather", icon: "󰖐", category: "Utilities", desc: "Local forecast & weather radar" },
  { id: "omarchy.media", name: "Media Player", icon: "󰐊", category: "Media", desc: "Now playing playback controls" },
  { id: "omarchy.audio", name: "Audio", icon: "󰕾", category: "Media", desc: "Volume mixer & audio devices" },
  { id: "omarchy.bluetooth", name: "Bluetooth", icon: "󰂯", category: "Hardware", desc: "Bluetooth devices & pairing" },
  { id: "omarchy.network", name: "Network", icon: "󰤨", category: "Network", desc: "Wi-Fi & Ethernet connections" },
  { id: "omarchy.tailscale", name: "Tailscale", icon: "󰇄", category: "Network", desc: "VPN & Tailscale mesh network" },
  { id: "omarchy.monitor", name: "Display", icon: "󰍹", category: "Hardware", desc: "Display brightness & monitor layout" },
  { id: "omarchy.power", name: "Power", icon: "󰐥", category: "System", desc: "Battery, sleep & power management" },
  { id: "omarchy.lock", name: "Lock Screen", icon: "󰌾", category: "System", desc: "Desktop lock & security" },
  { id: "omarchy.clipboard", name: "Clipboard", icon: "󰅍", category: "Utilities", desc: "Clipboard history manager" },
  { id: "omarchy.notifications", name: "Notifications", icon: "󰂚", category: "System", desc: "Notifications feed & history" },
  { id: "omarchy.reminders", name: "Reminders", icon: "󰂞", category: "Utilities", desc: "Desktop reminders & timer" },
  { id: "omarchy.tray", name: "System Tray", icon: "󰇄", category: "System", desc: "StatusNotifier tray items" },
  { id: "omarchy.active-window", name: "Active Window", icon: "󰖲", category: "System", desc: "Focused window title & icon" },
  { id: "omarchy.emojis", name: "Emojis", icon: "󰞋", category: "Utilities", desc: "Emoji picker" },
  { id: "omarchy.dropbox", name: "Dropbox", icon: "󰇄", category: "Cloud", desc: "Dropbox sync status" },
  { id: "omarchy.speedtest", name: "Speedtest", icon: "󰓅", category: "Network", desc: "Internet bandwidth test" },
  { id: "omarchy.disk-speedtest", name: "Disk Speed", icon: "󰓅", category: "System", desc: "Storage drive benchmark" },
  { id: "omarchy.wifiqr", name: "Wi-Fi QR", icon: "󰤨", category: "Network", desc: "Share Wi-Fi credentials via QR" },

  // ------------------------------------------------------------- 3rd-Party Plugins
  { id: "akshad.lock", name: "Lock Screen", icon: "󰌾", category: "System", desc: "Desktop lock button" },
  { id: "akshad.clipboard", name: "Clipboard", icon: "󰅍", category: "Utilities", desc: "Clipboard history manager" },
  { id: "akshad135.anisync", name: "AniSync", icon: "󰵪", category: "Media", desc: "Anime & Manga release tracker" },
  { id: "akshad135.wordle", name: "Wordle", icon: "W", category: "Games", desc: "Daily NYT Wordle puzzle" },
  { id: "jankeesvw.omasweeper", name: "Omasweeper", icon: "⚑", category: "Games", desc: "Minesweeper bar widget" },
  { id: "io.github.tallsam.navbar-cat", name: "Navbar Cat", icon: "󰄛", category: "Fun", desc: "Interactive top bar pet" },
  { id: "ilyazar.btop", name: "btop Activity", icon: "󰍛", category: "System", desc: "CPU, RAM & process monitor" },
  { id: "ssupt.audio-control", name: "Audio Control", icon: "󰕾", category: "Media", desc: "Advanced audio mixer" },
  { id: "shavanced.notification-center", name: "Notification Center", icon: "󰂚", category: "System", desc: "Notifications feed" }
];

var EXCLUDED_PLUGIN_IDS = [
  "akshad.omadrawer",
  "omarchy.indicators",
  "indicators"
];

function isExcludedPlugin(pluginId) {
  if (!pluginId || typeof pluginId !== "string") return true;
  var id = pluginId.trim();
  if (id === "") return true;
  for (var i = 0; i < EXCLUDED_PLUGIN_IDS.length; i++) {
    if (id === EXCLUDED_PLUGIN_IDS[i] || id === "omarchy." + EXCLUDED_PLUGIN_IDS[i]) {
      return true;
    }
  }
  return false;
}

var PRESET_ICONS = [
  // Drawers & Boxes
  "󰏖", "󰀻", "󰅪", "󰆦", "󰆧", "󰒓", "󰘳", "󰘵", "󰏘", "󰏗",
  // Media & Audio
  "󰵪", "󰐊", "󰕾", "󰎆", "󰝚", "󰑋", "󰝰", "󰗃", "󰕼", "󰎈",
  // Gaming & Play
  "󰌌", "⚑", "󰊖", "󰊗", "󰊕", "󰊢", "󰍳", "󰡏", "󰓎", "󰓏",
  // System & Hardware
  "󰍛", "󰢮", "󰘚", "󰍹", "󰐥", "󰌢", "󰌪", "󰒋", "󰚌", "󰈙",
  // Network & Devices
  "󰤨", "󰂯", "󰇄", "󰍬", "󰕢", "󰢝", "󰂚", "󰖩", "󰖩", "󰅐",
  // Tools & Productivity
  "󰥔", "󰖐", "󰃭", "󰈙", "󰏝", "󰃟", "󰄬", "󰆍", "󰅨", "󰘐"
];

function getDefaultGroups() {
  return [
    {
      id: "group-media-fun",
      name: "Media & Entertainment",
      icon: "󰵪",
      position: "right",
      direction: "right",
      description: "",
      enabled: true,
      plugins: ["akshad135.anisync", "akshad135.wordle", "jankeesvw.omasweeper"]
    }
  ];
}

function findPluginMeta(pluginId, pluginRegistry) {
  if (!pluginId || typeof pluginId !== "string") {
    return { id: "unknown", name: "Plugin", icon: "󰏖", iconUrl: "", fontFamily: "", category: "Plugin", desc: "" };
  }
  var trimmedId = pluginId.trim();
  var iconUrl = "";
  var registeredName = "";
  var registeredCat = "";
  var registeredDesc = "";

  // Dynamic manifest inspection from PluginRegistry
  if (pluginRegistry && pluginRegistry.installedPlugins && pluginRegistry.installedPlugins[trimmedId]) {
    var pManifest = pluginRegistry.installedPlugins[trimmedId];
    if (pManifest) {
      if (pManifest.name) registeredName = pManifest.name;
      if (pManifest.description) registeredDesc = pManifest.description;
      if (pManifest.barWidget) {
        if (pManifest.barWidget.displayName) registeredName = pManifest.barWidget.displayName;
        if (pManifest.barWidget.category) registeredCat = pManifest.barWidget.category;
        if (pManifest.barWidget.description) registeredDesc = pManifest.barWidget.description;
      }
      var rawIcon = (pManifest.barWidget && pManifest.barWidget.icon) ? pManifest.barWidget.icon : pManifest.icon;
      if (rawIcon && typeof rawIcon === "string" && pManifest.__sourceDir) {
        if (rawIcon.startsWith("/") || rawIcon.startsWith("file://")) {
          iconUrl = rawIcon;
        } else {
          iconUrl = "file://" + pManifest.__sourceDir + "/" + rawIcon;
        }
      }
    }
  }

  // 1. Direct match in KNOWN_PLUGINS
  for (var i = 0; i < KNOWN_PLUGINS.length; i++) {
    if (KNOWN_PLUGINS[i].id === trimmedId) {
      var item = KNOWN_PLUGINS[i];
      return {
        id: trimmedId,
        name: registeredName || item.name,
        icon: item.icon,
        fontFamily: item.fontFamily || "",
        iconUrl: iconUrl,
        category: registeredCat || item.category,
        desc: registeredDesc || item.desc
      };
    }
  }

  // 2. Suffix match
  var rawKey = trimmedId.split(".").pop().toLowerCase();
  for (var j = 0; j < KNOWN_PLUGINS.length; j++) {
    var knownKey = KNOWN_PLUGINS[j].id.split(".").pop().toLowerCase();
    if (rawKey === knownKey) {
      var kItem = KNOWN_PLUGINS[j];
      return {
        id: trimmedId,
        name: registeredName || kItem.name,
        icon: kItem.icon,
        fontFamily: kItem.fontFamily || "",
        iconUrl: iconUrl,
        category: registeredCat || kItem.category,
        desc: registeredDesc || kItem.desc
      };
    }
  }

  // 3. Heuristic match for custom plugins
  var icon = "󰏖";
  var category = registeredCat || "Plugin";
  var lower = trimmedId.toLowerCase();

  if (lower.indexOf("menu") !== -1) { icon = "\ue900"; category = "System"; }
  else if (lower.indexOf("workspace") !== -1) { icon = "󰮯"; category = "System"; }
  else if (lower.indexOf("lock") !== -1) { icon = "󰌾"; category = "System"; }
  else if (lower.indexOf("clip") !== -1) { icon = "󰅍"; category = "Utilities"; }
  else if (lower.indexOf("update") !== -1) { icon = "󰚰"; category = "System"; }
  else if (lower.indexOf("cat") !== -1) { icon = "󰄛"; category = "Fun"; }
  else if (lower.indexOf("audio") !== -1 || lower.indexOf("volume") !== -1 || lower.indexOf("sound") !== -1) { icon = "󰕾"; category = "Media"; }
  else if (lower.indexOf("notif") !== -1) { icon = "󰂚"; category = "System"; }
  else if (lower.indexOf("power") !== -1 || lower.indexOf("batt") !== -1) { icon = "󰐥"; category = "System"; }
  else if (lower.indexOf("btop") !== -1 || lower.indexOf("cpu") !== -1 || lower.indexOf("ram") !== -1) { icon = "󰍛"; category = "System"; }
  else if (lower.indexOf("blue") !== -1) { icon = "󰂯"; category = "Hardware"; }
  else if (lower.indexOf("wifi") !== -1 || lower.indexOf("network") !== -1 || lower.indexOf("net") !== -1) { icon = "󰤨"; category = "Network"; }
  else if (lower.indexOf("weather") !== -1) { icon = "󰖐"; category = "Utilities"; }
  else if (lower.indexOf("clock") !== -1 || lower.indexOf("time") !== -1) { icon = "󰥔"; category = "Utilities"; }
  else if (lower.indexOf("mic") !== -1) { icon = "󰍬"; category = "Media"; }
  else if (lower.indexOf("game") !== -1 || lower.indexOf("wordle") !== -1) { icon = "W"; category = "Games"; }
  else if (lower.indexOf("sweep") !== -1 || lower.indexOf("mine") !== -1) { icon = "⚑"; category = "Games"; }
  else if (lower.indexOf("sync") !== -1 || lower.indexOf("ani") !== -1) { icon = "󰵪"; category = "Media"; }
  else if (lower.indexOf("display") !== -1 || lower.indexOf("monitor") !== -1) { icon = "󰍹"; category = "Hardware"; }
  else if (lower.indexOf("tray") !== -1) { icon = "󰇄"; category = "System"; }

  var displayName = registeredName || (rawKey.charAt(0).toUpperCase() + rawKey.slice(1));
  return {
    id: trimmedId,
    name: displayName,
    icon: icon,
    iconUrl: iconUrl,
    fontFamily: (lower.indexOf("menu") !== -1) ? "omarchy" : "",
    category: category,
    desc: registeredDesc || trimmedId
  };
}

function generateGroupId() {
  return "group-" + Date.now().toString(36) + "-" + Math.random().toString(36).substring(2, 6);
}

function parseData(rawText) {
  var defaults = {
    settings: {
      displayMode: "icon",
      slideDirection: "right"
    },
    pluginOrigins: {},
    groups: getDefaultGroups()
  };
  if (!rawText || rawText.trim().length === 0) {
    return defaults;
  }
  try {
    var data = JSON.parse(rawText);
    if (Array.isArray(data)) {
      return {
        settings: { displayMode: "icon", slideDirection: "right" },
        pluginOrigins: {},
        groups: data
      };
    }
    if (data && typeof data === "object") {
      var groups = Array.isArray(data.groups) ? data.groups : getDefaultGroups();
      var settings = data.settings || {};
      if (!settings.displayMode) settings.displayMode = "icon";
      return {
        settings: settings,
        pluginOrigins: data.pluginOrigins || {},
        groups: groups
      };
    }
  } catch (e) {
    console.warn("DrawerLogic: Failed to parse data json:", e);
  }
  return defaults;
}

function reconcileGroupsWithLayout(groups, barLayout) {
  if (!Array.isArray(groups) || groups.length === 0 || !barLayout || typeof barLayout !== "object") {
    return { changed: false, groups: groups || [] };
  }

  function hasDrawer(list) {
    if (!Array.isArray(list)) return false;
    for (var i = 0; i < list.length; i++) {
      var entry = list[i];
      var id = typeof entry === "string" ? entry : (entry && entry.id ? entry.id : "");
      if (id === "akshad.omadrawer") return true;
    }
    return false;
  }

  var activeSections = {
    left: hasDrawer(barLayout.left),
    center: hasDrawer(barLayout.center),
    right: hasDrawer(barLayout.right)
  };

  // Sections that currently host groups according to groups array
  var groupsBySection = { left: [], center: [], right: [] };
  for (var i = 0; i < groups.length; i++) {
    var g = groups[i];
    var pos = (g && g.position) ? g.position : "right";
    if (!groupsBySection[pos]) groupsBySection[pos] = [];
    groupsBySection[pos].push(g);
  }

  // Sections that had groups but no longer have akshad.omadrawer in barLayout
  var orphanedSections = [];
  var sections = ["left", "center", "right"];
  for (var s = 0; s < sections.length; s++) {
    var sec = sections[s];
    if (groupsBySection[sec].length > 0 && !activeSections[sec]) {
      orphanedSections.push(sec);
    }
  }

  if (orphanedSections.length === 0) {
    return { changed: false, groups: groups };
  }

  // Available destination sections that DO have akshad.omadrawer in barLayout
  var availableDestSections = [];
  for (var d = 0; d < sections.length; d++) {
    var dSec = sections[d];
    if (activeSections[dSec]) {
      availableDestSections.push(dSec);
    }
  }

  if (availableDestSections.length === 0) {
    return { changed: false, groups: groups };
  }

  // Select target: prefer section that had no groups previously, or first available
  var targetSec = "";
  for (var a = 0; a < availableDestSections.length; a++) {
    var cand = availableDestSections[a];
    if (groupsBySection[cand].length === 0) {
      targetSec = cand;
      break;
    }
  }
  if (!targetSec) {
    targetSec = availableDestSections[0];
  }

  var updatedGroups = [];
  var changed = false;
  for (var j = 0; j < groups.length; j++) {
    var grp = Object.assign({}, groups[j]);
    var gPos = grp.position || "right";
    if (orphanedSections.indexOf(gPos) !== -1) {
      grp.position = targetSec;
      changed = true;
    }
    updatedGroups.push(grp);
  }

  return { changed: changed, groups: updatedGroups };
}

function deduplicateBarLayout(barLayout) {
  if (!barLayout || typeof barLayout !== "object") return { changed: false, layout: barLayout };
  var sections = ["left", "center", "right"];
  var changed = false;
  var nextLayout = {};

  for (var s = 0; s < sections.length; s++) {
    var sec = sections[s];
    var list = barLayout[sec];
    if (Array.isArray(list)) {
      var seenDrawer = false;
      var filtered = [];
      for (var i = 0; i < list.length; i++) {
        var entry = list[i];
        var id = typeof entry === "string" ? entry : (entry && entry.id ? entry.id : "");
        if (id === "akshad.omadrawer") {
          if (!seenDrawer) {
            seenDrawer = true;
            filtered.push(entry);
          } else {
            changed = true;
          }
        } else {
          filtered.push(entry);
        }
      }
      nextLayout[sec] = filtered;
    } else {
      nextLayout[sec] = list;
    }
  }

  return { changed: changed, layout: nextLayout };
}

function serializeData(groupsList, settings, pluginOrigins) {
  return JSON.stringify({
    version: 1,
    updatedAt: new Date().toISOString(),
    settings: settings || { displayMode: "icon", slideDirection: "right" },
    pluginOrigins: pluginOrigins || {},
    groups: groupsList || []
  }, null, 2) + "\n";
}

