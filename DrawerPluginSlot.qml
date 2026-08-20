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

  implicitWidth: isRegistered 
    ? (loader.item && loader.item.visible ? (bar && bar.vertical ? bar.barSize : loader.item.implicitWidth) : 0) 
    : fallbackButton.implicitWidth
  implicitHeight: isRegistered 
    ? (loader.item && loader.item.visible ? loader.item.implicitHeight : 0) 
    : fallbackButton.implicitHeight

  width: implicitWidth
  height: implicitHeight
  visible: implicitWidth > 0 && implicitHeight > 0

  Loader {
    id: loader
    active: root.isRegistered
    sourceComponent: root.registryComponent
    anchors.fill: parent

    onLoaded: {
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
