pragma ComponentBehavior: Bound
import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

Item {
  id: root
  property var pluginApi
  property var screen
  property bool active
  property string density: "full"
  property real s: 1
  property real widthBudget: 428

  readonly property var service: pluginApi && pluginApi.mainInstance ? pluginApi.mainInstance : null
  readonly property real pad: 14 * root.s
  readonly property real contentW: Math.max(240 * root.s, (root.widthBudget > 0 ? root.widthBudget : 428 * root.s) - root.pad * 2)
  property real customGrams: 4
  property bool quickAddExpanded: true
  property bool equivalentsExpanded: false
  property bool dessertExpanded: false
  property real equivalentWhiteGrams: 4
  readonly property real brownSugarRatio: {
    var settings = root.pluginApi && root.pluginApi.pluginSettings ? root.pluginApi.pluginSettings : null
    var value = settings ? Number(settings.brownSugarRatio) : 100
    return isFinite(value) && value > 0 ? Math.max(10, Math.min(400, value)) : 100
  }
  readonly property real steviaSweetness: {
    var settings = root.pluginApi && root.pluginApi.pluginSettings ? root.pluginApi.pluginSettings : null
    var value = settings ? Number(settings.steviaSweetness) : 200
    return isFinite(value) && value > 0 ? Math.max(1, Math.min(500, value)) : 200
  }
  readonly property real equivalentBrownGrams: Math.max(0, equivalentWhiteGrams) * brownSugarRatio / 100
  readonly property real equivalentSteviaGrams: steviaSweetness > 0 ? Math.max(0, equivalentWhiteGrams) / steviaSweetness : 0
  implicitWidth: root.contentW + root.pad * 2
  implicitHeight: body.implicitHeight

  function gramsText(value) {
    var grams = Number(value)
    if (!isFinite(grams) || grams <= 0) return "0 g"
    if (grams >= 10) return (Math.round(grams * 10) / 10) + " g"
    if (grams >= 1) return (Math.round(grams * 100) / 100) + " g"
    return (Math.round(grams * 1000) / 1000) + " g"
  }

  Component.onCompleted: {
    var white = root.pluginApi && root.pluginApi.pluginSettings ? Number(root.pluginApi.pluginSettings.whiteSugarGrams) : 4
    root.equivalentWhiteGrams = isFinite(white) && white > 0 ? white : 4
  }

  Column {
    id: body
    x: root.pad
    width: root.contentW
    spacing: 14 * root.s

    // ── Header card ─────────────────────────────────────────────────────
    Rectangle {
      width: parent.width
      height: 90 * root.s
      radius: 16 * root.s
      gradient: Gradient {
        GradientStop { position: 0.0; color: root.service && root.service.overGoal ? "#3d1a1f" : "#1e293b" }
        GradientStop { position: 1.0; color: root.service && root.service.overGoal ? "#2a1215" : "#0f172a" }
      }
      border.width: 1
      border.color: root.service && root.service.overGoal ? "#fa3b30" : "#334155"

      Column {
        anchors.centerIn: parent
        spacing: 2 * root.s

        Text {
          text: qsTr("Sweetener today")
          color: "#94a3b8"
          font.family: Theme.font
          font.pixelSize: 10 * root.s
          font.letterSpacing: 1.2 * root.s
        }

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 8 * root.s
          Text {
            text: root.service ? Number(root.service.todayGrams || 0).toFixed(1) : "—"
            color: root.service && root.service.overGoal ? "#fa3b30" : "#f1f5f9"
            font.family: Theme.font
            font.pixelSize: 36 * root.s
            font.bold: true
          }
          Text {
            text: "g"
            color: "#64748b"
            font.family: Theme.font
            font.pixelSize: 14 * root.s
            anchors.baseline: parent.baseline
            anchors.baselineOffset: 12 * root.s
          }
        }

        Text {
          text: root.service ? (root.service.overGoal
            ? qsTr("Over by " + Number((root.service.todayGrams || 0) - (root.service.dailyGoal || 25)).toFixed(1) + " g")
            : qsTr(Number((root.service.dailyGoal || 25) - (root.service.todayGrams || 0)).toFixed(1) + " g remaining")) : ""
          color: root.service && root.service.overGoal ? "#fca5a5" : "#4ade80"
          font.family: Theme.font
          font.pixelSize: 11 * root.s
          font.bold: true
        }
      }
    }

    // ── Progress bar ───────────────────────────────────────────────────
    Rectangle {
      width: parent.width
      height: 6 * root.s
      radius: 3 * root.s
      color: "#1e293b"
      border.color: "#334155"
      border.width: 1
      Rectangle {
        x: 1
        y: 1
        width: Math.max(0, parent.width - 2) * Math.min(1, root.service && (root.service.dailyGoal || 25) > 0 ? Number(root.service.todayGrams || 0) / Number(root.service.dailyGoal || 25) : 0)
        height: parent.height - 2
        radius: 14 * root.s
        gradient: Gradient {
          GradientStop { position: 0.0; color: root.service && root.service.overGoal ? "#ef4444" : "#22c55e" }
          GradientStop { position: 1.0; color: root.service && root.service.overGoal ? "#dc2626" : "#16a34a" }
        }
        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
      }
    }

    // ── Quick add ──────────────────────────────────────────────────────
    Rectangle {
      width: parent.width
      height: quickAddOuterColumn.implicitHeight
      radius: 14 * root.s
      color: "#1e293b"
      border.width: 1
      border.color: "#334155"

      Column {
        id: quickAddOuterColumn
        width: parent.width
        spacing: 0

        // Header row
        Item {
          width: parent.width
          height: 44 * root.s
          property real radius: 14 * root.s
          Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: quickHeader.containsMouse ? "#2d3a4f" : "transparent"
            Behavior on color { ColorAnimation { duration: 200 } }
          }
          Text {
            anchors.left: parent.left
            anchors.leftMargin: 16 * root.s
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("Quick add")
            color: "#e2e8f0"
            font.family: Theme.font
            font.pixelSize: 12 * root.s
            font.bold: true
            font.letterSpacing: 0.8 * root.s
          }
          Text {
            anchors.right: parent.right
            anchors.rightMargin: 16 * root.s
            anchors.verticalCenter: parent.verticalCenter
            text: root.quickAddExpanded ? "−" : "+"
            color: "#94a3b8"
            font.family: Theme.font
            font.pixelSize: 18 * root.s
            font.bold: true
          }
          MouseArea {
            id: quickHeader
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.quickAddExpanded = !root.quickAddExpanded
          }
        }

        // Quick add buttons
        Column {
          width: parent.width
          spacing: 8 * root.s
          visible: root.quickAddExpanded
          padding: 8 * root.s
          topPadding: 0
          bottomPadding: 12 * root.s

          Repeater {
            model: [
              { label: qsTr("Sugar (white)"), grams: root.pluginApi && root.pluginApi.pluginSettings ? Number(root.pluginApi.pluginSettings.whiteSugarGrams) : 4, color: "#f8fafc", icon: "◉" },
              { label: qsTr("Brown sugar"), grams: root.pluginApi && root.pluginApi.pluginSettings ? Number(root.pluginApi.pluginSettings.brownSugarGrams) : 4, color: "#fef3c7", icon: "◎" },
              { label: qsTr("Stevia"), grams: root.pluginApi && root.pluginApi.pluginSettings ? Number(root.pluginApi.pluginSettings.steviaGrams) : 1, color: "#dcfce7", icon: "✱" },
              { label: qsTr("Teaspoon sugar"), grams: 4, color: "#e0f2fe", icon: "🥄" }
            ]
            delegate: Item {
              required property var modelData
              width: parent.width
              height: 40 * root.s
              Rectangle {
                anchors.fill: parent
                radius: 10 * root.s
                color: addRowTap.containsMouse ? "#334155" : "#273148"
                border.width: 1
                border.color: "#3d4a5f"
                Behavior on color { ColorAnimation { duration: 180 } }
              }
              Text {
                anchors.left: parent.left
                anchors.leftMargin: 14 * root.s
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.icon + "  " + modelData.label
                color: "#e2e8f0"
                font.family: Theme.font
                font.pixelSize: 12 * root.s
              }
              Text {
                anchors.right: parent.right
                anchors.rightMargin: 14 * root.s
                anchors.verticalCenter: parent.verticalCenter
                text: "+" + modelData.grams + " g"
                color: "#94a3b8"
                font.family: Theme.font
                font.pixelSize: 11 * root.s
                font.bold: true
              }
              MouseArea {
                id: addRowTap
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.service && root.service.addSugar(modelData.grams, modelData.label)
              }
            }
          }

          // Custom amount
          Item {
            width: parent.width
            height: 40 * root.s
            Rectangle {
              x: 0
              width: parent.width - 108 * root.s - 6 * root.s
              height: parent.height
              radius: 10 * root.s
              color: "#0f172a"
              border.width: 1
              border.color: "#334155"
              TextInput {
                id: customField
                anchors.fill: parent
                anchors.leftMargin: 12 * root.s
                anchors.rightMargin: 12 * root.s
                verticalAlignment: TextInput.AlignVCenter
                text: String(root.customGrams)
                color: "#f1f5f9"
                font.family: Theme.font
                font.pixelSize: 13 * root.s
                inputMethodHints: Qt.ImhDigitsOnly
                validator: DoubleValidator { bottom: 0.1; top: 200; decimals: 1 }
                onTextChanged: {
                  var amount = Number(text)
                  if (isFinite(amount) && amount > 0 && amount <= 200) root.customGrams = amount
                }
              }
            }
            Rectangle {
              x: parent.width - 108 * root.s
              width: 108 * root.s
              height: parent.height
              radius: 10 * root.s
              gradient: Gradient {
                GradientStop { position: 0.0; color: customTap.containsMouse ? "#4ade80" : "#22c55e" }
                GradientStop { position: 1.0; color: customTap.containsMouse ? "#16a34a" : "#15803d" }
              }
              Text {
                anchors.centerIn: parent
                text: qsTr("Add " + root.gramsText(root.customGrams))
                color: "#0f172a"
                font.family: Theme.font
                font.pixelSize: 11 * root.s
                font.bold: true
              }
              MouseArea {
                id: customTap
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.service && root.service.addSugar(root.customGrams, qsTr("Custom sugar"))
              }
            }
          }
        }
      }
    }

    // ── Equivalents ────────────────────────────────────────────────────
    Rectangle {
      width: parent.width
      height: equivOuterColumn.implicitHeight
      radius: 14 * root.s
      color: "#1e293b"
      border.width: 1
      border.color: "#334155"

      Column {
        id: equivOuterColumn
        width: parent.width
        spacing: 0

        Item {
          width: parent.width
          height: 44 * root.s
          Rectangle {
            anchors.fill: parent
            radius: 14 * root.s
            color: equivHeader.containsMouse ? "#2d3a4f" : "transparent"
            Behavior on color { ColorAnimation { duration: 200 } }
          }
          Text {
            anchors.left: parent.left
            anchors.leftMargin: 16 * root.s
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("Sugar equivalents")
            color: "#e2e8f0"
            font.family: Theme.font
            font.pixelSize: 12 * root.s
            font.bold: true
            font.letterSpacing: 0.8 * root.s
          }
          Text {
            anchors.right: parent.right
            anchors.rightMargin: 38 * root.s
            anchors.verticalCenter: parent.verticalCenter
            text: root.gramsText(root.equivalentWhiteGrams) + " white"
            color: "#94a3b8"
            font.family: Theme.font
            font.pixelSize: 11 * root.s
          }
          Text {
            anchors.right: parent.right
            anchors.rightMargin: 16 * root.s
            anchors.verticalCenter: parent.verticalCenter
            text: root.equivalentsExpanded ? "−" : "+"
            color: "#94a3b8"
            font.family: Theme.font
            font.pixelSize: 18 * root.s
            font.bold: true
          }
          MouseArea {
            id: equivHeader
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.equivalentsExpanded = !root.equivalentsExpanded
          }
        }

        Column {
          width: parent.width
          spacing: 8 * root.s
          visible: root.equivalentsExpanded
          padding: 8 * root.s
          topPadding: 0
          bottomPadding: 12 * root.s

          Item {
            width: parent.width
            height: 34 * root.s
            Text {
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              text: qsTr("White sugar grams")
              color: "#94a3b8"
              font.family: Theme.font
              font.pixelSize: 11 * root.s
            }
            Rectangle {
              anchors.right: parent.right
              width: 110 * root.s
              height: parent.height
              radius: 8 * root.s
              color: "#0f172a"
              border.width: 1
              border.color: "#334155"
              TextInput {
                id: equivalentField
                anchors.fill: parent
                anchors.leftMargin: 10 * root.s
                anchors.rightMargin: 10 * root.s
                verticalAlignment: TextInput.AlignVCenter
                text: String(root.equivalentWhiteGrams)
                color: "#f1f5f9"
                font.family: Theme.font
                font.pixelSize: 12 * root.s
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                validator: DoubleValidator { bottom: 0; top: 500; decimals: 2 }
                onTextChanged: {
                  var amount = Number(text)
                  if (isFinite(amount) && amount >= 0 && amount <= 500) root.equivalentWhiteGrams = amount
                }
              }
            }
          }

          Repeater {
            model: [
              { label: qsTr("Brown sugar"), grams: root.equivalentBrownGrams },
              { label: qsTr("Stevia"), grams: root.equivalentSteviaGrams },
            ]
            delegate: Item {
              required property var modelData
              width: parent.width
              height: 34 * root.s
              Rectangle {
                anchors.fill: parent
                radius: 8 * root.s
                color: "#273148"
                border.width: 1
                border.color: "#3d4a5f"
              }
              Text {
                anchors.left: parent.left
                anchors.leftMargin: 12 * root.s
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.label
                color: "#cbd5e1"
                font.family: Theme.font
                font.pixelSize: 12 * root.s
              }
              Text {
                anchors.right: parent.right
                anchors.rightMargin: 12 * root.s
                anchors.verticalCenter: parent.verticalCenter
                text: "≈ " + root.gramsText(modelData.grams)
                color: "#4ade80"
                font.family: Theme.font
                font.pixelSize: 12 * root.s
                font.bold: true
              }
            }
          }

          Text {
            width: parent.width
            text: qsTr("Brown sugar at " + root.brownSugarRatio + "% and stevia at " + root.steviaSweetness + "× the sweetness of white sugar. Change both in Ryoku Settings.")
            color: "#64748b"
            font.family: Theme.font
            font.pixelSize: 9 * root.s
            wrapMode: Text.WordWrap
          }
        }
      }
    }

    // ── Desserts ───────────────────────────────────────────────────────
    Rectangle {
      width: parent.width
      height: dessertOuterColumn.implicitHeight
      radius: 14 * root.s
      color: "#1e293b"
      border.width: 1
      border.color: "#334155"

      Column {
        id: dessertOuterColumn
        width: parent.width
        spacing: 0

        // Header row
        Item {
          width: parent.width
          height: 44 * root.s
          property real radius: 14 * root.s
          Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: dessertHeader.containsMouse ? "#2d3a4f" : "transparent"
            Behavior on color { ColorAnimation { duration: 200 } }
          }
          Text {
            anchors.left: parent.left
            anchors.leftMargin: 16 * root.s
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("Desserts")
            color: "#e2e8f0"
            font.family: Theme.font
            font.pixelSize: 12 * root.s
            font.bold: true
            font.letterSpacing: 0.8 * root.s
          }
          Text {
            anchors.right: parent.right
            anchors.rightMargin: 16 * root.s
            anchors.verticalCenter: parent.verticalCenter
            text: root.dessertExpanded ? "−" : "+"
            color: "#94a3b8"
            font.family: Theme.font
            font.pixelSize: 18 * root.s
            font.bold: true
          }
          MouseArea {
            id: dessertHeader
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.dessertExpanded = !root.dessertExpanded
          }
        }

        Column {
          width: parent.width
          spacing: 8 * root.s
          visible: root.dessertExpanded
          padding: 8 * root.s
          topPadding: 0
          bottomPadding: 12 * root.s

          Repeater {
            model: [
              { label: qsTr("Bonbon"), grams: 8, icon: "🍬" },
              { label: qsTr("Biscuit"), grams: 3, icon: "🍪" },
              { label: qsTr("Chocolate bar"), grams: 22, icon: "🍫" },
              { label: qsTr("Gum"), grams: 2, icon: "🫧" }
            ]
            delegate: Item {
              required property var modelData
              width: parent.width
              height: 40 * root.s
              Rectangle {
                anchors.fill: parent
                radius: 10 * root.s
                color: dessertTap.containsMouse ? "#334155" : "#273148"
                border.width: 1
                border.color: "#3d4a5f"
                Behavior on color { ColorAnimation { duration: 180 } }
              }
              Text {
                anchors.left: parent.left
                anchors.leftMargin: 14 * root.s
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.icon + "  " + modelData.label
                color: "#e2e8f0"
                font.family: Theme.font
                font.pixelSize: 12 * root.s
              }
              Text {
                anchors.right: parent.right
                anchors.rightMargin: 14 * root.s
                anchors.verticalCenter: parent.verticalCenter
                text: "+" + modelData.grams + " g"
                color: "#94a3b8"
                font.family: Theme.font
                font.pixelSize: 11 * root.s
                font.bold: true
              }
              MouseArea {
                id: dessertTap
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.service && root.service.addSugar(modelData.grams, modelData.icon + " " + modelData.label)
              }
            }
          }
        }
      }
    }

    // ── Today's log ────────────────────────────────────────────────────
    Item {
      width: parent.width
      height: 20 * root.s
      Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: qsTr("Today's log")
        color: "#e2e8f0"
        font.family: Theme.font
        font.pixelSize: 11 * root.s
        font.bold: true
        font.letterSpacing: 0.8 * root.s
      }
      Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14 * root.s
        Text {
          text: qsTr("Clear")
          color: root.service && (root.service.todayEntries || []).length > 0 ? "#ef4444" : "#334155"
          font.family: Theme.font
          font.pixelSize: 10 * root.s
          MouseArea {
            anchors.fill: parent
            enabled: root.service && (root.service.todayEntries || []).length > 0
            cursorShape: Qt.PointingHandCursor
            onClicked: root.service && root.service.clearToday()
          }
        }
        Text {
          text: qsTr("Undo")
          color: root.service && root.service.todayEntries.length > 0 ? "#94a3b8" : "#334155"
          font.family: Theme.font
          font.pixelSize: 10 * root.s
          MouseArea {
            anchors.fill: parent
            enabled: root.service && (root.service.todayEntries || []).length > 0
            cursorShape: Qt.PointingHandCursor
            onClicked: root.service && root.service.undoLast()
          }
        }
      }
    }

    Text {
      width: parent.width
      visible: !root.service || (root.service.todayEntries || []).length === 0
      text: qsTr("Nothing logged today.")
      color: "#64748b"
      font.family: Theme.font
      font.pixelSize: 12 * root.s
      padding: 8 * root.s
    }

    Column {
      width: parent.width
      spacing: 5 * root.s
      Repeater {
        model: {
          var rows = root.service ? (root.service.todayEntries || []).slice() : []
          rows.reverse()
          return rows.slice(0, 8)
        }
        delegate: Item {
          required property var modelData
          width: parent.width
          height: 30 * root.s
          Rectangle {
            anchors.fill: parent
            radius: 8 * root.s
            color: "#1e293b"
            border.width: 1
            border.color: "#273148"
          }
          Text {
            anchors.left: parent.left
            anchors.leftMargin: 12 * root.s
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatTime(new Date(modelData.t), "hh:mm")
            color: "#64748b"
            font.family: Theme.font
            font.pixelSize: 10 * root.s
            font.bold: true
          }
          Text {
            anchors.left: parent.left
            anchors.leftMargin: 52 * root.s
            anchors.verticalCenter: parent.verticalCenter
            text: modelData.name
            color: "#cbd5e1"
            font.family: Theme.font
            font.pixelSize: 11 * root.s
          }
          Text {
            anchors.right: parent.right
            anchors.rightMargin: 12 * root.s
            anchors.verticalCenter: parent.verticalCenter
            text: modelData.grams + " g"
            color: "#e2e8f0"
            font.family: Theme.font
            font.pixelSize: 11 * root.s
            font.bold: true
          }
        }
      }
    }

    // ── Footer info ────────────────────────────────────────────────────
    Column {
      width: parent.width
      spacing: 4 * root.s
      Text {
        width: parent.width
        text: qsTr("DAILY SWEETENER GOAL")
        color: "#64748b"
        font.family: Theme.font
        font.pixelSize: 10 * root.s
        font.bold: true
        font.letterSpacing: 0.8 * root.s
      }
      Text {
        width: parent.width
        text: root.service ? (root.service.todayGrams <= root.service.dailyGoal
          ? qsTr((root.service.dailyGoal - root.service.todayGrams).toFixed(1) + " g remaining today")
          : qsTr((root.service.todayGrams - root.service.dailyGoal).toFixed(1) + " g over goal")) : ""
        color: root.service && root.service.overGoal ? "#fca5a5" : "#4ade80"
        font.family: Theme.font
        font.pixelSize: 12 * root.s
        font.bold: true
      }
      Text {
        width: parent.width
        text: qsTr("Edit amounts in Ryoku Settings → Plugins → Sugar Tracker")
        color: "#475569"
        font.family: Theme.font
        font.pixelSize: 9 * root.s
        wrapMode: Text.WordWrap
      }
    }
  }
}
