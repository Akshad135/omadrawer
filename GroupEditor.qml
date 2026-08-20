import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Ui
import "DrawerLogic.js" as Logic

Rectangle {
  id: root

  property var initialGroup: null
  property string fontFamily: Style.font.family
  property color foreground: Color.foreground
  property color accent: Color.accent
  property var availablePlugins: Logic.KNOWN_PLUGINS

  signal saveGroup(var groupData)
  signal cancel()

  // Form State
  property string formId: ""
  property string formName: ""
  property string formIcon: "󰏖"
  property string formDescription: ""
  property var selectedPluginIds: []

  readonly property color colBorder: Style.normalBorderFor(foreground, accent)
  readonly property bool isEditing: formId !== ""

  function loadGroup(group) {
    if (group) {
      formId = group.id || ""
      formName = group.name || ""
      formIcon = group.icon || "󰏖"
      formDescription = group.description || ""
      selectedPluginIds = group.plugins ? group.plugins.slice() : []
    } else {
      formId = ""
      formName = ""
      formIcon = "󰏖"
      formDescription = ""
      selectedPluginIds = []
    }
  }

  onInitialGroupChanged: loadGroup(initialGroup)
  Component.onCompleted: loadGroup(initialGroup)

  function isPluginSelected(pluginId) {
    return selectedPluginIds.indexOf(pluginId) !== -1
  }

  function togglePluginSelection(pluginId) {
    var list = selectedPluginIds.slice()
    var idx = list.indexOf(pluginId)
    if (idx !== -1) {
      list.splice(idx, 1)
    } else {
      list.push(pluginId)
    }
    selectedPluginIds = list
  }

  function submit() {
    if (formName.trim().length === 0) return
    var saved = {
      id: formId ? formId : Logic.generateGroupId(),
      name: formName.trim(),
      icon: formIcon.trim() || "󰏖",
      description: formDescription.trim(),
      enabled: true,
      plugins: selectedPluginIds
    }
    root.saveGroup(saved)
  }

  color: "transparent"

  ColumnLayout {
    anchors.fill: parent
    spacing: Style.space(8)

    // Form Header: [‹ Back] [Title]
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.space(8)

      Rectangle {
        width: Style.space(28)
        height: Style.space(28)
        radius: Style.cornerRadius
        color: backHover.containsMouse ? Util.alpha(root.foreground, 0.12) : Util.alpha(root.foreground, 0.05)
        border.color: Util.alpha(root.colBorder, 0.3)
        border.width: 1

        Text {
          anchors.centerIn: parent
          text: "‹"
          font.family: root.fontFamily
          font.pixelSize: Style.font.heading
          color: root.foreground
        }

        MouseArea {
          id: backHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.cancel()
        }
      }

      Text {
        text: root.isEditing ? "Edit Drawer Group" : "Create Drawer Group"
        font.family: root.fontFamily
        font.pixelSize: Style.font.subtitle
        font.bold: true
        color: root.foreground
        Layout.fillWidth: true
      }
    }

    // Scrollable Form Fields
    Flickable {
      Layout.fillWidth: true
      Layout.fillHeight: true
      contentHeight: formContent.implicitHeight + Style.space(10)
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      ColumnLayout {
        id: formContent
        width: parent.width
        spacing: Style.space(10)

        // Field 1: Group Name
        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.space(4)

          Text {
            text: "GROUP NAME"
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            color: Qt.darker(root.foreground, 1.4)
          }

          TextField {
            id: nameField
            Layout.fillWidth: true
            text: root.formName
            placeholderText: "e.g. Media & Entertainment, System Tools"
            foreground: root.foreground
            accent: root.accent
            onTextChanged: root.formName = text
          }
        }

        // Field 2: Group Icon Preset Selector
        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.space(4)

          RowLayout {
            Layout.fillWidth: true
            Text {
              text: "GROUP ICON"
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              color: Qt.darker(root.foreground, 1.4)
            }
            Item { Layout.fillWidth: true }
            Text {
              text: "Selected: " + root.formIcon
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              color: root.accent
            }
          }

          Flow {
            Layout.fillWidth: true
            spacing: Style.space(4)

            Repeater {
              model: Logic.PRESET_ICONS

              delegate: Rectangle {
                width: Style.space(30)
                height: Style.space(30)
                radius: Style.cornerRadius
                color: root.formIcon === modelData 
                  ? Util.alpha(root.accent, 0.35) 
                  : (iconHover.containsMouse ? Util.alpha(root.foreground, 0.1) : Util.alpha(root.foreground, 0.04))
                border.color: root.formIcon === modelData 
                  ? root.accent 
                  : (iconHover.containsMouse ? Util.alpha(root.accent, 0.5) : Util.alpha(root.colBorder, 0.25))
                border.width: 1

                Text {
                  anchors.centerIn: parent
                  text: modelData
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  color: root.formIcon === modelData ? root.accent : root.foreground
                }

                MouseArea {
                  id: iconHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.formIcon = modelData
                }
              }
            }
          }
        }

        // Field 3: Short Description
        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.space(4)

          Text {
            text: "DESCRIPTION (OPTIONAL)"
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            color: Qt.darker(root.foreground, 1.4)
          }

          TextField {
            id: descField
            Layout.fillWidth: true
            text: root.formDescription
            placeholderText: "e.g. Quick access to daily plugins"
            foreground: root.foreground
            accent: root.accent
            onTextChanged: root.formDescription = text
          }
        }

        // Field 4: Select Plugins to Include
        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.space(6)

          RowLayout {
            Layout.fillWidth: true
            Text {
              text: "ASSIGN PLUGINS (" + root.selectedPluginIds.length + " SELECTED)"
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              color: Qt.darker(root.foreground, 1.4)
            }
            Item { Layout.fillWidth: true }
          }

          Repeater {
            model: root.availablePlugins

            delegate: Rectangle {
              readonly property bool isSelected: root.isPluginSelected(modelData.id)
              Layout.fillWidth: true
              implicitHeight: Style.space(40)
              radius: Style.cornerRadius
              color: isSelected 
                ? Util.alpha(root.accent, 0.12) 
                : (pMouse.containsMouse ? Util.alpha(root.foreground, 0.07) : Util.alpha(root.foreground, 0.03))
              border.color: isSelected 
                ? Util.alpha(root.accent, 0.6) 
                : (pMouse.containsMouse ? Util.alpha(root.colBorder, 0.5) : Util.alpha(root.colBorder, 0.2))
              border.width: 1

              Behavior on color { ColorAnimation { duration: 120 } }
              Behavior on border.color { ColorAnimation { duration: 120 } }

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Style.space(8)
                anchors.rightMargin: Style.space(8)
                spacing: Style.space(8)

                // Checkbox / Indicator
                Rectangle {
                  width: Style.space(18)
                  height: Style.space(18)
                  radius: Style.cornerRadius
                  color: isSelected ? root.accent : "transparent"
                  border.color: isSelected ? root.accent : Qt.darker(root.foreground, 1.5)
                  border.width: 1.5

                  Text {
                    anchors.centerIn: parent
                    text: "✓"
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    font.bold: true
                    color: "#12131a"
                    visible: isSelected
                  }
                }

                // Plugin Icon
                Text {
                  text: modelData.icon || "󰏖"
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  color: isSelected ? root.accent : root.foreground
                }

                // Plugin Name & Desc
                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 0

                  Text {
                    text: modelData.name || modelData.id
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: isSelected
                    color: root.foreground
                  }

                  Text {
                    text: modelData.desc || modelData.category || ""
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    color: Qt.darker(root.foreground, 1.5)
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                  }
                }

                // Category Tag
                Rectangle {
                  height: Style.space(16)
                  width: catText.implicitWidth + Style.space(8)
                  radius: Style.cornerRadius
                  color: Util.alpha(root.foreground, 0.06)
                  border.color: Util.alpha(root.foreground, 0.15)
                  border.width: 1

                  Text {
                    id: catText
                    anchors.centerIn: parent
                    text: modelData.category || "Plugin"
                    font.family: root.fontFamily
                    font.pixelSize: 9
                    color: Qt.darker(root.foreground, 1.3)
                  }
                }
              }

              MouseArea {
                id: pMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.togglePluginSelection(modelData.id)
              }
            }
          }
        }
      }
    }

    // Bottom Action Bar: Cancel & Save Buttons
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.space(8)

      // Cancel Button
      Rectangle {
        Layout.preferredWidth: Style.space(90)
        Layout.preferredHeight: Style.space(34)
        radius: Style.cornerRadius
        color: cancelHover.containsMouse ? Util.alpha(root.foreground, 0.12) : Util.alpha(root.foreground, 0.05)
        border.color: Util.alpha(root.colBorder, 0.4)
        border.width: 1

        Text {
          anchors.centerIn: parent
          text: "Cancel"
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          color: root.foreground
        }

        MouseArea {
          id: cancelHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.cancel()
        }
      }

      // Save Group Button
      Rectangle {
        readonly property bool canSave: root.formName.trim().length > 0
        Layout.fillWidth: true
        Layout.preferredHeight: Style.space(34)
        radius: Style.cornerRadius
        color: canSave 
          ? (saveHover.containsMouse ? root.accent : Util.alpha(root.accent, 0.85)) 
          : Util.alpha(root.foreground, 0.08)
        border.color: canSave ? root.accent : "transparent"
        border.width: 1

        RowLayout {
          anchors.centerIn: parent
          spacing: Style.space(6)

          Text {
            text: "󰄬"
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            color: canSave ? "#12131a" : Qt.darker(root.foreground, 1.6)
          }

          Text {
            text: root.isEditing ? "Update Group" : "Save Group"
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.bold: true
            color: canSave ? "#12131a" : Qt.darker(root.foreground, 1.6)
          }
        }

        MouseArea {
          id: saveHover
          anchors.fill: parent
          enabled: parent.canSave
          hoverEnabled: true
          cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
          onClicked: root.submit()
        }
      }
    }
  }
}
