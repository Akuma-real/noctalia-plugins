.pragma library
.import "LrclibProvider.js" as LrclibProvider
.import "LrcCxProvider.js" as LrcCxProvider

function getProvider(providerId) {
  var id = (providerId || "lrccx").toString().trim().toLowerCase()
  if (id === "lrccx" || id === "lrcapi" || id === "lrc.cx") return LrcCxProvider
  if (id === "lrclib") return LrclibProvider
  return null
}

function fetchLyrics(providerId, track, providerCfg, httpClient, callback) {
  var done = callback || function() {}
  var provider = getProvider(providerId)
  if (!provider) {
    done({ ok: false, status: "provider not found", lines: [], plainFirstLine: "" })
    return
  }

  var request = provider.buildRequest(track, providerCfg || ({}))
  if (!request || !request.ok || !request.url) {
    done({
      ok: false,
      status: request && request.status ? request.status : "bad request",
      lines: [],
      plainFirstLine: ""
    })
    return
  }

  if (!httpClient || !httpClient.get) {
    done({ ok: false, status: "http unavailable", lines: [], plainFirstLine: "" })
    return
  }

  var timeoutMs = Math.round(Number((providerCfg || ({})).timeoutMs || 3500))
  httpClient.get(request.url, timeoutMs, function(resp) {
    if (!resp || !resp.ok) {
      var code = resp && resp.statusCode ? resp.statusCode : 0
      var status = code > 0
        ? ("error " + code)
        : ((resp && resp.error) ? resp.error : "network error")
      done({ ok: false, status: status, lines: [], plainFirstLine: "" })
      return
    }

    var parsed = provider.parseResponse(resp.body)
    if (!parsed || !parsed.ok) {
      done({
        ok: false,
        status: parsed && parsed.status ? parsed.status : "parse error",
        lines: [],
        plainFirstLine: ""
      })
      return
    }

    done({
      ok: true,
      status: "",
      lines: parsed.lines || [],
      plainFirstLine: parsed.plainFirstLine || ""
    })
  })
}
