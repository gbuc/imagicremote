(function (root) {
  var DELAYS = [1000, 2000, 5000, 10000];
  function createBridge() {
    var ws = null;
    var host = null;
    var attempt = 0;
    var timer = null;
    var wanted = false;
    var token = 0;
    var onStatus = function () {};
    var onHost = function () {};

    function url() {
      return "ws://" + host + ":18734/";
    }

    function clearTimer() {
      if (timer) {
        clearTimeout(timer);
        timer = null;
      }
    }

    function dropSocket() {
      if (!ws) return;
      var old = ws;
      ws = null;
      old.close();
    }

    function open() {
      if (!wanted || !host) return;
      var myToken = token;
      var socket;
      try {
        socket = new WebSocket(url());
      } catch (e) {
        schedule();
        onStatus("can't reach Mac");
        return;
      }
      ws = socket;
      socket.onopen = function () {
        if (myToken !== token) return;
        attempt = 0;
        onStatus(null);
      };
      socket.onmessage = function (ev) {
        if (myToken !== token) return;
        var data;
        try {
          data = JSON.parse(ev.data);
        } catch (e) {
          return;
        }
        if (data && (data.t === "kbd" || data.t === "devextend")) onHost(data);
      };
      socket.onclose = function () {
        if (myToken !== token) return;
        if (ws === socket) ws = null;
        if (wanted) {
          onStatus("can't reach Mac");
          schedule();
        }
      };
      socket.onerror = function () {
        if (myToken !== token) return;
        onStatus("can't reach Mac");
      };
    }

    function schedule() {
      clearTimer();
      var delay = DELAYS[Math.min(attempt, DELAYS.length - 1)];
      attempt += 1;
      timer = setTimeout(open, delay);
    }

    return {
      setStatusHandler: function (fn) { onStatus = fn; },
      setHostHandler: function (fn) { onHost = fn; },
      connect: function (nextHost) {
        host = nextHost;
        wanted = true;
        attempt = 0;
        token += 1;
        clearTimer();
        dropSocket();
        open();
      },
      // Drop the socket but keep `wanted` so a later connect/open can resume.
      // Used when webOS fires visibility hidden on launch (close() would stop retries).
      pause: function () {
        token += 1;
        clearTimer();
        dropSocket();
      },
      close: function () {
        wanted = false;
        token += 1;
        clearTimer();
        dropSocket();
      },
      send: function (obj) {
        if (!ws || ws.readyState !== 1) return;
        ws.send(JSON.stringify(obj));
      },
    };
  }
  root.LGRemote = root.LGRemote || {};
  root.LGRemote.createBridge = createBridge;
  if (typeof module !== "undefined" && module.exports) {
    module.exports = { createBridge: createBridge };
  }
})(typeof window !== "undefined" ? window : global);
