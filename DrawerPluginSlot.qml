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

  implicitWidth: activeItem ? (bar && bar.vertical ? bar.barSize : (activeItem.implicitWidth > 0 ? activeItem.implicitWidth : Style.bar.iconSlot)) : fallbackButton.implicitWidth
  implicitHeight: activeItem ? (activeItem.implicitHeight > 0 ? activeItem.implicitHeight : (bar ? bar.barSize : Style.bar.sizeHorizontal)) : fallbackButton.implicitHeight

  width: implicitWidth
  height: implicitHeight

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
    anchors.fill: parent
    bar: root.bar
    text: root.pluginMeta.icon || "󰏖"
    tooltipText: root.pluginMeta.name || root.pluginId

    onPressed: function(button) {
      Quickshell.execDetached(["omarchy-shell", "shell", "toggle", root.pluginId, "{}"])
    }
  }
}
