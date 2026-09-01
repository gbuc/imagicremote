(function (root) {
  var RED = 403;
  var GREEN = 404;
  var YELLOW = 405;
  var BACK = 461;
  function attachKeys(onRed, onBack, onGreen, onYellow) {
    document.addEventListener("keydown", function (ev) {
      if (ev.keyCode === RED) {
        ev.preventDefault();
        onRed();
      } else if (ev.keyCode === BACK) {
        ev.preventDefault();
        onBack();
      } else if (ev.keyCode === GREEN && onGreen) {
        ev.preventDefault();
        onGreen();
      } else if (ev.keyCode === YELLOW && onYellow) {
        ev.preventDefault();
        onYellow();
      }
    });
  }
  root.LGRemote.attachKeys = attachKeys;
})(window);
