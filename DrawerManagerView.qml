import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Ui
import "DrawerLogic.js" as Logic

Item {
  id: root

  property var host: null
  property var groupsList: host ? host.groupsList : []
  property string currentView: "list" // "list" | "editor" | "settings" | "delete_confirm"
  property var editingGroup: null
  property var deletingGroup: null

  readonly property color colForeground: Color.foreground
  readonly property color colAccent: Color.accent
  readonly property color colDim: Qt.darker(Color.foreground, 1.4)
  readonly property color colBorder: Style.normalBorderFor(Color.foreground, Color.accent)
  readonly property color colCardBg: Style.normalFillFor(Color.foreground, Color.accent)
  readonly property string fontFamily: host && host.bar ? host.bar.fontFamily : Style.font.family
  readonly property string activeDisplayMode: host ? (host.displayMode || "icon") : "icon"

  implicitWidth: Style.space(420)
  implicitHeight: Style.space(510)

  ColumnLayout {
    anchors.fill: parent
    spacing: Style.space(8)

    // ------------------------------------------------------------- Header with Dynamic Theme Styling
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: Style.space(48)
      radius: Style.cornerRadius
      clip: true
      color: Util.alpha(colAccent, 0.08)
      border.color: Util.alpha(colBorder, 0.25)
      border.width: 1

      // Header Row Content
      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Style.space(8)
        anchors.rightMargin: Style.space(8)
        spacing: Style.space(8)

        // Drawer Icon Badge
        Rectangle {
          width: Style.space(32)
          height: Style.space(32)
          radius: Style.cornerRadius
          color: Util.alpha(colAccent, 0.2)
          border.color: Util.alpha(colAccent, 0.6)
          border.width: 1

          Text {
            anchors.centerIn: parent
            text: "󰏖"
            font.family: root.fontFamily
            font.pixelSize: Style.font.heading
            color: colAccent
          }
        }

        // Title and Subtitle
        ColumnLayout {
          spacing: 0

          Text {
            text: "OmaDrawer"
            font.family: root.fontFamily
            font.pixelSize: Style.font.subtitle
            font.bold: true
            color: colForeground
          }

          Text {
            text: root.currentView === "settings"
              ? "Preferences"
              : (root.groupsList.length + " " + (root.groupsList.length === 1 ? "group" : "groups") + " configured")
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            color: colDim
          }
        }

        Item { Layout.fillWidth: true }

        // Settings Button (Top-Right)
        Rectangle {
          width: Style.space(28)
          height: Style.space(28)
          radius: Style.cornerRadius
          color: root.currentView === "settings"
            ? Util.alpha(colAccent, 0.35)
            : (settingsHover.containsMouse ? Util.alpha(colForeground, 0.15) : Util.alpha(colForeground, 0.06))
          border.color: root.currentView === "settings" ? colAccent : (settingsHover.containsMouse ? colBorder : "transparent")
          border.width: 1

          Text {
            anchors.centerIn: parent
            text: "󰒓"
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            color: root.currentView === "settings" ? colAccent : (settingsHover.containsMouse ? colForeground : colDim)
          }

          MouseArea {
            id: settingsHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (root.currentView === "settings") {
                root.currentView = "list"
              } else {
                root.currentView = "settings"
              }
            }
          }
        }

        // Close Button
        Rectangle {
          width: Style.space(28)
          height: Style.space(28)
          radius: Style.cornerRadius
          color: closeHover.containsMouse ? Util.alpha(colForeground, 0.15) : Util.alpha(colForeground, 0.06)
          border.color: closeHover.containsMouse ? colBorder : "transparent"
          border.width: 1

          Text {
            anchors.centerIn: parent
            text: "✕"
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            color: closeHover.containsMouse ? colForeground : colDim
          }

          MouseArea {
            id: closeHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (host && host.close) host.close()
            }
          }
        }
      }
    }

    // ------------------------------------------------------------- Body Switcher
    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true

      // 1. MAIN LIST VIEW
      ColumnLayout {
        anchors.fill: parent
        visible: root.currentView === "list"
        spacing: Style.space(8)

        // Section header
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(6)

          Text {
            text: "PLUGIN GROUPS"
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            color: Qt.darker(colForeground, 1.4)
          }

          Item { Layout.fillWidth: true }
        }

        // Scrollable Groups List
        Flickable {
          Layout.fillWidth: true
          Layout.fillHeight: true
          contentHeight: groupsColumn.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds

          ColumnLayout {
            id: groupsColumn
            width: parent.width
            spacing: Style.space(8)

            // Empty state if 0 groups
            Rectangle {
              visible: root.groupsList.length === 0
              Layout.fillWidth: true
              implicitHeight: Style.space(160)
              radius: Style.cornerRadius
              color: Util.alpha(colForeground, 0.03)
              border.color: Util.alpha(colBorder, 0.25)
              border.width: 1

              ColumnLayout {
                anchors.centerIn: parent
                spacing: Style.space(8)

                Rectangle {
                  Layout.alignment: Qt.AlignHCenter
                  width: Style.space(42)
                  height: Style.space(42)
                  radius: Style.cornerRadius
                  color: Util.alpha(colAccent, 0.15)
                  border.color: Util.alpha(colAccent, 0.4)
                  border.width: 1

                  Text {
                    anchors.centerIn: parent
                    text: "󰏖"
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.display
                    color: colAccent
                  }
                }

                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: "No Drawer Groups Yet"
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.subtitle
                  font.bold: true
                  color: colForeground
                }

                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: "Click 'Add Group' below to bundle your top bar plugins."
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.caption
                  color: colDim
                }
              }
            }

            // Groups repeater
            Repeater {
              model: root.groupsList

              delegate: DrawerCard {
                host: root.host
                groupData: modelData
                fontFamily: root.fontFamily
                foreground: root.colForeground
                accent: root.colAccent
                onEditClicked: {
                  root.editingGroup = modelData
                  root.currentView = "editor"
                }
                onDeleteClicked: {
                  root.deletingGroup = modelData
                  root.currentView = "delete_confirm"
                }
              }
            }
          }
        }

        // Bottom Action Bar: [ + Add Group ]
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: Style.space(38)
          radius: Style.cornerRadius
          color: addHover.containsMouse ? Util.alpha(colAccent, 0.22) : Util.alpha(colAccent, 0.12)
          border.color: addHover.containsMouse ? colAccent : Util.alpha(colAccent, 0.5)
          border.width: 1

          Behavior on color { ColorAnimation { duration: 150 } }
          Behavior on border.color { ColorAnimation { duration: 150 } }

          RowLayout {
            anchors.centerIn: parent
            spacing: Style.space(6)

            Text {
              text: "󰐕"
              font.family: root.fontFamily
              font.pixelSize: Style.font.subtitle
              font.bold: true
              color: colAccent
            }

            Text {
              text: "Add Group"
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
              color: colForeground
            }
          }

          MouseArea {
            id: addHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.editingGroup = null
              root.currentView = "editor"
            }
          }
        }
      }

      // 2. SETTINGS VIEW (Display Mode Toggle)
      ColumnLayout {
        anchors.fill: parent
        visible: root.currentView === "settings"
        spacing: Style.space(12)

        // Settings Header: [‹ Back] [Title]
        RowLayout {
          Layout.fillWidth: true
          spacing: Style.space(8)

          Rectangle {
            width: Style.space(28)
            height: Style.space(28)
            radius: Style.cornerRadius
            color: setBackHover.containsMouse ? Util.alpha(root.colForeground, 0.15) : Util.alpha(root.colForeground, 0.06)
            border.color: Util.alpha(root.colBorder, 0.3)
            border.width: 1

            Text {
              anchors.centerIn: parent
              text: "‹"
              font.family: root.fontFamily
              font.pixelSize: Style.font.heading
              color: root.colForeground
            }

            MouseArea {
              id: setBackHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.currentView = "list"
            }
          }

          Text {
            text: "Drawer Preferences"
            font.family: root.fontFamily
            font.pixelSize: Style.font.subtitle
            font.bold: true
            color: root.colForeground
            Layout.fillWidth: true
          }
        }

        // Section: Top Bar Display Mode Toggle
        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.space(8)

          Text {
            text: "TOP BAR GROUP DISPLAY"
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            color: Qt.darker(root.colForeground, 1.4)
          }

          // 3-Way Segmented Slider / Toggle Control
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: Style.space(40)
            radius: Style.cornerRadius
            color: Util.alpha(root.colForeground, 0.05)
            border.color: Util.alpha(root.colBorder, 0.3)
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.margins: Style.space(3)
              spacing: Style.space(3)

              // Option 1: Icon Only
              Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Style.cornerRadius - 1
                color: root.activeDisplayMode === "icon" 
                  ? root.colAccent 
                  : (iconOnlyH.containsMouse ? Util.alpha(root.colForeground, 0.1) : "transparent")

                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                  anchors.centerIn: parent
                  spacing: Style.space(5)

                  Text {
                    text: "󰀻"
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    color: root.activeDisplayMode === "icon" ? "#12131a" : root.colForeground
                  }

                  Text {
                    text: "Icon"
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: root.activeDisplayMode === "icon"
                    color: root.activeDisplayMode === "icon" ? "#12131a" : root.colForeground
                  }
                }

                MouseArea {
                  id: iconOnlyH
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (host && host.updateSetting) host.updateSetting("displayMode", "icon")
                  }
                }
              }

              // Option 2: Name Only
              Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Style.cornerRadius - 1
                color: root.activeDisplayMode === "name" 
                  ? root.colAccent 
                  : (nameOnlyH.containsMouse ? Util.alpha(root.colForeground, 0.1) : "transparent")

                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                  anchors.centerIn: parent
                  spacing: Style.space(5)

                  Text {
                    text: "󰀬"
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    color: root.activeDisplayMode === "name" ? "#12131a" : root.colForeground
                  }

                  Text {
                    text: "Name"
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: root.activeDisplayMode === "name"
                    color: root.activeDisplayMode === "name" ? "#12131a" : root.colForeground
                  }
                }

                MouseArea {
                  id: nameOnlyH
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (host && host.updateSetting) host.updateSetting("displayMode", "name")
                  }
                }
              }

              // Option 3: Both Icon & Name
              Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Style.cornerRadius - 1
                color: root.activeDisplayMode === "both" 
                  ? root.colAccent 
                  : (bothH.containsMouse ? Util.alpha(root.colForeground, 0.1) : "transparent")

                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                  anchors.centerIn: parent
                  spacing: Style.space(5)

                  Text {
                    text: "󰍜"
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    color: root.activeDisplayMode === "both" ? "#12131a" : root.colForeground
                  }

                  Text {
                    text: "Both"
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: root.activeDisplayMode === "both"
                    color: root.activeDisplayMode === "both" ? "#12131a" : root.colForeground
                  }
                }

                MouseArea {
                  id: bothH
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (host && host.updateSetting) host.updateSetting("displayMode", "both")
                  }
                }
              }
            }
          }

          // Descriptive Helper Text
          Text {
            text: {
              if (root.activeDisplayMode === "name") return "Top bar shows only the group name (e.g. Games)."
              if (root.activeDisplayMode === "both") return "Top bar shows both the icon and group name (e.g. 󰊖 Games)."
              return "Top bar shows only the group icon (e.g. 󰊖)."
            }
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            color: Qt.darker(root.colForeground, 1.45)
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
          }
        }

        Item { Layout.fillHeight: true }

        // Done Button
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: Style.space(36)
          radius: Style.cornerRadius
          color: doneHover.containsMouse ? root.colAccent : Util.alpha(root.colAccent, 0.85)
          border.color: root.colAccent
          border.width: 1

          Text {
            anchors.centerIn: parent
            text: "Done"
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.bold: true
            color: "#12131a"
          }

          MouseArea {
            id: doneHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.currentView = "list"
          }
        }
      }

      // 3. ADD / EDIT GROUP EDITOR VIEW
      GroupEditor {
        anchors.fill: parent
        visible: root.currentView === "editor"
        host: root.host
        initialGroup: root.editingGroup
        fontFamily: root.fontFamily
        foreground: root.colForeground
        accent: root.colAccent
        onSaveGroup: function(groupData) {
          if (host && host.saveGroup) {
            host.saveGroup(groupData)
          }
          root.currentView = "list"
        }
        onCancel: {
          root.currentView = "list"
        }
      }

      // 4. DELETE CONFIRMATION VIEW
      Rectangle {
        anchors.fill: parent
        visible: root.currentView === "delete_confirm"
        radius: Style.cornerRadius
        color: Util.alpha(Color.background, 0.95)
        border.color: Util.alpha(colBorder, 0.4)
        border.width: 1

        ColumnLayout {
          anchors.centerIn: parent
          width: parent.width - Style.space(40)
          spacing: Style.space(12)

          Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: Style.space(44)
            height: Style.space(44)
            radius: Style.cornerRadius
            color: Util.alpha("#e06c75", 0.2)
            border.color: Util.alpha("#e06c75", 0.6)
            border.width: 1

            Text {
              anchors.centerIn: parent
              text: "󰆴"
              font.family: root.fontFamily
              font.pixelSize: Style.font.display
              color: "#e06c75"
            }
          }

          Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Delete Drawer Group?"
            font.family: root.fontFamily
            font.pixelSize: Style.font.subtitle
            font.bold: true
            color: colForeground
          }

          Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: "Are you sure you want to delete '" + (root.deletingGroup ? root.deletingGroup.name : "") + "'?\nPlugins will return to your top bar."
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            color: colDim
          }

          RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Style.space(12)

            Rectangle {
              Layout.preferredWidth: Style.space(100)
              Layout.preferredHeight: Style.space(32)
              radius: Style.cornerRadius
              color: delCancelHover.containsMouse ? Util.alpha(colForeground, 0.12) : Util.alpha(colForeground, 0.05)
              border.color: Util.alpha(colBorder, 0.4)
              border.width: 1

              Text {
                anchors.centerIn: parent
                text: "Cancel"
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                color: colForeground
              }

              MouseArea {
                id: delCancelHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.currentView = "list"
              }
            }

            Rectangle {
              Layout.preferredWidth: Style.space(110)
              Layout.preferredHeight: Style.space(32)
              radius: Style.cornerRadius
              color: delConfirmHover.containsMouse ? "#e06c75" : Util.alpha("#e06c75", 0.85)
              border.color: "#e06c75"
              border.width: 1

              Text {
                anchors.centerIn: parent
                text: "Delete"
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                font.bold: true
                color: "#ffffff"
              }

              MouseArea {
                id: delConfirmHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (root.deletingGroup && host && host.deleteGroup) {
                    host.deleteGroup(root.deletingGroup.id)
                  }
                  root.deletingGroup = null
                  root.currentView = "list"
                }
              }
            }
          }
        }
      }
    }
  }
}
