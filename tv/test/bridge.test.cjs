const { test } = require("node:test");
const assert = require("node:assert/strict");
const { createBridge } = require("../js/bridge.js");

class FakeWebSocket {
  constructor(url) {
    this.url = url;
    this.readyState = 0;
    this.sent = [];
    FakeWebSocket.all.push(this);
  }
  close() {
    this.readyState = 3;
  }
  send(data) {
    this.sent.push(data);
  }
  open() {
    this.readyState = 1;
    if (this.onopen) this.onopen();
  }
  fireClose() {
    this.readyState = 3;
    if (this.onclose) this.onclose();
  }
  fireError() {
    if (this.onerror) this.onerror();
  }
}

test("close then connect ignores stale onclose", () => {
  FakeWebSocket.all = [];
  global.WebSocket = FakeWebSocket;
  const statuses = [];
  const bridge = createBridge();
  bridge.setStatusHandler((s) => statuses.push(s));

  bridge.connect("10.0.0.1");
  assert.equal(FakeWebSocket.all.length, 1);
  const first = FakeWebSocket.all[0];
  first.open();
  assert.equal(statuses[statuses.length - 1], null);

  bridge.close();
  bridge.connect("10.0.0.1");
  assert.equal(FakeWebSocket.all.length, 2);
  first.fireClose();
  first.fireError();
  assert.equal(FakeWebSocket.all.length, 2);
  assert.equal(
    statuses.filter((s) => s === "can't reach Mac").length,
    0
  );
});

test("connect replaces socket without stale reopen", () => {
  FakeWebSocket.all = [];
  global.WebSocket = FakeWebSocket;
  const statuses = [];
  const bridge = createBridge();
  bridge.setStatusHandler((s) => statuses.push(s));

  bridge.connect("10.0.0.1");
  const first = FakeWebSocket.all[0];
  first.open();
  bridge.connect("10.0.0.2");
  assert.equal(FakeWebSocket.all.length, 2);
  assert.equal(FakeWebSocket.all[1].url, "ws://10.0.0.2:18734/");
  first.fireClose();
  assert.equal(FakeWebSocket.all.length, 2);
  assert.equal(
    statuses.filter((s) => s === "can't reach Mac").length,
    0
  );
});

test("pause does not reopen on delayed onclose", () => {
  FakeWebSocket.all = [];
  global.WebSocket = FakeWebSocket;
  const bridge = createBridge();
  bridge.connect("10.0.0.1");
  const first = FakeWebSocket.all[0];
  first.open();
  bridge.pause();
  first.fireClose();
  assert.equal(FakeWebSocket.all.length, 1);
});

test("host kbd frame is forwarded", () => {
  FakeWebSocket.all = [];
  global.WebSocket = FakeWebSocket;
  const host = [];
  const bridge = createBridge();
  bridge.setHostHandler((m) => host.push(m));
  bridge.connect("10.0.0.1");
  const ws = FakeWebSocket.all[0];
  ws.open();
  ws.onmessage({ data: JSON.stringify({ t: "kbd", on: true }) });
  assert.deepEqual(host, [{ t: "kbd", on: true }]);
  ws.onmessage({ data: JSON.stringify({ t: "devextend" }) });
  assert.equal(host[1].t, "devextend");
});

test("close does not reopen on delayed onclose", () => {
  FakeWebSocket.all = [];
  global.WebSocket = FakeWebSocket;
  const bridge = createBridge();
  bridge.setStatusHandler(() => {});

  bridge.connect("10.0.0.1");
  const first = FakeWebSocket.all[0];
  first.open();
  bridge.close();
  first.fireClose();
  assert.equal(FakeWebSocket.all.length, 1);
});
