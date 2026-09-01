(function (root) {
  function mountSettings(rootEl, onSave) {
    var picks = rootEl.querySelector("#hdmi-picks");
    var hdmi = 1;
    for (var i = 1; i <= 4; i++) {
      var b = document.createElement("button");
      b.textContent = "HDMI " + i;
      b.dataset.hdmi = String(i);
      b.addEventListener("click", function (ev) {
        hdmi = Number(ev.currentTarget.dataset.hdmi);
        highlight();
      });
      picks.appendChild(b);
    }

    function highlight() {
      var buttons = picks.querySelectorAll("button");
      for (var i = 0; i < buttons.length; i++) {
        buttons[i].style.outline = Number(buttons[i].dataset.hdmi) === hdmi ? "2px solid #fff" : "";
      }
    }

    function fill(cfg) {
      hdmi = (cfg && cfg.hdmi) || 1;
      var parts = cfg && cfg.host ? cfg.host.split(".") : ["", "", "", ""];
      var inputs = rootEl.querySelectorAll("input[data-oct]");
      for (var i = 0; i < inputs.length; i++) inputs[i].value = parts[i] || "";
      highlight();
    }

    rootEl.querySelector("#save").addEventListener("click", function () {
      var inputs = rootEl.querySelectorAll("input[data-oct]");
      var parts = [];
      for (var i = 0; i < inputs.length; i++) parts.push(inputs[i].value);
      var host = root.LGRemote.parseOctets(parts);
      if (!host) return;
      onSave({ host: host, hdmi: hdmi });
    });

    fill(null);
    return { fill: fill };
  }
  root.LGRemote.mountSettings = mountSettings;
})(window);
