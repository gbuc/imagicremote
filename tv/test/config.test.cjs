const { test } = require("node:test");
const assert = require("node:assert/strict");
const { loadConfig, saveConfig, parseOctets } = require("../js/config.js");

function mem() {
  const s = {};
  return {
    getItem: (k) => (k in s ? s[k] : null),
    setItem: (k, v) => {
      s[k] = String(v);
    },
  };
}

test("roundtrip", () => {
  const storage = mem();
  assert.equal(loadConfig(storage), null);
  saveConfig(storage, { host: "192.168.1.8", hdmi: 2 });
  assert.deepEqual(loadConfig(storage), { host: "192.168.1.8", hdmi: 2 });
});

test("rejects bad hdmi", () => {
  const storage = mem();
  saveConfig(storage, { host: "192.168.1.8", hdmi: 9 });
  assert.equal(loadConfig(storage), null);
});

test("parseOctets", () => {
  assert.equal(parseOctets(["192", "168", "1", "8"]), "192.168.1.8");
  assert.equal(parseOctets(["192", "168", "1", "256"]), null);
  assert.equal(parseOctets(["", "168", "1", "8"]), null);
});
