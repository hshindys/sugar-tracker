import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root
  property var pluginApi
  readonly property string logDir: pluginApi && pluginApi.stateDir
    ? pluginApi.stateDir
    : (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache"))
      + "/ryoku/plugins/sugar-tracker"
  readonly property string logPath: root.logDir + "/sugar-log.json"
  property var entries: []
  property real now: Date.now()
  readonly property real dailyGoal: {
    var settings = pluginApi && pluginApi.pluginSettings ? pluginApi.pluginSettings : null
    var value = settings ? Number(settings.dailyGoal) : 25
    if (!isFinite(value)) value = 25
    return Math.max(1, Math.min(200, value))
  }
  readonly property var todayEntries: {
    var start = new Date(now)
    start.setHours(0, 0, 0, 0)
    var out = []
    for (var i = 0; i < entries.length; i++)
      if (entries[i].t >= start.getTime()) out.push(entries[i])
    return out
  }
  readonly property real todayGrams: {
    var total = 0
    for (var i = 0; i < todayEntries.length; i++) total += todayEntries[i].grams
    return Math.round(total * 10) / 10
  }
  readonly property bool overGoal: todayGrams > dailyGoal

  function loadLog(raw) {
    var parsed = []
    try {
      var json = JSON.parse(raw || "{}")
      if (json && Array.isArray(json.entries)) parsed = json.entries
    } catch (e) { parsed = [] }

    var cutoff = Date.now() - 14 * 86400000
    var cleaned = []
    for (var i = 0; i < parsed.length; i++) {
      var entry = parsed[i]
      var t = Number(entry && entry.t)
      var grams = Number(entry && entry.grams)
      if (!isFinite(t) || !isFinite(grams) || grams <= 0 || t < cutoff) continue
      cleaned.push({ t: t, grams: Math.round(grams * 10) / 10, name: String(entry.name || "Sugar") })
    }
    cleaned.sort(function(a, b) { return a - b })
    entries = cleaned
  }

  function saveLog() {
    var file = new File(root.logPath)
    file.setText(JSON.stringify({ version: 1, entries: entries }, null, 2) + "\n")
  }

  function addSugar(amount, name) {
    var grams = Number(amount)
    if (!isFinite(grams) || grams <= 0 || grams > 200) return
    var next = entries.slice()
    next.push({ t: Date.now(), grams: Math.round(grams * 10) / 10, name: String(name || "Sugar") })
    entries = next
    now = Date.now()
    saveLog()
  }

  function removeEntryAt(timestamp) {
    var next = entries.slice()
    for (var i = next.length - 1; i >= 0; i--) {
      if (next[i].t === timestamp) {
        next.splice(i, 1)
        entries = next
        saveLog()
        return
      }
    }
  }

  function undoLast() {
    if (todayEntries.length > 0) removeEntryAt(todayEntries[todayEntries.length - 1].t)
  }

  function clearToday() {
    if (todayEntries.length === 0) return
    var start = new Date(now)
    start.setHours(0, 0, 0, 0)
    var cutoff = start.getTime()
    entries = entries.filter(function(e) { return e.t < cutoff || e.t >= cutoff + 86400000 })
    now = Date.now()
    saveLog()
  }

  Component.onCompleted: {
    var logDirPath = root.logDir
    var logFileRaw = ""
    try {
      var dir = new Directory(logDirPath)
      if (dir.exists()) {
        var file = new File(logDirPath + "/sugar-log.json")
        if (file.exists()) logFileRaw = file.readAll()
      }
    } catch (e) { logFileRaw = "" }
    loadLog(logFileRaw)
  }


}
