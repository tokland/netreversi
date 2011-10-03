global = this;
module = {"exports": this};
exports = module.exports;
_browserify_namespace = {};

function browserify(namespace) {
  _browserify_namespace = namespace; 
}

function require(module) {
  var obj = _browserify_namespace[module];
  if (obj) {
    return obj;
  } else {
    alert("[browserify:require] unknown module was required: " + module);
  }
}
