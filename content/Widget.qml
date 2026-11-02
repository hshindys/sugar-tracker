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

  Canvas {
    id: spoonMark
    anchors.centerIn: parent
    visible: root.isGlyph
    width: root.glyphW * root.s
    height: root.glyphH * root.s
    onPaint: {
      var ctx = getContext("2d")
      var scale = Math.min(width / 24, height / 32)
      ctx.setTransform(1, 0, 0, 1, 0, 0)
      ctx.clearRect(0, 0, width, height)
      ctx.save()
      ctx.translate((width - 24 * scale) / 2, (height - 32 * scale) / 2)
      ctx.scale(scale, scale)

      var prog = root.progress
      var over = root.service ? root.service.overGoal : false
      var color = "#4ade80"  // green default
      if (over) color = "#fa3b30"
      else if (prog >= 1) color = "#f97316"
      else if (prog >= 0.7) color = "#fbbf24"
      else if (prog >= 0.35) color = "#4ade80"

      // Spoon bowl (oval, top)
      ctx.fillStyle = color
      ctx.beginPath()
      ctx.ellipse(12, 8, 8, 10, 0, 0, 2 * Math.PI)
      ctx.fill()

      // Spoon handle (pill, bottom)
      ctx.fillStyle = color
      ctx.beginPath()
      ctx.roundRect(9.5, 16, 5, 14, 2.5)
      ctx.fill()

      // Sugar cube on spoon (white square with slight transparency)
      ctx.fillStyle = "rgba(255,255,255,0.85)"
      ctx.beginPath()
      ctx.roundRect(8.5, 4, 7, 7, 1.5)
      ctx.fill()

      // Sugar cube highlight
      ctx.fillStyle = "rgba(255,255,255,0.6)"
      ctx.beginPath()
      ctx.roundRect(9, 4.5, 3, 3, 0.8)
      ctx.fill()

      // Sparkles (sugar crystals) - golden
      ctx.fillStyle = "#fbbf24"
      ctx.globalAlpha = 0.9
      ctx.beginPath()
      ctx.arc(20, 4, 2, 0, 2 * Math.PI)
      ctx.fill()
      ctx.beginPath()
      ctx.arc(22, 9, 1.5, 0, 2 * Math.PI)
      ctx.fill()
      ctx.beginPath()
      ctx.arc(19, 12, 1, 0, 2 * Math.PI)
      ctx.fill()
      ctx.globalAlpha = 1.0

      // Shadow on handle
      ctx.fillStyle = "rgba(0,0,0,0.15)"
      ctx.beginPath()
      ctx.roundRect(11, 17, 2, 12, 1)
      ctx.fill()

      ctx.restore()
    }
    Connections {
      target: root.service
      function onTodayGramsChanged() { spoonMark.requestPaint() }
      function onDailyGoalChanged() { spoonMark.requestPaint() }
      function onOverGoalChanged() { spoonMark.requestPaint() }
    }
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
