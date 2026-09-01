(function (root) {
  function setHdmi(video, index) {
    video.innerHTML = "";
    var source = document.createElement("source");
    source.type = "service/webos-external";
    source.src = "ext://hdmi:" + index;
    video.appendChild(source);
    video.load();
    video.play().catch(function () {});
  }
  root.LGRemote.setHdmi = setHdmi;
})(window);
