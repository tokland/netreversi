_.mixin({
  /* Return a new object with the merged properties of all objects in arguments */
  merge: function() {
    var objects = arguments;
    return _.reduce(_.rest(objects), function(obj, o) {
      return _.extend(obj, o);
    }, _.clone(_.first(objects) || {}));
  },

  /* Build an object with [key, value] from pair list or callback */
  mash: function(list, callback, context) {
   var pair_callback = callback || _.identity;
    return _.reduce(list, function(obj, value, index, list) {
      var pair = pair_callback.call(context, value, index, list);
      if (typeof pair == "object" && pair.length == 2) {
        obj[pair[0]] = pair[1];
      }
      return obj;
    }, {});
  },

  /* take elements from list while callback condition is met */
  takeWhile: function(list, callback, context) {
    var xs = [];
    _.detect(list, function(item, index, list) {
      var res = callback.call(context, item, index, list);
      if (res)
        xs.push(item);
      return !res;
    });
    return xs;
  },

  /* Repeat item n timtes */
  repeat: function(item, n) {
    var output = [];
    for(var i=0; i < n; i++) {
      output.push(item);
    }
    return output;
  },

  /* Return true if array_of_objects contain an object (deep comparison) */
  containsObject: function(array_of_objects, obj) {
    return _(array_of_objects).any(function(o) { return _(o).isEqual(obj) });
  },

  /* Return the first true element returned by the callback block (map + first) */
  mapDetect: function(list, callback, context) {
    var output;
    _.detect(list, function(item, index, list) {
      var res = callback.call(context, item, index, list);
      if (res) {
        output = res;
        return true;
      }
      return false;
    });
    return output;
  },

  /* Inspect object and print it to the JS console */
  inspect: function(obj) {
    console.log(JSON.stringify(obj, null));
  }
});

//console.log(_.mapDetect([1, 2, 3, 4, 5], function(x) { if (x > 3) return 2*x }));
//console.log(_.takeWhile([1, 2, 3, 4, 5], function(x) { return x < 3 }));
//console.log(_.merge({a: 1}, {a: 'new1', b: 2}));
//console.log(_(["ride", "the", "dragon"]).mash(function(s) { return [s, s.length]; }));
