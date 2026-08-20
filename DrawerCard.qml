import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Ui
import "DrawerLogic.js" as Logic

Rectangle {
  id: root

  property var host: null
  property var groupData: null
  property string fontFamily: Style.font.family
  property color foreground: Color.foreground
  property color accent: Color.accent

  signal editClicked()
  signal deleteClicked()

  readonly property color colBorder: Style.normalBorderFor(foreground, accent)
  readonly property color colCardBg: Style.normalFillFor(foreground, accent)
  readonly property var pluginRegistry: host && host.bar && host.bar.shell ? host.bar.shell.pluginRegistry : null

  Layout.fillWidth: true
  implicitHeight: cardLayout.implicitHeight + Style.space(20)
  radius: Style.cornerRadius
  color: cardMouse.containsMouse ? Util.alpha(accent, 0.08) : Util.alpha(foreground, 0.04)
  border.color: cardMouse.containsMouse ? Util.alpha(accent, 0.45) : Util.alpha(colBorder, 0.3)
  border.width: 1

  Behavior on color { ColorAnimation { duration: 150 } }
  Behavior on border.color { ColorAnimation { duration: 150 } }

  MouseArea {
    id: cardMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.editClicked()
  }

  ColumnLayout {
    id: cardLayout
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Style.space(10)
    spacing: Style.space(8)

    // Row 1: Icon, Title & Right-Aligned Actions
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.space(8)

      // Group Icon Badge
      Rectangle {
        width: Style.space(34)
        height: Style.space(34)
        radius: Style.cornerRadius
        color: Util.alpha(root.accent, 0.18)
        border.color: Util.alpha(root.accent, 0.55)
        border.width: 1

        Text {
          anchors.centerIn: parent
          text: root.groupData ? (root.groupData.icon || "󰏖") : "󰏖"
          font.family: root.fontFamily
          font.pixelSize: Style.font.heading
          color: root.accent
        }
      }

      // Group Title & Items count
      RowLayout {
        spacing: Style.space(6)

        Text {
          text: root.groupData ? (root.groupData.name || "Untitled Group") : "Untitled Group"
          font.family: root.fontFamily
          font.pixelSize: Style.font.subtitle
          font.bold: true
          color: root.foreground
          elide: Text.ElideRight
        }

        // Plugins count pill
        Rectangle {
          height: Style.space(16)
          width: countText.implicitWidth + Style.space(10)
          radius: Style.cornerRadius
          color: Util.alpha(root.foreground, 0.08)
          border.color: Util.alpha(root.foreground, 0.2)
          border.width: 1

          Text {
            id: countText
            anchors.centerIn: parent
            text: (root.groupData && root.groupData.plugins ? root.groupData.plugins.length : 0) + " items"
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            color: Qt.darker(root.foreground, 1.25)
          }
        }

        // Position pill
        Rectangle {
          height: Style.space(16)
          width: posText.implicitWidth + Style.space(10)
          radius: Style.cornerRadius
          color: Util.alpha(root.accent, 0.12)
          border.color: Util.alpha(root.accent, 0.35)
          border.width: 1

          Text {
            id: posText
            anchors.centerIn: parent
            text: {
              var pos = root.groupData ? (root.groupData.position || "right") : "right"
              return pos.charAt(0).toUpperCase() + pos.slice(1)
            }
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            color: root.accent
          }
        }

        // Direction pill
        Rectangle {
          height: Style.space(16)
          width: dirText.implicitWidth + Style.space(10)
          radius: Style.cornerRadius
          color: Util.alpha(root.foreground, 0.08)
          border.color: Util.alpha(root.foreground, 0.2)
          border.width: 1

          Text {
            id: dirText
            anchors.centerIn: parent
            text: (root.groupData && root.groupData.direction === "left") ? "Slide Left 󰁍" : "Slide Right 󰁔"
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            color: Qt.darker(root.foreground, 1.25)
          }
        }
      }

      // Spacer pushing Edit & Delete to the right side
      Item {
        Layout.fillWidth: true
      }

      // Action Buttons: Edit & Delete (Right-aligned)
      RowLayout {
        spacing: Style.space(4)

        // Edit Button
        Rectangle {
          width: Style.space(28)
          height: Style.space(28)
          radius: Style.cornerRadius
          color: editHover.containsMouse ? Util.alpha(root.accent, 0.25) : Util.alpha(Color.background, 0.4)
          border.color: editHover.containsMouse ? root.accent : Util.alpha(root.colBorder, 0.4)
          border.width: 1

          Text {
            anchors.centerIn: parent
            text: "󰏫"
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            color: editHover.containsMouse ? root.accent : Qt.darker(root.foreground, 1.3)
          }

          MouseArea {
            id: editHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.editClicked()
          }
        }

        // Delete Button
        Rectangle {
          width: Style.space(28)
          height: Style.space(28)
          radius: Style.cornerRadius
          color: deleteHover.containsMouse ? Util.alpha("#e06c75", 0.25) : Util.alpha(Color.background, 0.4)
          border.color: deleteHover.containsMouse ? "#e06c75" : Util.alpha(root.colBorder, 0.4)
          border.width: 1

          Text {
            anchors.centerIn: parent
            text: "󰆴"
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            color: deleteHover.containsMouse ? "#e06c75" : Qt.darker(root.foreground, 1.4)
          }

          MouseArea {
            id: deleteHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.deleteClicked()
          }
        }
      }
    }

    // Row 2: Assigned Plugin Tags Preview
    Flow {
      Layout.fillWidth: true
      spacing: Style.space(4)
      visible: root.groupData && root.groupData.plugins && root.groupData.plugins.length > 0

      Repeater {
        model: root.groupData ? root.groupData.plugins : []

        delegate: Rectangle {
          readonly property var meta: Logic.findPluginMeta(modelData, root.pluginRegistry)
          height: Style.space(20)
          width: tagRow.implicitWidth + Style.space(10)
          radius: Style.cornerRadius
          color: Util.alpha(root.foreground, 0.06)
          border.color: Util.alpha(root.foreground, 0.15)
          border.width: 1

          RowLayout {
            id: tagRow
            anchors.centerIn: parent
            spacing: Style.space(4)

            // SVG Image or Font Glyph
            Item {
              width: Style.space(14)
              height: Style.space(14)

              Image {
                anchors.centerIn: parent
                source: meta.iconUrl || ""
                visible: meta.iconUrl && meta.iconUrl.length > 0
                width: Style.space(14)
                height: Style.space(14)
                sourceSize: Qt.size(14, 14)
                fillMode: Image.PreserveAspectFit
              }

              Text {
                anchors.centerIn: parent
                visible: !meta.iconUrl || meta.iconUrl.length === 0
                text: meta.icon || "󰏖"
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
                color: root.accent
              }
            }

            Text {
              text: meta.name
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              color: root.foreground
            }
          }
        }
      }
    }
  }
}
