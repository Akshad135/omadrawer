import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Ui
import "DrawerLogic.js" as Logic

Rectangle {
  id: root

  property var host: null
  property var initialGroup: null
  property string fontFamily: Style.font.family
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string viewMode: "editor" // "editor" | "picker"

  // Form State
  property string formId: ""
  property string formName: ""
  property string formIcon: "󰏖"
  property string formPosition: host ? host.currentRegion : "right"
  property var selectedPluginIds: []

  readonly property var otherGroupsPluginMap: {
    var map = {}
    if (!host || !host.groupsList) return map
    for (var i = 0; i < host.groupsList.length; i++) {
      var g = host.groupsList[i]
      if (g && g.id !== formId && Array.isArray(g.plugins)) {
        for (var j = 0; j < g.plugins.length; j++) {
          map[g.plugins[j]] = true
        }
      }
    }
    return map
  }

  readonly property var activeBarPluginIds: {
    var ids = []
    var seen = {}

    function addId(id) {
      if (!id || typeof id !== "string") return
      id = id.trim()
      if (id === "" || id === "akshad.omadrawer" || seen[id]) return
      seen[id] = true
      ids.push(id)
    }

    // 1. Current group's plugins (if editing an existing group)
    if (initialGroup && Array.isArray(initialGroup.plugins)) {
      for (var i = 0; i < initialGroup.plugins.length; i++) {
        addId(initialGroup.plugins[i])
      }
    }

    // 2. Plugins currently present on the top bar layout (left, center, right)
    var barLayout = null
    if (host && host.bar) {
      if (host.bar.barConfig && host.bar.barConfig.layout) {
        barLayout = host.bar.barConfig.layout
      } else if (host.bar.shell && host.bar.shell.shellConfig && host.bar.shell.shellConfig.bar && host.bar.shell.shellConfig.bar.layout) {
        barLayout = host.bar.shell.shellConfig.bar.layout
      }
    }

    if (barLayout) {
      var sections = ["left", "center", "right"]
      for (var s = 0; s < sections.length; s++) {
        var secList = barLayout[sections[s]]
        if (Array.isArray(secList)) {
          for (var j = 0; j < secList.length; j++) {
            var entry = secList[j]
            var pid = typeof entry === "string" ? entry : (entry && entry.id ? entry.id : "")
            addId(pid)
          }
        }
      }
    }

    return ids
  }

  readonly property var availablePlugins: {
    var result = []
    var ids = activeBarPluginIds

    // Disabled plugins map
    var disabledMap = {}
    if (host && host.bar && host.bar.shell && host.bar.shell.shellConfig && Array.isArray(host.bar.shell.shellConfig.disabledPlugins)) {
      var dList = host.bar.shell.shellConfig.disabledPlugins
      for (var d = 0; d < dList.length; d++) {
        disabledMap[dList[d]] = true
      }
    }

    for (var i = 0; i < ids.length; i++) {
      var id = ids[i]
      if (disabledMap[id]) continue
      if (otherGroupsPluginMap[id]) continue

      var meta = Logic.findPluginMeta(id)
      result.push(meta)
    }

    return result
  }

  signal saveGroup(var groupData)
  signal cancel()

  readonly property color colBorder: Style.normalBorderFor(foreground, accent)
  readonly property bool isEditing: formId !== ""

  function loadGroup(group) {
    if (group) {
      formId = group.id || ""
      formName = group.name || ""
      formIcon = group.icon || "󰏖"
      formPosition = group.position || (host ? host.currentRegion : "right")
      selectedPluginIds = group.plugins ? group.plugins.slice() : []
    } else {
      formId = ""
      formName = ""
      formIcon = "󰏖"
      formPosition = host ? host.currentRegion : "right"
      selectedPluginIds = []
    }
    viewMode = "editor"
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

  function movePluginUp(index) {
    if (index <= 0 || index >= selectedPluginIds.length) return
    var list = selectedPluginIds.slice()
    var temp = list[index - 1]
    list[index - 1] = list[index]
    list[index] = temp
    selectedPluginIds = list
  }

  function movePluginDown(index) {
    if (index < 0 || index >= selectedPluginIds.length - 1) return
    var list = selectedPluginIds.slice()
    var temp = list[index + 1]
    list[index + 1] = list[index]
    list[index] = temp
    selectedPluginIds = list
  }

  function submit() {
    if (formName.trim().length === 0) return
    var saved = {
      id: formId ? formId : Logic.generateGroupId(),
      name: formName.trim(),
      icon: formIcon.trim() || "󰏖",
      position: formPosition || "right",
      description: "",
      enabled: true,
      plugins: selectedPluginIds
    }
    root.saveGroup(saved)
  }

  color: "transparent"

  // ------------------------------------------------------------- 1. MAIN GROUP EDITOR VIEW
  ColumnLayout {
    anchors.fill: parent
    visible: root.viewMode === "editor"
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
      contentHeight: formContent.implicitHeight + Style.space(12)
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
            placeholderText: "e.g. Media & Fun, System Tools"
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

        // Field 3: Group Top Bar Positioning (Left, Center, Right)
        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.space(6)

          Text {
            text: "TOP BAR POSITION"
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            font.bold: true
            color: Qt.darker(root.foreground, 1.4)
          }

          // Horizontal Segmented Toggle for Positioning
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: Style.space(38)
            radius: Style.cornerRadius
            color: Util.alpha(root.foreground, 0.05)
            border.color: Util.alpha(root.colBorder, 0.3)
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.margins: Style.space(3)
              spacing: Style.space(3)

              // Position: Left
              Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Style.cornerRadius - 1
                color: root.formPosition === "left" ? root.accent : (posLeftHover.containsMouse ? Util.alpha(root.foreground, 0.1) : "transparent")
                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                  anchors.centerIn: parent
                  spacing: Style.space(4)
                  Text {
                    text: "󰁍"
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    color: root.formPosition === "left" ? "#12131a" : root.foreground
                  }
                  Text {
                    text: "Left"
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: root.formPosition === "left"
                    color: root.formPosition === "left" ? "#12131a" : root.foreground
                  }
                }

                MouseArea {
                  id: posLeftHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.formPosition = "left"
                }
              }

              // Position: Center
              Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Style.cornerRadius - 1
                color: root.formPosition === "center" ? root.accent : (posCenterHover.containsMouse ? Util.alpha(root.foreground, 0.1) : "transparent")
                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                  anchors.centerIn: parent
                  spacing: Style.space(4)
                  Text {
                    text: "󰅀"
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    color: root.formPosition === "center" ? "#12131a" : root.foreground
                  }
                  Text {
                    text: "Center"
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: root.formPosition === "center"
                    color: root.formPosition === "center" ? "#12131a" : root.foreground
                  }
                }

                MouseArea {
                  id: posCenterHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.formPosition = "center"
                }
              }

              // Position: Right
              Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Style.cornerRadius - 1
                color: root.formPosition === "right" ? root.accent : (posRightHover.containsMouse ? Util.alpha(root.foreground, 0.1) : "transparent")
                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                  anchors.centerIn: parent
                  spacing: Style.space(4)
                  Text {
                    text: "󰁔"
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    color: root.formPosition === "right" ? "#12131a" : root.foreground
                  }
                  Text {
                    text: "Right"
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                    font.bold: root.formPosition === "right"
                    color: root.formPosition === "right" ? "#12131a" : root.foreground
                  }
                }

                MouseArea {
                  id: posRightHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.formPosition = "right"
                }
              }
            }
          }
        }

        // Field 4: Current Added Plugins List with Reordering
        ColumnLayout {
          Layout.fillWidth: true
          spacing: Style.space(6)

          RowLayout {
            Layout.fillWidth: true
            Text {
              text: "GROUP PLUGINS (" + root.selectedPluginIds.length + ")"
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
              color: Qt.darker(root.foreground, 1.4)
            }
            Item { Layout.fillWidth: true }
            Text {
              text: "Order: Top to Bottom"
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              color: Qt.darker(root.foreground, 1.5)
            }
          }

          // Empty State if no plugins assigned yet
          Rectangle {
            visible: root.selectedPluginIds.length === 0
            Layout.fillWidth: true
            implicitHeight: Style.space(56)
            radius: Style.cornerRadius
            color: Util.alpha(root.foreground, 0.03)
            border.color: Util.alpha(root.colBorder, 0.2)
            border.width: 1

            Text {
              anchors.centerIn: parent
              text: "No plugins added yet. Click 'Update Plugins' below."
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              color: Qt.darker(root.foreground, 1.4)
            }
          }

          // Ordered Plugins List
          Repeater {
            model: root.selectedPluginIds

            delegate: Rectangle {
              id: pluginItemDelegate
              readonly property var meta: Logic.findPluginMeta(modelData)
              readonly property int itemIndex: index
              Layout.fillWidth: true
              implicitHeight: Style.space(38)
              radius: Style.cornerRadius
              color: Util.alpha(root.foreground, 0.04)
              border.color: Util.alpha(root.colBorder, 0.25)
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Style.space(8)
                anchors.rightMargin: Style.space(8)
                spacing: Style.space(8)

                // Index Badge
                Rectangle {
                  width: Style.space(20)
                  height: Style.space(20)
                  radius: width / 2
                  color: Util.alpha(root.accent, 0.2)
                  border.color: Util.alpha(root.accent, 0.5)
                  border.width: 1

                  Text {
                    anchors.centerIn: parent
                    text: String(itemIndex + 1)
                    font.family: root.fontFamily
                    font.pixelSize: 10
                    font.bold: true
                    color: root.accent
                  }
                }

                // Plugin Icon
                Text {
                  text: meta.icon || "󰏖"
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  color: root.accent
                }

                // Plugin Name
                Text {
                  Layout.fillWidth: true
                  text: meta.name || modelData
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                  color: root.foreground
                  elide: Text.ElideRight
                }

                // Action: Move Up Button (▲)
                Rectangle {
                  width: Style.space(28)
                  height: Style.space(26)
                  radius: Style.cornerRadius
                  color: itemIndex > 0 
                    ? (upHover.containsMouse ? Util.alpha(root.accent, 0.3) : Util.alpha(root.foreground, 0.08))
                    : Util.alpha(root.foreground, 0.02)
                  border.color: itemIndex > 0 
                    ? (upHover.containsMouse ? root.accent : Util.alpha(root.colBorder, 0.3))
                    : "transparent"
                  border.width: 1
                  opacity: itemIndex > 0 ? 1.0 : 0.25

                  Text {
                    anchors.centerIn: parent
                    text: "▲"
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    color: itemIndex > 0 
                      ? (upHover.containsMouse ? root.accent : root.foreground)
                      : Qt.darker(root.foreground, 1.8)
                  }

                  MouseArea {
                    id: upHover
                    anchors.fill: parent
                    enabled: itemIndex > 0
                    hoverEnabled: true
                    cursorShape: itemIndex > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.movePluginUp(itemIndex)
                  }
                }

                // Action: Move Down Button (▼)
                Rectangle {
                  width: Style.space(28)
                  height: Style.space(26)
                  radius: Style.cornerRadius
                  color: itemIndex < root.selectedPluginIds.length - 1
                    ? (downHover.containsMouse ? Util.alpha(root.accent, 0.3) : Util.alpha(root.foreground, 0.08))
                    : Util.alpha(root.foreground, 0.02)
                  border.color: itemIndex < root.selectedPluginIds.length - 1
                    ? (downHover.containsMouse ? root.accent : Util.alpha(root.colBorder, 0.3))
                    : "transparent"
                  border.width: 1
                  opacity: itemIndex < root.selectedPluginIds.length - 1 ? 1.0 : 0.25

                  Text {
                    anchors.centerIn: parent
                    text: "▼"
                    font.family: root.fontFamily
                    font.pixelSize: 11
                    color: itemIndex < root.selectedPluginIds.length - 1
                      ? (downHover.containsMouse ? root.accent : root.foreground)
                      : Qt.darker(root.foreground, 1.8)
                  }

                  MouseArea {
                    id: downHover
                    anchors.fill: parent
                    enabled: itemIndex < root.selectedPluginIds.length - 1
                    hoverEnabled: true
                    cursorShape: itemIndex < root.selectedPluginIds.length - 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.movePluginDown(itemIndex)
                  }
                }
              }
            }
          }

          // "+ Update Plugins" Button
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: Style.space(36)
            radius: Style.cornerRadius
            color: updHover.containsMouse ? Util.alpha(root.accent, 0.18) : Util.alpha(root.accent, 0.08)
            border.color: updHover.containsMouse ? root.accent : Util.alpha(root.accent, 0.4)
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            RowLayout {
              anchors.centerIn: parent
              spacing: Style.space(6)

              Text {
                text: "󰐕"
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                font.bold: true
                color: root.accent
              }

              Text {
                text: root.selectedPluginIds.length === 0 ? "Add Plugins to Group" : "Update Plugins"
                font.family: root.fontFamily
                font.pixelSize: Style.font.body
                font.bold: true
                color: root.foreground
              }
            }

            MouseArea {
              id: updHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.viewMode = "picker"
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
          enabled: canSave
          hoverEnabled: true
          cursorShape: canSave ? Qt.PointingHandCursor : Qt.ArrowCursor
          onClicked: root.submit()
        }
      }
    }
  }

  // ------------------------------------------------------------- 2. PLUGIN SELECTION CHECKLIST VIEW
  ColumnLayout {
    anchors.fill: parent
    visible: root.viewMode === "picker"
    spacing: Style.space(8)

    // Picker Header: [‹ Back] [Title]
    RowLayout {
      Layout.fillWidth: true
      spacing: Style.space(8)

      Rectangle {
        width: Style.space(28)
        height: Style.space(28)
        radius: Style.cornerRadius
        color: pickerBackHover.containsMouse ? Util.alpha(root.foreground, 0.12) : Util.alpha(root.foreground, 0.05)
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
          id: pickerBackHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.viewMode = "editor"
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Text {
          text: "Select Plugins for Group"
          font.family: root.fontFamily
          font.pixelSize: Style.font.subtitle
          font.bold: true
          color: root.foreground
        }

        Text {
          text: root.selectedPluginIds.length + " selected (toggle to add/remove)"
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          color: root.accent
        }
      }
    }

    // Scrollable Checklist
    Flickable {
      Layout.fillWidth: true
      Layout.fillHeight: true
      contentHeight: pickerList.implicitHeight + Style.space(10)
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      ColumnLayout {
        id: pickerList
        width: parent.width
        spacing: Style.space(6)

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

            Behavior on color { ColorAnimation { duration: 100 } }
            Behavior on border.color { ColorAnimation { duration: 100 } }

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

              // Plugin Name & Category
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

    // Done Selecting Button
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: Style.space(34)
      radius: Style.cornerRadius
      color: donePickHover.containsMouse ? root.accent : Util.alpha(root.accent, 0.85)
      border.color: root.accent
      border.width: 1

      Text {
        anchors.centerIn: parent
        text: "Done Selecting (" + root.selectedPluginIds.length + " chosen)"
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.bold: true
        color: "#12131a"
      }

      MouseArea {
        id: donePickHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.viewMode = "editor"
      }
    }
  }
}
