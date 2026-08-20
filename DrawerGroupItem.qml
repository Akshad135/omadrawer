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
  property string slideDirection: "right" // "right" | "left"

  signal toggleExpanded()
  signal openManager()

  readonly property color colAccent: Color.accent
  readonly property var pluginsList: (groupData && groupData.plugins) ? groupData.plugins : []
  readonly property string effectiveDirection: (groupData && groupData.direction) ? groupData.direction : (slideDirection || "right")
  readonly property bool isSlideLeft: effectiveDirection === "left"

  implicitWidth: groupButton.implicitWidth + sliderArea.implicitWidth
  implicitHeight: Math.max(groupButton.implicitHeight, sliderArea.implicitHeight)
  width: implicitWidth
  height: implicitHeight

  Row {
    id: groupRow
    spacing: 0
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    layoutDirection: root.isSlideLeft ? Qt.RightToLeft : Qt.LeftToRight

    // 1. Group Icon Button on Top Bar
    WidgetButton {
      id: groupButton
      bar: root.bar
      text: root.groupData ? (root.groupData.icon || "󰏖") : "󰏖"
      active: root.expanded
      useActiveColor: true
      activeColor: root.colAccent
      tooltipText: (root.groupData ? root.groupData.name : "Drawer") + (root.expanded ? " (Click to close drawer)" : " (Click to open drawer)")

      onPressed: function(buttonCode) {
        if (buttonCode === Qt.RightButton) {
          root.openManager()
        } else {
          root.toggleExpanded()
        }
      }
    }

    // 2. Sliding Drawer Container
    Item {
      id: sliderArea
      clip: true
      implicitWidth: root.expanded ? pluginsBlock.implicitWidth : 0
      implicitHeight: Math.max(pluginsBlock.implicitHeight, groupButton.implicitHeight)
      width: implicitWidth
      height: implicitHeight

      Behavior on implicitWidth {
        NumberAnimation {
          duration: 200
          easing.type: Easing.OutCubic
        }
      }

      Row {
        id: pluginsBlock
        spacing: 0
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        layoutDirection: root.isSlideLeft ? Qt.RightToLeft : Qt.LeftToRight

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
}
