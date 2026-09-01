(function (root) {
  var KEY = "imagicremote.v1";

  function parseOctets(parts) {
    if (!parts || parts.length !== 4) return null;
    var nums = [];
    for (var i = 0; i < 4; i++) {
      if (!/^\d{1,3}$/.test(parts[i])) return null;
      var n = Number(parts[i]);
      if (n > 255) return null;
      nums.push(String(n));
    }
    return nums.join(".");
  }

  function saveConfig(storage, cfg) {
    storage.setItem(KEY, JSON.stringify(cfg));
  }

  function loadConfig(storage) {
    var raw = storage.getItem(KEY);
    if (!raw) return null;
    try {
      var cfg = JSON.parse(raw);
      if (typeof cfg.host !== "string" || !parseOctets(cfg.host.split("."))) return null;
      var hdmi = Number(cfg.hdmi);
      if (hdmi < 1 || hdmi > 4 || hdmi !== Math.floor(hdmi)) return null;
      return { host: cfg.host, hdmi: hdmi };
    } catch (e) {
      return null;
    }
  }

  root.LGRemote = root.LGRemote || {};
  root.LGRemote.parseOctets = parseOctets;
  root.LGRemote.saveConfig = saveConfig;
  root.LGRemote.loadConfig = loadConfig;
  if (typeof module !== "undefined" && module.exports) {
    module.exports = { parseOctets: parseOctets, saveConfig: saveConfig, loadConfig: loadConfig };
  }
})(typeof window !== "undefined" ? window : global);
