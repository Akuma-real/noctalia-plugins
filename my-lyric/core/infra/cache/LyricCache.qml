import QtQuick

QtObject {
  id: root

  property bool enabled: true
  property int ttlSec: 21600
  property int maxEntries: 200

  property var _store: ({})
  property var _order: []

  function clear() {
    _store = ({})
    _order = []
  }

  function _nowMs() {
    return Date.now()
  }

  function _dropKey(key) {
    if (!key) return
    if (_store[key] !== undefined) delete _store[key]
    var next = []
    for (var i = 0; i < _order.length; i++) {
      if (_order[i] !== key) next.push(_order[i])
    }
    _order = next
  }

  function _touchKey(key) {
    var next = []
    for (var i = 0; i < _order.length; i++) {
      if (_order[i] !== key) next.push(_order[i])
    }
    next.push(key)
    _order = next
  }

  function _pruneExpired() {
    var now = _nowMs()
    var keys = Object.keys(_store)
    for (var i = 0; i < keys.length; i++) {
      var key = keys[i]
      var entry = _store[key]
      if (!entry) continue
      if (entry.expiresAtMs > 0 && entry.expiresAtMs <= now) {
        _dropKey(key)
      }
    }
  }

  function _pruneOverflow() {
    var limit = Math.max(1, Math.round(Number(maxEntries || 1)))
    while (_order.length > limit) {
      var oldest = _order[0]
      _dropKey(oldest)
    }
  }

  function get(key) {
    if (!enabled || !key) return null
    _pruneExpired()
    var entry = _store[key]
    if (!entry) return null
    _touchKey(key)
    return entry.value
  }

  function set(key, value) {
    if (!enabled || !key) return
    var now = _nowMs()
    var ttl = Math.max(0, Math.round(Number(ttlSec || 0)))
    var expiresAtMs = ttl > 0 ? (now + ttl * 1000) : 0
    _store[key] = { value: value, expiresAtMs: expiresAtMs }
    _touchKey(key)
    _pruneExpired()
    _pruneOverflow()
  }
}
