(function (root) {
  function diff(prev, next) {
    var i = 0;
    var n = Math.min(prev.length, next.length);
    while (i < n && prev.charAt(i) === next.charAt(i)) i += 1;
    return { backs: prev.length - i, insert: next.slice(i) };
  }

  function attachKeyboard(input, bridge, isOpen) {
    var last = "";
    var composing = false;
    var ignore = false;

    function sync() {
      if (!isOpen() || ignore) return;
      var next = input.value || "";
      var d = diff(last, next);
      last = next;
      for (var i = 0; i < d.backs; i++) bridge.send({ t: "key", k: "backspace" });
      if (d.insert) bridge.send({ t: "text", s: d.insert });
    }

    input.addEventListener("compositionstart", function () {
      composing = true;
    });
    input.addEventListener("compositionend", function () {
      composing = false;
      sync();
    });
    input.addEventListener("input", function () {
      if (!composing) sync();
    });
    input.addEventListener("keydown", function (ev) {
      if (!isOpen()) return;
      if (ev.keyCode !== 13) return;
      if (ev.preventDefault) ev.preventDefault();
      sync();
      bridge.send({ t: "key", k: "enter" });
      ignore = true;
      input.value = "";
      last = "";
      ignore = false;
    });

    return {
      reset: function () {
        ignore = true;
        input.value = "";
        last = "";
        ignore = false;
      },
      focus: function () {
        if (input.focus) input.focus();
      },
      blur: function () {
        if (input.blur) input.blur();
      },
    };
  }

  root.LGRemote = root.LGRemote || {};
  root.LGRemote.diff = diff;
  root.LGRemote.attachKeyboard = attachKeyboard;
  if (typeof module !== "undefined" && module.exports) {
    module.exports = { diff: diff, attachKeyboard: attachKeyboard };
  }
})(typeof window !== "undefined" ? window : global);
