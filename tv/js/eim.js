(function (root) {
  var APP_ID = "com.gbuc.imagicremote";

  function luna(uri, payload) {
    try {
      if (typeof webOS !== "undefined" && webOS.service && webOS.service.request) {
        var parts = uri.replace("luna://", "").split("/");
        var service = "luna://" + parts[0];
        var method = parts.slice(1).join("/");
        webOS.service.request(service, { method: method, parameters: payload });
        return;
      }
    } catch (e) {}
    try {
      var bridge = new PalmServiceBridge();
      bridge.onservicecallback = function () {};
      bridge.call(uri, JSON.stringify(payload));
    } catch (e2) {}
  }

  function registerAsInput() {
    luna("luna://com.webos.service.eim/addDevice", {
      appId: APP_ID,
      pigImage: "",
      mvpdIcon: "",
      type: "MVPD_IP",
    });
  }

  // Same as the EXTEND button in the Developer Mode app (updates the on-screen 50h/999h timer).
  function extendDevModeSession() {
    luna("luna://com.webos.applicationManager/launch", {
      id: "com.palmdts.devmode",
      params: { extend: true },
    });
  }

  root.LGRemote = root.LGRemote || {};
  root.LGRemote.extendDevModeSession = extendDevModeSession;
  registerAsInput();
})(window);
