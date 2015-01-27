![logo](https://raw.github.com/gsamokovarov/rvt/master/.logo.png)

A [VT100] compatible terminal, running on Rails.

## Requirements

_RVT_ has been tested on the following rubies.

* _MRI Ruby_ 2.2
* _MRI Ruby_ 2.1
* _MRI Ruby_ 2.0
* _MRI Ruby_ 1.9.3

_Rubunius_ in 1.9 mode may work, but it hasn't been tested.

_RVT_ has been built explicitly for _Rails 4_.

## Installation

To install it in your current application, add the following to your `Gemfile`.

```ruby
group :development do
  gem 'rvt'
end
```

After you save the `Gemfile` changes, make sure to run `bundle install` and
restart your server for the _RVT_ to take affect.

By default, it should be available in your development environment under
`/console`. The route is not automatically mounted in a production environment
and we strongly encourage you to keep it that way.

## Configuration

> Today we have learned in the agony of war that great power involves great
> responsibility.
>
> -- <cite>Franklin D. Roosevelt</cite>

_RVT_ is a powerful tool. It allows you to execute arbitrary code on
the server, so you should be very careful, who you give access to it.

### config.rvt.whitelisted_ips

By default, only requests coming from `127.0.0.1` are allowed.

`config.rvt.whitelisted_ips` lets you control which IP's have access to
the console.

Let's say you want to share your console with just that one roommate, you like
and his/her IP is `192.168.0.100`.

```ruby
class Application < Rails::Application
  config.rvt.whitelisted_ips = %w( 127.0.0.1 192.168.0.100 )
end
```

From the example, you can guess that `config.rvt.whitelisted_ips`
accepts an array of ip addresses, provided as strings. An important thing to
note here is that, we won't push `127.0.0.1` if you manually set the option!

Now let's assume you like all of your roommates. Instead of enumerating their
IP's, you can whitelist the whole private network. Now every time their IP's
change, you'll have them covered.

```ruby
class Application < Rails::Application
  config.rvt.whitelisted_ips = '192.168.0.0/16'
end
```

You can see that `config.rvt.whitelisted_ips` accepts plains strings
too. More than that, they can cover whole networks.

Again, note that this network doesn't allow `127.0.0.1`. If you want to access
the console, you have to do so from it's external IP or add `127.0.0.1` to the
mix.

### config.rvt.default_mount_path

By default, the console will be automatically mounted on `/console`.

_(This happens only in the development and test environments!)_.

Say you want to mount the console to `/debug`, so you can more easily remember
where to go, when your application needs debugging.

```ruby
class Application < Rails::Application
  config.rvt.default_mount_path = '/debug'
end
```

### config.rvt.automount

If you want to explicitly mount `RVT::Engine`, you can prevent the
automatic mount by setting this option to `false`.

### config.rvt.command

By default, _RVT_ will run `Rails.root.join('bin/rails console)` to
spawn you a fresh Rails console. If the relative `bin/rails` does not exist, it
doesn't exist, `rails console` will be run.

One of the advantages of being a [VT100] emulator is that _RVT_ can run
most of your terminal applications.

Let say _(for some reason)_ you can't run SSH on your server machine. You can
run [`login`][login] instead to let users sign into the host system.

```ruby
class Application < Rails::Application
  # You have to run /bin/login as root. That should worry you and you may work
  # around it by running ssh connecting to the same machine.
  config.rvt.command = 'sudo /bin/login'
end
```

_Poor man's solution to SSH._ ![boom](http://f.cl.ly/items/3n2h0p1w0B261u2d201b/boom.png)

**If you ever decide to use _RVT_ that way, use SSL to encrypt the
traffic, otherwise all the input (including the negotiated username and
password) can be easily sniffed!**

### config.rvt.term

By default, the _RVT_ terminal will report itself as `xterm-color`. You
can override this option to change that.

### config.rvt.timeout

You may have noticed that _RVT_ client sends a lot of requests to the
server. And by a lot, we really mean, **a lot** _(every few milliseconds)_.
We do this since we can't reliably predict when the output of your command
execution will come available, so we poll for it.

This option control how much will the server wait on the process output pipe
for input, before signalling the client to try again.

Maybe some day Web Sockets or SSE can be used for more efficient communication.
Until that day, you can use long-polling. To enable it, use [Puma] as your
development server and add the following to your configuration.

```ruby
class Application < Rails::Application
  # You have to explicitly enable the concurrency, as in development mode,
  # the falsy config.cache_classes implies no concurrency support.
  #
  # The concurrency is enabled by removing the Rack::Lock middleware, which
  # wraps each request in a mutex, effectively making the request handling
  # synchronous.
  config.allow_concurrency = true

  # For long-polling, 45 seconds timeout for the development server seems
  # reasonable. You may want to experiment with the value.
  config.rvt.timeout = 45.seconds
end
```

Styling
-------

If you would like to style the terminal a bit different than the default
appearance, you can do so with the following options.

### config.rvt.style.colors

_RVT_ supports up to 256 color themes, though most of the common
terminal themes are usually just 16 colors.

The default color theme is a white-on-black theme called `light`. For
different appearance you may want to experiment with the other included color
themes.

- `monokai` _the default Sublime Text colors_
- `solarized_dark` _light version of the common solarized colors_
- `solarized_light` _dark version of the common solarized colors_
- `tango` _theme based on the tango colors_
- `xterm` _the standard xterm theme_

If you would like to use a custom theme, you may do so with the following
syntax.

```ruby
class Application < Rails::Application
  # First, you have to define and register your custom color theme. Each color
  # theme is mapped to a name.
  RVT::Colors.register_theme(:custom) do |c|
    # The most common color themes are the 16 colors one. They are built from 3
    # parts.

    # 8 darker colors.
    c.add '#000000'
    c.add '#cd0000'
    c.add '#00cd00'
    c.add '#cdcd00'
    c.add '#0000ee'
    c.add '#cd00cd'
    c.add '#00cdcd'
    c.add '#e5e5e5'

    # 8 lighter colors.
    c.add '#7f7f7f'
    c.add '#ff0000'
    c.add '#00ff00'
    c.add '#ffff00'
    c.add '#5c5cff'
    c.add '#ff00ff'
    c.add '#00ffff'
    c.add '#ffffff'

    # Background and foreground colors.
    c.background '#ffffff'
    c.foreground '#000000'
  end

  # Now you have to tell RVT to actually use it.
  config.rvt.style.colors = :custom
end
```

### config.rvt.style.font

You may also change the font, which is following the CSS font property syntax.
By default it is `large DejaVu Sans Mono, Liberation Mono, monospace`.

## FAQ

### I'm running JRuby and the console doesn't load.

**TL;DR** Give it a bit of time, it will load.

While spawning processes is relatively cheap on _MRI_, this is not the case in
_JRuby_. Spawning another process is slow. Spawning another **JRuby** process
is even slower. Read more about the problem at the _JRuby_ [wiki].

### Changing the colors is broken.

Some of the style sheets may be cached on the file system. Run
`rake tmp:cache:clear` to clear those up.

  [Puma]: http://puma.io/
  [VT100]: http://en.wikipedia.org/wiki/VT100
  [login]: http://linux.die.net/man/1/login
  [video]: http://www.youtube.com/watch?v=zjuJRXCLkHk
  [wiki]: https://github.com/jruby/jruby/wiki/Improving-startup-time#avoid-spawning-sub-rubies
