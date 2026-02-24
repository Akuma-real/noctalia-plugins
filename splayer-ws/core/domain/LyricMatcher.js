.pragma library

function _asArray(value) {
  return Array.isArray(value) ? value : []
}

function _toNumber(value, fallback) {
  var num = Number(value)
  return isFinite(num) ? num : fallback
}

function _lineStart(line) {
  var start = _toNumber(line && line.startTime, NaN)
  if (isFinite(start)) return start

  var words = _asArray(line && line.words)
  if (words.length > 0) {
    return _toNumber(words[0].startTime, 0)
  }
  return 0
}

function _lineText(line) {
  if (!line) return ""

  var words = _asArray(line.words)
  if (words.length > 0) {
    var joined = ""
    for (var i = 0; i < words.length; i++) {
      joined += (words[i] && words[i].word ? words[i].word : "")
    }
    joined = joined.toString().trim()
    if (joined) return joined
  }

  if (line.text !== undefined && line.text !== null) {
    var text = line.text.toString().trim()
    if (text) return text
  }

  return ""
}

function pickLines(lines, positionMs) {
  var list = _asArray(lines)
  if (list.length === 0) {
    return {
      current: "",
      next: "",
      index: -1
    }
  }

  var pos = _toNumber(positionMs, 0)
  var selected = -1

  for (var i = 0; i < list.length; i++) {
    var start = _lineStart(list[i])
    if (start <= pos) {
      selected = i
    } else {
      break
    }
  }

  if (selected < 0) {
    return {
      current: "",
      next: _lineText(list[0]),
      index: -1
    }
  }

  var current = _lineText(list[selected])
  var next = (selected + 1 < list.length) ? _lineText(list[selected + 1]) : ""

  return {
    current: current,
    next: next,
    index: selected
  }
}
