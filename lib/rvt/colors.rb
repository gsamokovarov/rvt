require 'active_support/core_ext/hash/indifferent_access'

module RVT
  # = Colors
  #
  # Manages the creation and serialization of terminal color themes.
  #
  # Colors is a subclass of +Array+ and it stores a collection of CSS color
  # values, to be used from the client-side terminal.
  #
  # You can specify 8 or 16 colors and additional +background+ and +foreground+
  # colors. If not explicitly specified, +background+ and +foreground+ are
  # considered to be the first and the last of the given colors.
  class Colors < Array
    class << self
      # Registry of color themes mapped to a name.
      #
      # Don't manually alter the registry. Use RVT::Colors.register_theme
      # for adding entries.
      def themes
        @@themes ||= {}.with_indifferent_access
      end

      # Register a color theme into the color themes registry.
      #
      # Registration maps a name and Colors instance.
      #
      # If a block is given, it would be yielded with a new Colors instance to
      # populate the theme colors in.
      #
      # If a Colors instance is already instantiated it can be passed directly
      # as the second (_colors_) argument. In this case, if a block is given,
      # it won't be executed.
      def register_theme(name, colors = nil)
        themes[name] = colors || new.tap { |c| yield c }
      end

      # The default colors theme.
      def default
        self[:light]
      end

      # Shortcut for RVT::Colors.themes#[].
      def [](name)
        themes[name]
      end
    end

    alias :add :<<

    # Background color getter and setter.
    #
    # If called without arguments it acts like a getter. Otherwise it acts like
    # a setter.
    #
    # The default background color will be the first entry in the colors theme.
    def background(value = nil)
      @background   = value unless value.nil?
      @background ||= self.first
    end

    alias :background= :background

    # Foreground color getter and setter.
    #
    # If called without arguments it acts like a getter. Otherwise it acts like
    # a setter.
    #
    # The default foreground color will be the last entry in the colors theme.
    def foreground(value = nil)
      @foreground   = value unless value.nil?
      @foreground ||= self.last
    end

    alias :foreground= :foreground

    def as_json(*)
      (dup << background << foreground).to_a
    end
  end
end

require 'rvt/colors/light'
require 'rvt/colors/monokai'
require 'rvt/colors/solarized'
require 'rvt/colors/tango'
require 'rvt/colors/xterm'
