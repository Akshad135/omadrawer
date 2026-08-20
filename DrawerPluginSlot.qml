import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Ui
import "DrawerLogic.js" as Logic

Item {
  id: root

  required property string pluginId
  property var bar: null
  property bool expanded: false

  readonly property var registryComponent: {
    if (!bar || !bar.barWidgetRegistry || !bar.barWidgetRegistry.widgets) return null
    var w = bar.barWidgetRegistry.widgets
    var canonical = Util.canonicalWidgetId(pluginId)
    var entry = w[canonical] || w[pluginId]
    return entry ? entry.component : null
  }

  readonly property var pluginMeta: Logic.findPluginMeta(pluginId)
  readonly property bool isRegistered: registryComponent !== null
  readonly property var activeItem: isRegistered ? loader.item : fallbackButton
  implicitWidth: {
    if (activeItem && activeItem.visible !== false) {
      if (bar && bar.vertical) return bar.barSize
      if (activeItem.implicitWidth > 0) return activeItem.implicitWidth
      return Style.bar.iconSlot
    }
    if (isRegistered) {
      return Style.bar.iconSlot
    }
    return fallbackButton.implicitWidth > 0 ? fallbackButton.implicitWidth : Style.bar.iconSlot
  }

  implicitHeight: {
    if (activeItem && activeItem.visible !== false) {
      if (activeItem.implicitHeight > 0) return activeItem.implicitHeight
      return bar ? bar.barSize : Style.bar.sizeHorizontal
    }
    return bar ? bar.barSize : Style.bar.sizeHorizontal
  }

  width: implicitWidth
  height: implicitHeight

  function applyExpandedState(target) {
    if (!target) return
    if ("interactive" in target) {
      target.interactive = Qt.binding(function() { return root.expanded })
    }
    if ("concealed" in target) {
      target.concealed = Qt.binding(function() { return !root.expanded })
    }
    if ("enabled" in target) {
      target.enabled = Qt.binding(function() { return root.expanded })
    }

    if (target.children) {
      for (var i = 0; i < target.children.length; i++) {
        var child = target.children[i]
        if (child) {
          if ("interactive" in child) {
            child.interactive = Qt.binding(function() { return root.expanded })
          }
          if ("concealed" in child) {
            child.concealed = Qt.binding(function() { return !root.expanded })
          }
          if ("enabled" in child) {
            child.enabled = Qt.binding(function() { return root.expanded })
          }
        }
      }
    }
  }

  Loader {
    id: loader
    active: root.isRegistered
    sourceComponent: root.registryComponent
    anchors.fill: parent

    onLoaded: {
      injectProps()
      Qt.callLater(injectProps)
    }

    onItemChanged: {
      injectProps()
      Qt.callLater(injectProps)
    }

    function injectProps() {
      if (!item) return
      if ("bar" in item) item.bar = root.bar
      if ("moduleName" in item) item.moduleName = root.pluginId
      if ("settings" in item) item.settings = ({})
      // Ensure the loaded widget item expands to fill this slot's allocated dimensions
      item.width = Qt.binding(function() { return root.width })
      item.height = Qt.binding(function() { return root.height })
      root.applyExpandedState(item)
    }
  }

  onExpandedChanged: {
    if (loader.item) {
      applyExpandedState(loader.item)
    }
  }

  onBarChanged: {
    if (loader.item) {
      if ("bar" in loader.item) loader.item.bar = root.bar
    }
  }

  WidgetButton {
    id: fallbackButton
    visible: !root.isRegistered
    interactive: root.expanded
    concealed: !root.expanded
    enabled: root.expanded
    anchors.fill: parent
    bar: root.bar
    text: root.pluginMeta.icon || "󰏖"
    tooltipText: root.pluginMeta.name || root.pluginId

    onPressed: function(button) {
      if (!root.expanded) return
      Quickshell.execDetached(["omarchy-shell", "shell", "toggle", root.pluginId, "{}"])
    }
  }
}
