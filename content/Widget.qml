pragma ComponentBehavior: Bound
import QtQuick
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

Item {
  id: root
  property var pluginApi
  property var screen
  property bool active
  property string density: "glyph"
  property real s: 1
  property real widthBudget: 0

  readonly property bool isGlyph: root.density === "glyph"
  readonly property real popoutW: 428 * root.s
  readonly property var service: pluginApi && pluginApi.mainInstance ? pluginApi.mainInstance : null
  readonly property real glyphW: 22
  readonly property real glyphH: 32
  readonly property real contentW: isGlyph ? root.glyphW + 4 : root.popoutW
  readonly property real progress: {
    if (!service) return 0
    var goal = Number(service.dailyGoal)
    if (!isFinite(goal) || goal <= 0) return service.todayGrams > 0 ? 1 : 0
    return Math.max(0, Math.min(1, service.todayGrams / goal))
  }

  implicitWidth: root.contentW
  implicitHeight: isGlyph ? root.glyphH : body.implicitHeight

  MouseArea {
    anchors.fill: parent
    visible: root.isGlyph
    cursorShape: Qt.PointingHandCursor
    onClicked: root.pluginApi && root.pluginApi.togglePanel()
  }

  Image {
    id: spoonMark
    anchors.centerIn: parent
    visible: root.isGlyph
    width: root.glyphW * root.s
    height: root.glyphH * root.s
    source: root.pluginApi && root.pluginApi.pluginDir ? root.pluginApi.pluginDir + "/assets/icon.png" : ""
    fillMode: Image.PreserveAspectFit
    smooth: true
  }

  Loader {
    id: body
    active: !root.isGlyph && root.service !== null
    source: "Panel.qml"
    onLoaded: {
      item.pluginApi = Qt.binding(() => root.pluginApi)
      item.s = Qt.binding(() => root.s)
      item.active = Qt.binding(() => root.active)
      item.widthBudget = Qt.binding(() => root.widthBudget > 0 ? root.widthBudget : root.popoutW)
    }
    anchors.horizontalCenter: parent.horizontalCenter
  }
}
