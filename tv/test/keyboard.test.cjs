const { test } = require("node:test");
const assert = require("node:assert/strict");
const { diff, attachKeyboard } = require("../js/keyboard.js");

test("diff inserts and deletes from a common prefix", () => {
  assert.deepEqual(diff("", "ab"), { backs: 0, insert: "ab" });
  assert.deepEqual(diff("ab", "abc"), { backs: 0, insert: "c" });
  assert.deepEqual(diff("abc", "ab"), { backs: 1, insert: "" });
  assert.deepEqual(diff("abc", "ax"), { backs: 2, insert: "x" });
});

test("input events send text and backspace", () => {
  const sent = [];
  const listeners = {};
  const input = {
    value: "",
    addEventListener(type, fn) {
      listeners[type] = fn;
    },
    focus() {},
    blur() {},
  };
  attachKeyboard(input, { send: (o) => sent.push(o) }, () => true);
  input.value = "hi";
  listeners.input();
  assert.deepEqual(sent, [{ t: "text", s: "hi" }]);
  input.value = "h";
  listeners.input();
  assert.deepEqual(sent, [{ t: "text", s: "hi" }, { t: "key", k: "backspace" }]);
});

test("enter sends key then clears the buffer without extra backspaces", () => {
  const sent = [];
  const listeners = {};
  const input = {
    value: "",
    addEventListener(type, fn) {
      listeners[type] = fn;
    },
    focus() {},
    blur() {},
  };
  attachKeyboard(input, { send: (o) => sent.push(o) }, () => true);
  input.value = "x";
  listeners.input();
  const ev = { keyCode: 13, preventDefault() {} };
  listeners.keydown(ev);
  assert.deepEqual(sent, [{ t: "text", s: "x" }, { t: "key", k: "enter" }]);
  assert.equal(input.value, "");
});
