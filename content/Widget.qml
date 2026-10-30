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
      var scale = Math.min(width / 22, height / 32)
      ctx.setTransform(1, 0, 0, 1, 0, 0)
      ctx.clearRect(0, 0, width, height)
      ctx.save()
      ctx.translate((width - 22 * scale) / 2, (height - 32 * scale) / 2)
      ctx.scale(scale, scale)

      var prog = root.progress
      var over = root.service ? root.service.overGoal : false
      var color = "#e2e8f0"
      if (over) color = "#fa3b30"
      else if (prog >= 1) color = "#f97316"
      else if (prog >= 0.7) color = "#fbbf24"
      else if (prog >= 0.35) color = "#4ade80"
      ctx.fillStyle = color

      function oval(cx, cy, rx, ry) {
        ctx.save()
        ctx.translate(cx, cy)
        ctx.scale(1, ry / rx)
        ctx.beginPath()
        ctx.arc(0, 0, rx, 0, 2 * Math.PI, false)
        ctx.fill()
        ctx.restore()
      }

      oval(11.0, 6.8, 6.4, 6.8)
      ctx.beginPath()
      ctx.moveTo(9.2, 11.6)
      ctx.bezierCurveTo(9.4, 18.0, 9.7, 25.5, 9.8, 29.4)
      ctx.quadraticCurveTo(9.9, 31.4, 11.0, 31.4)
      ctx.quadraticCurveTo(12.1, 31.4, 12.2, 29.4)
      ctx.bezierCurveTo(12.3, 25.5, 12.6, 18.0, 12.8, 11.6)
      ctx.closePath()
      ctx.fill()

      ctx.globalAlpha = 0.17
      ctx.fillStyle = "#000000"
      oval(11.0, 7.0, 3.4, 4.0)
      ctx.globalAlpha = 1.0
      ctx.fillStyle = color

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
