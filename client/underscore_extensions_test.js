#!/usr/bin/node
_ = require('underscore_extensions')
assert = require('assert');

assert.deepEqual(_.merge(), {});
assert.deepEqual(_.merge({}), {});
assert.deepEqual(_.merge({a: 1}, {a: 2, b: 3}), {a: 2, b: 3});
assert.deepEqual(_.merge({a: 1}, {a: 2, b: 3}, {c: 4}), {a: 2, b: 3, c: 4});

assert.deepEqual(_([["a", 1], ["b", 2]]).mash(), {"a": 1, "b": 2});
assert.deepEqual(
  _(["ride", "the", "dragon"]).mash(function(s) { return [s, s.length]; }),
  {"ride": 4, "the": 3, "dragon": 6});

assert.equal(_([1, 2, 3, 4]).mapDetect(function(x) { if (x > 2) return x; }), 3);
assert.equal(_([1, 2, 3, 4]).mapDetect(function(x) { if (x > 10) return; }), undefined);

assert.ok(_([1, 2, 3]).containsObject(1))
assert.ok(!_([1, 2, 3]).containsObject(4))
assert.ok(_([1, [2, 3], 4]).containsObject([2, 3]))
assert.ok(!_([1, [2, 3], 4]).containsObject([1]))

assert.deepEqual(_.takeWhile([], function(x) { return x < 3 }), []);
assert.deepEqual(_.takeWhile([4, 5], function(x) { return x < 3 }), []);
assert.deepEqual(_.takeWhile([1, 2, 3, 4, 5], function(x) { return x < 3 }), [1, 2]);

assert.deepEqual(_.repeat("a", 0), []);
assert.deepEqual(_.repeat("b", 3), ["b", "b", "b"]);

assert.deepEqual(_.flatten1([]), []);
assert.deepEqual(_.flatten1([[1, 2], [3, 4]]), [1, 2, 3, 4]);
assert.deepEqual(_.flatten1([[1, 2], [[3, 4], 5]]), [1, 2, [3, 4], 5]);

assert.deepEqual(_({a: 1, b: 2, c: 3}).slice(["a", "c", "x"]), {a: 1, c: 3});
assert.deepEqual(_({a: 1, b: 2, c: 3}).slice(["d"]), {});

assert.ok(!_([]).isNotEmpty())
assert.ok(_([1]).isNotEmpty())
assert.ok(_([1, 2, 3]).isNotEmpty())

console.log("Tests passed")
