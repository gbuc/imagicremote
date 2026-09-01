(function (root) {
  function clamp01(n) {
    if (n < 0) return 0;
    if (n > 1) return 1;
    return n;
  }
  function normalize(clientX, clientY, width, height) {
    if (!width || !height) return { x: 0, y: 0 };
    return {
      x: clamp01(clientX / width),
      y: clamp01(clientY / height),
    };
  }
  root.LGRemote = root.LGRemote || {};
  root.LGRemote.normalize = normalize;
  if (typeof module !== "undefined" && module.exports) {
    module.exports = { normalize };
  }
})(typeof window !== "undefined" ? window : global);
