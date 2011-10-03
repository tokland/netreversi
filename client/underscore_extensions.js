module.exports = _ = require('underscore');

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
    _.any(list, function(item, index, list) {
      var res = callback.call(context, item, index, list);
      if (res) {
        xs.push(item);
        return false;
      } else {
        return true;
      }
    });
    return xs;
  },

  /* Repeat item n times */
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
    _.any(list, function(item, index, list) {
      var res = callback.call(context, item, index, list);
      if (res) {
        output = res;
        return true;
      } else {
        return false;
      }
    });
    return output;
  },
  
  /* Return copy of object containing only given keys */
  slice: function(object, keys) {
    return _.reduce(_(object).keys(), function(obj, key) {
      if (_.include(keys, key)) 
        obj[key] = object[key];
      return obj;
    }, {});
  },

  /* Like _.uniq but using a custom comparison function */
  uniqWith: function(list, compare_function, context) {
    var output = [];
    _.each(list, function(item) {
      if (!_.any(output, function(x) { return compare_function.call(context, item, x); })) {
        output.push(item);
      }
    });
    return output;
  },

  /* Return a one-level flattened version of an array. */
  flatten1: function(array) {
    return _.reduce(array, function(memo, value) {
      return memo.concat(value);
    }, []);
  },

  /* Return true if object is not empty */
  isNotEmpty: function(obj) {
    return !_.isEmpty(obj);
  },

  /* Inspect object and print it to the JS console */
  inspect: function(obj) {
    console.log(JSON.stringify(obj, null));
  }
})
