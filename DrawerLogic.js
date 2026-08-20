.pragma library

// Default catalogue of known plugins with their icons and friendly names
var KNOWN_PLUGINS = [
  { id: "akshad135.anisync", name: "AniSync", icon: "󰵪", category: "Media", desc: "Anime & Manga tracker" },
  { id: "akshad135.wordle", name: "Wordle", icon: "󰌌", category: "Games", desc: "Daily word puzzle" },
  { id: "jankeesvw.omasweeper", name: "Omasweeper", icon: "⚑", category: "Games", desc: "Minesweeper bar widget" },
  { id: "ilyazar.btop", name: "btop Activity", icon: "󰍛", category: "System", desc: "CPU, RAM & process monitor" },
  { id: "ssupt.audio-control", name: "Audio Control", icon: "󰕮", category: "Media", desc: "Advanced audio mixer" },
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
  { id: "omarchy.tray", name: "System Tray", icon: "󰇄", category: "System", desc: "Status notifier items" }
];

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

function findPluginMeta(pluginId) {
  for (var i = 0; i < KNOWN_PLUGINS.length; i++) {
    if (KNOWN_PLUGINS[i].id === pluginId) {
      return KNOWN_PLUGINS[i];
    }
  }
  var shortName = pluginId.split(".").pop();
  return {
    id: pluginId,
    name: shortName.charAt(0).toUpperCase() + shortName.slice(1),
    icon: "󰏖",
    category: "Plugin",
    desc: pluginId
  };
}

function generateGroupId() {
  return "group-" + Date.now().toString(36) + "-" + Math.random().toString(36).substring(2, 6);
}

function parseData(rawText) {
  var defaults = {
    settings: {
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
        settings: { slideDirection: "right" },
        pluginOrigins: {},
        groups: data
      };
    }
    if (data && typeof data === "object") {
      var groups = Array.isArray(data.groups) ? data.groups : getDefaultGroups();
      return {
        settings: data.settings || { slideDirection: "right" },
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
    settings: settings || { slideDirection: "right" },
    pluginOrigins: pluginOrigins || {},
    groups: groupsList || []
  }, null, 2) + "\n";
}
