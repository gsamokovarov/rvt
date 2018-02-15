//= require xterm
//= require xterm/addons/fit/fit
//= require xterm/addons/fullscreen/fullscreen

;(function(Terminal) {

  // Backport the EventEmitter from the old term.js implementation.
  function EventEmitter() {
    this._events = this._events || {};
  }

  EventEmitter.prototype.addListener = function(type, listener) {
    this._events[type] = this._events[type] || [];
    this._events[type].push(listener);
  };

  EventEmitter.prototype.on = EventEmitter.prototype.addListener;

  EventEmitter.prototype.removeListener = function(type, listener) {
    if (!this._events[type]) return;

    var obj = this._events[type]
      , i = obj.length;

    while (i--) {
      if (obj[i] === listener || obj[i].listener === listener) {
        obj.splice(i, 1);
        return;
      }
    }
  };

  EventEmitter.prototype.off = EventEmitter.prototype.removeListener;

  EventEmitter.prototype.removeAllListeners = function(type) {
    if (this._events[type]) delete this._events[type];
  };

  EventEmitter.prototype.once = function(type, listener) {
    function on() {
      var args = Array.prototype.slice.call(arguments);
      this.removeListener(type, on);
      return listener.apply(this, args);
    }
    on.listener = listener;
    return this.on(type, on);
  };

  EventEmitter.prototype.emit = function(type) {
    if (!this._events[type]) return;

    var args = Array.prototype.slice.call(arguments, 1)
      , obj = this._events[type]
      , l = obj.length
      , i = 0;

    for (; i < l; i++) {
      obj[i].apply(this, args);
    }
  };

  EventEmitter.prototype.listeners = function(type) {
    return this._events[type] = this._events[type] || [];
  };

  // Backport the inherits function as well.
  inherits = function(child, parent) {
    function f() { this.constructor = child; }
    f.prototype = parent.prototype;
    child.prototype = new f;
  };

  // Apply the fit and fullscreen addons before attaching to the RVT object.
  Terminal.applyAddon(fit);
  Terminal.applyAddon(fullscreen);

  // Expose the main RVT namespace.
  var RVT = this.RVT = {};

  RVT.inherits = inherits;
  RVT.EventEmitter = EventEmitter;
  RVT.Terminal = Terminal;

}).call(this, Terminal);
