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
  "󰏖", "󰵪", "󰍛", "󰕮", "󰒓", "󰀻", "󰍹", "󰤨", "󰌌", "󰇄", "󰂯", "󰐥", "󰖐", "󰥔", "⚑", "󰂚"
];

function getDefaultGroups() {
  return [
    {
      id: "group-media-fun",
      name: "Media & Entertainment",
      icon: "󰵪",
      description: "Anime, Wordle and games bundle",
      enabled: true,
      plugins: ["akshad135.anisync", "akshad135.wordle", "jankeesvw.omasweeper"]
    },
    {
      id: "group-system-tools",
      name: "System & Hardware",
      icon: "󰍛",
      description: "Activity, audio controls and mesh",
      enabled: true,
      plugins: ["ilyazar.btop", "ssupt.audio-control", "omarchy.tailscale"]
    },
    {
      id: "group-connectivity",
      name: "Network & Devices",
      icon: "󰤨",
      description: "Wi-Fi, Bluetooth and displays",
      enabled: true,
      plugins: ["omarchy.network", "omarchy.bluetooth", "omarchy.monitor"]
    }
  ];
}

function findPluginMeta(pluginId) {
  for (var i = 0; i < KNOWN_PLUGINS.length; i++) {
    if (KNOWN_PLUGINS[i].id === pluginId) {
      return KNOWN_PLUGINS[i];
    }
  }
  // Fallback if third-party plugin unknown
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

function parseGroups(rawText) {
  if (!rawText || rawText.trim().length === 0) {
    return getDefaultGroups();
  }
  try {
    var data = JSON.parse(rawText);
    if (Array.isArray(data)) {
      return data;
    }
    if (data && Array.isArray(data.groups)) {
      return data.groups;
    }
  } catch (e) {
    console.warn("DrawerLogic: Failed to parse groups json:", e);
  }
  return getDefaultGroups();
}

function serializeGroups(groupsList) {
  return JSON.stringify({
    version: 1,
    updatedAt: new Date().toISOString(),
    groups: groupsList || []
  }, null, 2) + "\n";
}
