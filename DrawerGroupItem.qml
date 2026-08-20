import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Ui

Item {
  id: root

  property var groupData: null
  property var bar: null
  property bool expanded: false

  signal toggleExpanded()
  signal openManager()

  readonly property color colAccent: Color.accent
  readonly property var pluginsList: (groupData && groupData.plugins) ? groupData.plugins : []

  implicitWidth: groupRow.implicitWidth
  implicitHeight: groupRow.implicitHeight
  width: implicitWidth
  height: implicitHeight

  Row {
    id: groupRow
    spacing: 0
    anchors.verticalCenter: parent.verticalCenter

    // Drawer Group Toggle Button on Top Bar
    WidgetButton {
      id: groupButton
      bar: root.bar
      text: (root.groupData ? (root.groupData.icon || "󰏖") : "󰏖")
      active: root.expanded
      useActiveColor: true
      activeColor: root.colAccent
      tooltipText: (root.groupData ? root.groupData.name : "Drawer Group") + (root.expanded ? " (Expanded - click to collapse)" : " (Collapsed - click to expand)")

      onPressed: function(buttonCode) {
        if (buttonCode === Qt.RightButton) {
          root.openManager()
        } else {
          root.toggleExpanded()
        }
      }
    }

    // Expanded Plugins Row
    Row {
      id: pluginsContainer
      visible: root.expanded
      opacity: root.expanded ? 1.0 : 0.0
      spacing: 0
      anchors.verticalCenter: parent.verticalCenter

      Behavior on opacity {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
      }

      Repeater {
        model: root.pluginsList

        DrawerPluginSlot {
          required property var modelData
          pluginId: String(modelData)
          bar: root.bar
        }
      }
    }
  }
}
