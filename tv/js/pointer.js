(function (root) {
  var LONG_MS = 550;
  var SLOP = 24;

  function attachPointer(overlay, bridge, isForwarding, onBlockedClick) {
    var pending = null;
    var raf = 0;
    var pressTimer = null;
    var pressX = 0;
    var pressY = 0;
    var didRight = false;
    var swallow = false;

    function size() {
      var box = overlay.getBoundingClientRect();
      if (box && box.width > 0 && box.height > 0) return box;
      // webOS without CSS `inset` leaves an empty overlay at 0×0.
      return {
        left: 0,
        top: 0,
        width: root.innerWidth || 1920,
        height: root.innerHeight || 1080,
      };
    }

    function cancelPending() {
      if (raf) {
        cancelAnimationFrame(raf);
        raf = 0;
      }
      pending = null;
    }

    function flushMove() {
      if (raf) {
        cancelAnimationFrame(raf);
        raf = 0;
      }
      if (pending) {
        bridge.send({ t: "move", x: pending.x, y: pending.y });
        pending = null;
      }
    }

    function clearPressTimer() {
      if (pressTimer) {
        clearTimeout(pressTimer);
        pressTimer = null;
      }
    }

    function rightClick() {
      if (!isForwarding()) return;
      flushMove();
      bridge.send({ t: "rdown" });
      bridge.send({ t: "rup" });
    }

    function release() {
      clearPressTimer();
      cancelPending();
      bridge.send({ t: "up" });
      bridge.send({ t: "rup" });
    }

    function onMove(ev) {
      if (!isForwarding()) return;
      var box = size();
      pending = root.LGRemote.normalize(ev.clientX - box.left, ev.clientY - box.top, box.width, box.height);
      if (pressTimer) {
        var dx = ev.clientX - pressX;
        var dy = ev.clientY - pressY;
        if (dx * dx + dy * dy > SLOP * SLOP) clearPressTimer();
      }
      if (!raf) {
        raf = requestAnimationFrame(function () {
          raf = 0;
          if (!isForwarding()) {
            pending = null;
            return;
          }
          if (pending) {
            bridge.send({ t: "move", x: pending.x, y: pending.y });
            pending = null;
          }
        });
      }
    }

    function onDown(ev) {
      if (!isForwarding()) {
        swallow = true;
        if (onBlockedClick) onBlockedClick();
        return;
      }
      if (ev.button === 2) {
        flushMove();
        bridge.send({ t: "rdown" });
        return;
      }
      if (ev.button !== 0) return;
      didRight = false;
      flushMove();
      bridge.send({ t: "down" });
      pressX = ev.clientX || 0;
      pressY = ev.clientY || 0;
      clearPressTimer();
      pressTimer = setTimeout(function () {
        pressTimer = null;
        didRight = true;
        bridge.send({ t: "up" });
        bridge.send({ t: "rdown" });
        bridge.send({ t: "rup" });
      }, LONG_MS);
    }

    function onUp(ev) {
      if (swallow) {
        swallow = false;
        return;
      }
      if (!isForwarding()) return;
      if (ev.button === 2) {
        bridge.send({ t: "rup" });
        return;
      }
      if (ev.button !== 0) return;
      clearPressTimer();
      if (didRight) {
        didRight = false;
        return;
      }
      bridge.send({ t: "up" });
    }

    function onWheel(ev) {
      if (!isForwarding()) return;
      if (ev.preventDefault) ev.preventDefault();
      var dy = ev.deltaY || 0;
      var dx = ev.deltaX || 0;
      if (!dx && !dy && ev.wheelDelta) dy = -ev.wheelDelta;
      function step(v) {
        if (!v) return 0;
        var n = Math.round(v / 40);
        if (n === 0) n = v > 0 ? 1 : -1;
        if (n > 8) n = 8;
        if (n < -8) n = -8;
        return n;
      }
      var sx = step(dx);
      var sy = step(dy);
      if (!sx && !sy) return;
      bridge.send({ t: "scroll", dx: sx, dy: sy });
    }

    function onContext(ev) {
      if (!isForwarding()) return;
      if (ev.preventDefault) ev.preventDefault();
      rightClick();
    }

    var doc = overlay.ownerDocument;
    var target = doc && doc !== overlay ? doc : overlay;
    var capture = target !== overlay;
    target.addEventListener("mousemove", onMove, capture);
    target.addEventListener("mousedown", onDown, capture);
    target.addEventListener("mouseup", onUp, capture);
    target.addEventListener("wheel", onWheel, { capture: capture, passive: false });
    target.addEventListener("contextmenu", onContext, capture);

    return { release: release, rightClick: rightClick };
  }
  root.LGRemote = root.LGRemote || {};
  root.LGRemote.attachPointer = attachPointer;
  if (typeof module !== "undefined" && module.exports) {
    module.exports = { attachPointer: attachPointer };
  }
})(typeof window !== "undefined" ? window : global);
