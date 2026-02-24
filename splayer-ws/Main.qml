import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.UI
import "core/config/SettingsCodec.js" as SettingsCodec
import "core/domain/LyricMatcher.js" as LyricMatcher

Item {
  id: root

  property var pluginApi: null
  property var settings: SettingsCodec.normalize({})

  property string connectionState: "disconnected"
  property string lastError: ""

  property bool isPlaying: false
  property string trackName: ""
  property string artistName: ""
  property string albumName: ""
  property string coverUrl: ""

  property int currentTimeMs: 0
  property int durationMs: 0
  property real progressRatio: 0

  property var lrcData: []
  property var yrcData: []
  property string currentLyric: ""
  property string nextLyric: ""

  property bool _checkingDependency: false
  property bool _restartExpected: false

  readonly property bool autoReconnect: Boolean(settings?.connection?.autoReconnect ?? true)
  readonly property int reconnectMs: Number(settings?.connection?.reconnectMs ?? 1500)
  readonly property int heartbeatSec: Number(settings?.connection?.heartbeatSec ?? 20)
  readonly property string websocatBin: (settings?.connection?.websocatBin ?? "websocat").toString()
  readonly property bool preferYrc: Boolean(settings?.lyric?.preferYrc ?? true)

  readonly property string wsUrl: "ws://"
    + (settings?.connection?.host ?? "127.0.0.1")
    + ":"
    + Number(settings?.connection?.port ?? 25885)

  function _safeText(value, fallback) {
    if (value === undefined || value === null) return fallback
    return value.toString().trim()
  }

  function _safeNumber(value, fallback) {
    var num = Math.round(Number(value))
    return isFinite(num) ? num : fallback
  }

  function _safeSecondsToMs(value, fallback) {
    var seconds = Number(value)
    if (!isFinite(seconds)) return fallback
    return Math.max(0, Math.round(seconds * 1000))
  }

  function _safeArray(value) {
    return Array.isArray(value) ? value : []
  }

  function _normalizePlayStatus(value, fallback) {
    if (typeof value === "boolean") return value
    if (typeof value === "number") return value !== 0
    if (typeof value === "string") {
      var text = value.toLowerCase().trim()
      if (text === "play" || text === "playing" || text === "true" || text === "1") return true
      if (text === "pause" || text === "paused" || text === "false" || text === "0") return false
    }
    return fallback
  }

  function _updateProgressRatio() {
    if (durationMs <= 0) {
      progressRatio = 0
      return
    }
    var ratio = currentTimeMs / durationMs
    if (ratio < 0) ratio = 0
    if (ratio > 1) ratio = 1
    progressRatio = ratio
  }

  function _updateLyricLines() {
    var source = (preferYrc && yrcData.length > 0) ? yrcData : lrcData
    var matched = LyricMatcher.pickLines(source, currentTimeMs)
    currentLyric = matched.current || ""
    nextLyric = matched.next || ""
  }

  function _clearLyrics() {
    lrcData = []
    yrcData = []
    currentLyric = ""
    nextLyric = ""
  }

  function _setConnectionError(message, showToast) {
    connectionState = "error"
    lastError = message
    if (showToast) {
      ToastService.showError(message)
    }
  }

  function reloadSettings() {
    var raw = (pluginApi && pluginApi.pluginSettings) ? pluginApi.pluginSettings : ({})
    settings = SettingsCodec.normalize(raw)
  }

  function _startDependencyCheck() {
    if (_checkingDependency) return
    _checkingDependency = true
    checkDependencyProc.command = [websocatBin, "--version"]
    checkDependencyProc.running = true
  }

  function _startWsProcess() {
    if (wsProc.running) return

    lastError = ""
    connectionState = "connecting"

    wsProc.command = [websocatBin, "-t", wsUrl]
    wsProc.running = true
  }

  function startConnection() {
    if (wsProc.running || _checkingDependency) return
    _startDependencyCheck()
  }

  function reconnect() {
    reconnectTimer.stop()

    if (wsProc.running) {
      _restartExpected = true
      wsProc.running = false
      return
    }

    _restartExpected = false
    startConnection()
  }

  function _sendRaw(message) {
    if (!wsProc.running) return false
    try {
      wsProc.write(message + "\n")
      return true
    } catch (e) {
      _setConnectionError(pluginApi?.tr("errors.send-failed") || "发送消息失败", false)
      return false
    }
  }

  function _sendJson(obj) {
    return _sendRaw(JSON.stringify(obj))
  }

  function requestSongInfo() {
    _sendJson({
      type: "get-song-info"
    })
  }

  function sendControl(command) {
    var allowed = ["toggle", "play", "pause", "next", "prev"]
    if (allowed.indexOf(command) < 0) return

    _sendJson({
      type: "control",
      data: {
        command: command
      }
    })
  }

  function _applySongInfo(data) {
    if (!data || typeof data !== "object") return

    isPlaying = _normalizePlayStatus(data.playStatus, isPlaying)

    trackName = _safeText(data.name, _safeText(data.playName, _safeText(data.title, trackName)))
    artistName = _safeText(data.artistName, _safeText(data.artist, _safeText(data.artists, artistName)))
    albumName = _safeText(data.albumName, _safeText(data.album, albumName))
    coverUrl = _safeText(
      data.cover,
      _safeText(
        data.coverUrl,
        _safeText(
          data.picUrl,
          _safeText(data.artwork, coverUrl)
        )
      )
    )

    currentTimeMs = _safeSecondsToMs(data.currentTime, currentTimeMs)
    durationMs = _safeSecondsToMs(data.duration, durationMs)
    _updateProgressRatio()

    if (Array.isArray(data.lrcData)) {
      lrcData = _safeArray(data.lrcData)
    }
    if (Array.isArray(data.yrcData)) {
      yrcData = _safeArray(data.yrcData)
    }
    _updateLyricLines()
  }

  function _applySongChange(data) {
    if (!data || typeof data !== "object") return

    trackName = _safeText(data.name, trackName)
    artistName = _safeText(data.artist, artistName)
    albumName = _safeText(data.album, albumName)
    durationMs = _safeNumber(data.duration, durationMs)
    currentTimeMs = 0
    _updateProgressRatio()
    _clearLyrics()

    requestSongInfo()
  }

  function _applyProgressChange(data) {
    if (!data || typeof data !== "object") return

    currentTimeMs = _safeNumber(data.currentTime, currentTimeMs)
    durationMs = _safeNumber(data.duration, durationMs)
    _updateProgressRatio()
    _updateLyricLines()
  }

  function _applyLyricChange(data) {
    if (!data || typeof data !== "object") return

    lrcData = _safeArray(data.lrcData)
    yrcData = _safeArray(data.yrcData)
    _updateLyricLines()
  }

  function _handleWsMessage(message) {
    if (!message || typeof message !== "object") return

    var type = _safeText(message.type, "")
    var data = message.data || ({})

    if (type !== "error" && connectionState !== "connected") {
      connectionState = "connected"
    }

    if (type === "welcome") {
      requestSongInfo()
      return
    }
    if (type === "song-info") {
      _applySongInfo(data)
      return
    }
    if (type === "status-change") {
      isPlaying = _normalizePlayStatus(data.status, isPlaying)
      return
    }
    if (type === "song-change") {
      _applySongChange(data)
      return
    }
    if (type === "progress-change") {
      _applyProgressChange(data)
      return
    }
    if (type === "lyric-change") {
      _applyLyricChange(data)
      return
    }
    if (type === "error") {
      lastError = _safeText(data.message, lastError)
      return
    }
  }

  function _handleWsLine(line) {
    var text = _safeText(line, "")
    if (!text) return

    if (text.toUpperCase() === "PONG") {
      if (connectionState !== "connected") connectionState = "connected"
      return
    }

    try {
      var message = JSON.parse(text)
      _handleWsMessage(message)
    } catch (e) {
      // Ignore invalid lines from ws bridge.
    }
  }

  IpcHandler {
    target: "plugin:splayer-ws"

    function toggle() { root.sendControl("toggle") }
    function play() { root.sendControl("play") }
    function pause() { root.sendControl("pause") }
    function next() { root.sendControl("next") }
    function prev() { root.sendControl("prev") }
    function refresh() { root.requestSongInfo() }
    function reconnect() { root.reconnect() }
  }

  Timer {
    id: initialSyncTimer
    interval: 450
    repeat: false
    onTriggered: root.requestSongInfo()
  }

  Timer {
    id: restartAfterStopTimer
    interval: 10
    repeat: false
    onTriggered: root.startConnection()
  }

  Timer {
    id: reconnectTimer
    interval: Math.max(500, root.reconnectMs)
    repeat: false
    onTriggered: root.startConnection()
  }

  Timer {
    id: heartbeatTimer
    interval: Math.max(5000, root.heartbeatSec * 1000)
    repeat: true
    running: wsProc.running
    onTriggered: root._sendRaw("PING")
  }

  Process {
    id: checkDependencyProc
    running: false
    command: []
    stderr: StdioCollector {}

    onExited: (exitCode, exitStatus) => {
      root._checkingDependency = false

      if (exitCode === 0) {
        root._startWsProcess()
        return
      }

      var message = root.pluginApi?.tr("errors.websocat-missing", {
        "bin": root.websocatBin
      }) || ("找不到 " + root.websocatBin + "，请先安装 websocat")
      root._setConnectionError(message, true)
    }
  }

  Process {
    id: wsProc
    running: false
    stdinEnabled: true
    command: []
    stdout: SplitParser {
      onRead: line => root._handleWsLine(line)
    }
    stderr: StdioCollector {
      id: wsStderr
    }

    onRunningChanged: {
      if (running) {
        root.connectionState = "connecting"
        root.lastError = ""
        initialSyncTimer.restart()
      }
    }

    onExited: (exitCode, exitStatus) => {
      heartbeatTimer.stop()

      if (root._restartExpected) {
        root._restartExpected = false
        restartAfterStopTimer.restart()
        return
      }

      if (root.connectionState !== "error") {
        root.connectionState = "disconnected"
      }

      var stderrText = (wsStderr.text || "").toString().trim()
      if (stderrText && root.connectionState !== "connected") {
        root.lastError = stderrText
      }

      if (root.autoReconnect) {
        reconnectTimer.restart()
      }
    }
  }

  Component.onCompleted: {
    reloadSettings()
    startConnection()
  }
}
