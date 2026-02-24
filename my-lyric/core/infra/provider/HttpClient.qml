import QtQuick

QtObject {
  id: root

  function get(url, timeoutMs, callback) {
    var done = callback || function() {}
    var finished = false

    function finalize(result) {
      if (finished) return
      finished = true
      done(result)
    }

    var xhr = new XMLHttpRequest()
    xhr.onreadystatechange = function() {
      if (xhr.readyState !== XMLHttpRequest.DONE) return
      var ok = xhr.status >= 200 && xhr.status < 300
      finalize({
        ok: ok,
        statusCode: xhr.status || 0,
        body: xhr.responseText || "",
        error: ok ? "" : ("http " + (xhr.status || 0))
      })
    }
    xhr.onerror = function() {
      finalize({ ok: false, statusCode: xhr.status || 0, body: "", error: "network error" })
    }

    try {
      xhr.timeout = Math.max(0, Math.round(Number(timeoutMs || 0)))
      xhr.ontimeout = function() {
        finalize({ ok: false, statusCode: 0, body: "", error: "timeout" })
      }
    } catch (e) {
    }

    try {
      xhr.open("GET", url, true)
      xhr.send()
    } catch (e2) {
      finalize({ ok: false, statusCode: 0, body: "", error: "request failed" })
    }
  }
}
