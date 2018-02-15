//= require rvt

var AJAXTransport = (function(RVT) {

  var inherits = RVT.inherits;
  var EventEmitter = RVT.EventEmitter;

  var FORM_MIME_TYPE = 'application/x-www-form-urlencoded; charset=utf-8';

  var AJAXTransport = function(options) {
    EventEmitter.call(this);
    options || (options = {});

    this.url = (typeof options.url === 'string') ? {
      input: options.url,
      pendingOutput: options.url,
      configuration: options.url
    } : options.url;

    this.uid = options.uid;
    this.pendingInput  = '';

    this.initializeEventHandlers();
  };

  inherits(AJAXTransport, EventEmitter);

  // Initializes the default event handlers.
  AJAXTransport.prototype.initializeEventHandlers = function() {
    this.on('input', this.sendInput);
    this.on('configuration', this.sendConfiguration);
    this.once('initialization', function(callback) {
      this.pollForPendingOutput();
      callback && callback();
    });
  };

  // Shorthand for creating XHR requests.
  AJAXTransport.prototype.createRequest = function(method, url, options) {
    options || (options = {});

    var params = '';

    if (typeof options.form === 'object') {
      var content = [], form = options.form;

      for (var key in form) {
        var value = form[key];
        content.push(encodeURIComponent(key) + '=' + encodeURIComponent(value));
      }

      params = content.join('&');
      if (method === 'GET' ? '?' : '') params = '?' + params;
    }

    var request = new XMLHttpRequest;
    request.open(method, method === 'GET' ? url + params : url);

    if (params && method != 'GET') {
      request.setRequestHeader('Content-Type', FORM_MIME_TYPE);
      request.data = params;
    }

    return request;
  };

  AJAXTransport.prototype.pollForPendingOutput = function() {
    var request = this.createRequest('GET', this.url.pendingOutput, {
      form: { uid: this.uid }
    });

    var self = this;
    request.onreadystatechange = function() {
      if (request.readyState === XMLHttpRequest.DONE) {
        if (request.status === 200) {
          self.emit('pendingOutput', request.responseText);
          self.pollForPendingOutput();
        } else {
          self.emit('disconnect', request);
        }
      }
    };

    request.send(null);
  };

  // Send the input to the server.
  //
  // Each key press is encoded to an intermediate format, before it is sent to
  // the server.
  //
  // RVT#keysPressed is an alias for RVT#sendInput.
  AJAXTransport.prototype.sendInput = function(input) {
    input || (input = '');

    if (this.disconnected) return;
    if (this.sendingInput) return this.pendingInput += input;

    // Indicate that we are starting to send input.
    this.sendingInput = true;

    var request = this.createRequest('PUT', this.url.input, {
      form: { input: this.pendingInput + input, uid: this.uid }
    });

    // Clear the pending input.
    this.pendingInput = '';

    var self = this;
    request.onreadystatechange = function() {
      if (request.readyState === XMLHttpRequest.DONE) {
        self.sendingInput = false;
        if (self.pendingInput) self.sendInput();
      }
    };

    request.send(request.data);
  };

  // Send the terminal configuration to the server.
  //
  // Right now by configuration, we understand the terminal width and terminal
  // height.
  AJAXTransport.prototype.sendConfiguration = function(cols, rows) {
    if (this.disconnected) return;

    var request = this.createRequest('PUT', this.url.configuration, {
      form: { width: cols, height: rows, uid: this.uid }
    });

    // Just send the configuration and don't care about any output.
    request.send(request.data);
  };

  return AJAXTransport;

}).call(this, RVT);

window.addEventListener('load', function() {

  var terminal = window.terminal = new RVT.Terminal(RVT.config.terminal);

  terminal.open(document.querySelector('#terminal'));

  terminal.on('resize', function(options) {
    transport.emit('configuration', options.cols, options.rows);
  });

  terminal.on('data', function(data) {
    transport.emit('input', data);
  });

  var transport = new AJAXTransport(RVT.config.transport);

  transport.on('pendingOutput', function(response) {
    var json = JSON.parse(response);
    if (json.output) terminal.write(json.output);
  });

  transport.on('disconnect', function() {
    terminal.destroy();
  });

  transport.emit('initialization', function() {
    terminal.fit();
    terminal.toggleFullScreen();
    terminal.focus();
  });

});
