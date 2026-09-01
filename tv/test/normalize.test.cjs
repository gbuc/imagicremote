const { test } = require("node:test");
const assert = require("node:assert/strict");
const { normalize } = require("../js/normalize.js");

test("center", () => {
  assert.deepEqual(normalize(960, 540, 1920, 1080), { x: 0.5, y: 0.5 });
});

test("clamps past edges", () => {
  assert.deepEqual(normalize(-10, 2000, 1920, 1080), { x: 0, y: 1 });
});

test("zero size", () => {
  assert.deepEqual(normalize(10, 10, 0, 0), { x: 0, y: 0 });
});
