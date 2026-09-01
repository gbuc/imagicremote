const { test } = require("node:test");
const assert = require("node:assert/strict");
require("../js/normalize.js");
const { attachPointer } = require("../js/pointer.js");

function fire(target, type, props) {
  const ev = new Event(type);
  for (const [k, v] of Object.entries(props)) {
    Object.defineProperty(ev, k, { value: v, configurable: true });
  }
  target.dispatchEvent(ev);
}

function setup() {
  const sent = [];
  const overlay = new EventTarget();
  overlay.getBoundingClientRect = () => ({ left: 0, top: 0, width: 1920, height: 1080 });
  const rafs = new Map();
  let nextId = 1;
  global.requestAnimationFrame = (fn) => {
    const id = nextId++;
    rafs.set(id, fn);
    return id;
  };
  global.cancelAnimationFrame = (id) => {
    rafs.delete(id);
  };
  const timers = new Map();
  let tid = 1;
  global.setTimeout = (fn) => {
    const id = tid++;
    timers.set(id, fn);
    return id;
  };
  global.clearTimeout = (id) => {
    timers.delete(id);
  };
  const pointer = attachPointer(overlay, { send: (o) => sent.push(o) }, () => true);
  return {
    sent,
    overlay,
    pointer,
    flushRaf: () => {
      for (const fn of rafs.values()) fn();
      rafs.clear();
    },
    fireLongPress: () => {
      for (const fn of [...timers.values()]) fn();
      timers.clear();
    },
  };
}

test("down flushes pending move first", () => {
  const { sent, overlay, flushRaf } = setup();
  fire(overlay, "mousemove", { clientX: 960, clientY: 540 });
  fire(overlay, "mousedown", { button: 0 });
  assert.deepEqual(sent, [
    { t: "move", x: 0.5, y: 0.5 },
    { t: "down" },
  ]);
  flushRaf();
  assert.deepEqual(sent, [
    { t: "move", x: 0.5, y: 0.5 },
    { t: "down" },
  ]);
});

test("zero overlay rect uses innerWidth innerHeight", () => {
  global.innerWidth = 1920;
  global.innerHeight = 1080;
  const sent = [];
  const overlay = new EventTarget();
  overlay.getBoundingClientRect = () => ({ left: 0, top: 0, width: 0, height: 0 });
  global.requestAnimationFrame = () => 1;
  global.cancelAnimationFrame = () => {};
  attachPointer(overlay, { send: (o) => sent.push(o) }, () => true);
  fire(overlay, "mousemove", { clientX: 960, clientY: 540 });
  fire(overlay, "mousedown", { button: 0 });
  assert.deepEqual(sent, [
    { t: "move", x: 0.5, y: 0.5 },
    { t: "down" },
  ]);
});

test("release sends up and drops pending move", () => {
  const { sent, overlay, pointer, flushRaf } = setup();
  fire(overlay, "mousemove", { clientX: 100, clientY: 100 });
  pointer.release();
  flushRaf();
  assert.deepEqual(sent, [{ t: "up" }, { t: "rup" }]);
});

test("wheel sends signed line scroll", () => {
  const { sent, overlay } = setup();
  fire(overlay, "wheel", { deltaX: 0, deltaY: 80 });
  assert.deepEqual(sent, [{ t: "scroll", dx: 0, dy: 2 }]);
});

test("long press becomes right click and suppresses left up", () => {
  const { sent, overlay, fireLongPress } = setup();
  fire(overlay, "mousemove", { clientX: 100, clientY: 100 });
  fire(overlay, "mousedown", { button: 0, clientX: 100, clientY: 100 });
  assert.equal(sent[sent.length - 1].t, "down");
  fireLongPress();
  assert.deepEqual(sent.slice(-3), [{ t: "up" }, { t: "rdown" }, { t: "rup" }]);
  fire(overlay, "mouseup", { button: 0 });
  assert.equal(sent.filter((m) => m.t === "up").length, 1);
});

test("click while not forwarding is swallowed and reported", () => {
  const sent = [];
  const overlay = new EventTarget();
  overlay.getBoundingClientRect = () => ({ left: 0, top: 0, width: 1920, height: 1080 });
  global.requestAnimationFrame = () => 1;
  global.cancelAnimationFrame = () => {};
  global.setTimeout = () => 1;
  global.clearTimeout = () => {};
  let blocked = 0;
  attachPointer(
    overlay,
    { send: (o) => sent.push(o) },
    () => false,
    () => {
      blocked += 1;
    }
  );
  fire(overlay, "mousedown", { button: 0, clientX: 10, clientY: 10 });
  fire(overlay, "mouseup", { button: 0 });
  assert.equal(blocked, 1);
  assert.deepEqual(sent, []);
});

test("move cancels long press so drag stays left", () => {
  const { sent, overlay, fireLongPress } = setup();
  fire(overlay, "mousedown", { button: 0, clientX: 10, clientY: 10 });
  fire(overlay, "mousemove", { clientX: 80, clientY: 10 });
  fireLongPress();
  assert.equal(sent.some((m) => m.t === "rdown"), false);
});
