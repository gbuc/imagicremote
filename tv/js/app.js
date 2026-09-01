(function () {
  var video = document.getElementById("hdmi");
  var overlay = document.getElementById("overlay");
  var banner = document.getElementById("banner");
  var macStatus = document.getElementById("mac-status");
  var settingsEl = document.getElementById("settings");
  var settingsOpen = false;
  var keyboardOpen = false;
  var bridge = LGRemote.createBridge();
  var signalTimer = null;
  var fadeTimer = null;

  function setStatus(text, fade) {
    if (!macStatus) return;
    clearTimeout(fadeTimer);
    macStatus.classList.remove("fade");
    if (!text) {
      macStatus.hidden = true;
      macStatus.textContent = "";
      return;
    }
    macStatus.hidden = false;
    macStatus.textContent = text;
    if (fade) {
      fadeTimer = setTimeout(function () {
        macStatus.classList.add("fade");
      }, 2500);
    }
  }

  function showBanner(text) {
    if (!text) {
      banner.hidden = true;
      banner.textContent = "";
      return;
    }
    banner.hidden = false;
    banner.textContent = text;
  }

  function isForwarding() {
    return !settingsOpen && !keyboardOpen;
  }

  function openSettings(cfg) {
    pointer.release();
    settingsOpen = true;
    settingsEl.hidden = false;
    ui.fill(cfg || LGRemote.loadConfig(localStorage));
  }

  function closeSettings() {
    settingsOpen = false;
    settingsEl.hidden = true;
  }

  function apply(cfg) {
    LGRemote.setHdmi(video, cfg.hdmi);
    setStatus("Connecting to Mac at " + cfg.host + "…", false);
    bridge.connect(cfg.host);
    clearTimeout(signalTimer);
    signalTimer = setTimeout(function () {
      if (!video.videoWidth) showBanner("no HDMI signal");
    }, 3000);
  }

  video.addEventListener("loadeddata", function () {
    if (video.videoWidth) {
      if (banner.textContent === "no HDMI signal") showBanner(null);
    }
  });

  bridge.setHostHandler(function (msg) {
    if (!msg) return;
    if (msg.t === "kbd" && msg.on) openKeyboard();
    if (msg.t === "devextend") LGRemote.extendDevModeSession();
  });

  bridge.setStatusHandler(function (msg) {
    if (msg) {
      showBanner(msg);
      setStatus(msg === "can't reach Mac" ? "Can't reach the Mac" : msg, false);
    } else {
      if (banner.textContent === "can't reach Mac") showBanner(null);
      setStatus("Controlling the Mac", true);
    }
  });

  var ui = LGRemote.mountSettings(settingsEl, function (cfg) {
    LGRemote.saveConfig(localStorage, cfg);
    closeSettings();
    apply(cfg);
  });

  var pointer = LGRemote.attachPointer(overlay, bridge, isForwarding, function () {
    if (keyboardOpen) closeKeyboard();
  });
  var keyboard = LGRemote.attachKeyboard(
    document.getElementById("kb-input"),
    bridge,
    function () {
      return keyboardOpen;
    }
  );

  function openKeyboard() {
    if (settingsOpen) return;
    if (keyboardOpen) {
      keyboard.focus();
      return;
    }
    pointer.release();
    keyboard.reset();
    keyboardOpen = true;
    keyboard.focus();
  }

  function closeKeyboard() {
    keyboard.reset();
    keyboard.blur();
    keyboardOpen = false;
  }

  LGRemote.attachKeys(
    function () {
      if (settingsOpen) closeSettings();
      else if (keyboardOpen) closeKeyboard();
      else openSettings(LGRemote.loadConfig(localStorage));
    },
    function () {
      if (settingsOpen) closeSettings();
      else if (keyboardOpen) closeKeyboard();
    },
    function () {
      if (!isForwarding()) return;
      pointer.rightClick();
    },
    function () {
      if (keyboardOpen) closeKeyboard();
      else openKeyboard();
    }
  );

  function resumeBridge() {
    if (document.hidden) return;
    var cfg = LGRemote.loadConfig(localStorage);
    if (cfg) bridge.connect(cfg.host);
  }

  document.addEventListener("visibilitychange", function () {
    if (document.hidden) bridge.pause();
    else resumeBridge();
  });
  window.addEventListener("pageshow", resumeBridge);
  document.addEventListener("webOSRelaunch", resumeBridge);

  var existing = LGRemote.loadConfig(localStorage);
  if (existing) apply(existing);
  else openSettings(null);

  // webOS often marks the document hidden during launch and never delivers
  // the matching visible event if we already closed the socket.
  setTimeout(resumeBridge, 400);
  setTimeout(resumeBridge, 2000);
})();
