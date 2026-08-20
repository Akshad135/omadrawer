.pragma library

// Comprehensive catalogue of plugins with their icons, clean names, and categories
var KNOWN_PLUGINS = [
  { id: "omarchy.menu", name: "App Menu", icon: "󰣇", category: "System", desc: "Application launcher" },
  { id: "omarchy.workspaces", name: "Workspaces", icon: "󰮯", category: "System", desc: "Workspace switcher & pager" },
  { id: "akshad.lock", name: "Lock Screen", icon: "󰌾", category: "System", desc: "Desktop screen lock" },
  { id: "omarchy.lock", name: "Lock Screen", icon: "󰌾", category: "System", desc: "Desktop screen lock" },
  { id: "akshad.clipboard", name: "Clipboard", icon: "󰅍", category: "Utilities", desc: "Clipboard history manager" },
  { id: "omarchy.clipboard", name: "Clipboard", icon: "󰅍", category: "Utilities", desc: "Clipboard history manager" },
  { id: "omarchy.system-update", name: "System Update", icon: "󰚰", category: "System", desc: "Package & OS updates" },
  { id: "akshad135.anisync", name: "AniSync", icon: "󰵪", category: "Media", desc: "Anime & Manga tracker" },
  { id: "akshad135.wordle", name: "Wordle", icon: "󰌌", category: "Games", desc: "Daily word puzzle" },
  { id: "jankeesvw.omasweeper", name: "Omasweeper", icon: "⚑", category: "Games", desc: "Minesweeper bar widget" },
  { id: "io.github.tallsam.navbar-cat", name: "Navbar Cat", icon: "󰄛", category: "Fun", desc: "Cute top bar pet cat" },
  { id: "ilyazar.btop", name: "btop Activity", icon: "󰍛", category: "System", desc: "CPU, RAM & process monitor" },
  { id: "ssupt.audio-control", name: "Audio Control", icon: "󰕮", category: "Media", desc: "Advanced audio mixer" },
  { id: "omarchy.audio", name: "Audio", icon: "󰕮", category: "Media", desc: "Volume & output devices" },
  { id: "omarchy.tailscale", name: "Tailscale", icon: "󰇄", category: "Network", desc: "VPN & mesh status" },
  { id: "omarchy.bluetooth", name: "Bluetooth", icon: "󰂯", category: "Hardware", desc: "Bluetooth devices" },
  { id: "omarchy.network", name: "Network", icon: "󰤨", category: "Network", desc: "Wi-Fi & Ethernet" },
  { id: "omarchy.monitor", name: "Display", icon: "󰍹", category: "Hardware", desc: "Display brightness & layout" },
  { id: "omarchy.power", name: "Power", icon: "󰐥", category: "System", desc: "Battery & power management" },
  { id: "omarchy.microphone", name: "Microphone", icon: "󰍬", category: "Media", desc: "Mic input & mute toggle" },
  { id: "omarchy.weather", name: "Weather", icon: "󰖐", category: "Utilities", desc: "Local forecast & radar" },
  { id: "omarchy.media", name: "Media Player", icon: "󰐊", category: "Media", desc: "Now playing controls" },
  { id: "omarchy.clock", name: "Clock", icon: "󰥔", category: "Utilities", desc: "Time, calendar & alarms" },
  { id: "shavanced.notification-center", name: "Notification Center", icon: "󰂚", category: "System", desc: "Notifications feed" },
  { id: "omarchy.notifications", name: "Notifications", icon: "󰂚", category: "System", desc: "Notifications feed" },
  { id: "omarchy.tray", name: "System Tray", icon: "󰇄", category: "System", desc: "Status notifier items" }
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
  "󰵪", "󰐊", "󰕮", "󰎆", "󰝚", "󰑋", "󰝰", "󰗃", "󰕼", "󰎈",
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
    return { id: "unknown", name: "Plugin", icon: "󰏖", iconUrl: "", category: "Plugin", desc: "" };
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

  if (lower.indexOf("menu") !== -1) { icon = "󰣇"; category = "System"; }
  else if (lower.indexOf("workspace") !== -1) { icon = "󰮯"; category = "System"; }
  else if (lower.indexOf("lock") !== -1) { icon = "󰌾"; category = "System"; }
  else if (lower.indexOf("clip") !== -1) { icon = "󰅍"; category = "Utilities"; }
  else if (lower.indexOf("update") !== -1) { icon = "󰚰"; category = "System"; }
  else if (lower.indexOf("cat") !== -1) { icon = "󰄛"; category = "Fun"; }
  else if (lower.indexOf("audio") !== -1 || lower.indexOf("volume") !== -1 || lower.indexOf("sound") !== -1) { icon = "󰕮"; category = "Media"; }
  else if (lower.indexOf("notif") !== -1) { icon = "󰂚"; category = "System"; }
  else if (lower.indexOf("power") !== -1 || lower.indexOf("batt") !== -1) { icon = "󰐥"; category = "System"; }
  else if (lower.indexOf("btop") !== -1 || lower.indexOf("cpu") !== -1 || lower.indexOf("ram") !== -1) { icon = "󰍛"; category = "System"; }
  else if (lower.indexOf("blue") !== -1) { icon = "󰂯"; category = "Hardware"; }
  else if (lower.indexOf("wifi") !== -1 || lower.indexOf("network") !== -1 || lower.indexOf("net") !== -1) { icon = "󰤨"; category = "Network"; }
  else if (lower.indexOf("weather") !== -1) { icon = "󰖐"; category = "Utilities"; }
  else if (lower.indexOf("clock") !== -1 || lower.indexOf("time") !== -1) { icon = "󰥔"; category = "Utilities"; }
  else if (lower.indexOf("mic") !== -1) { icon = "󰍬"; category = "Media"; }
  else if (lower.indexOf("game") !== -1 || lower.indexOf("wordle") !== -1) { icon = "󰌌"; category = "Games"; }
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

function serializeData(groupsList, settings, pluginOrigins) {
  return JSON.stringify({
    version: 1,
    updatedAt: new Date().toISOString(),
    settings: settings || { displayMode: "icon", slideDirection: "right" },
    pluginOrigins: pluginOrigins || {},
    groups: groupsList || []
  }, null, 2) + "\n";
}
