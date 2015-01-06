require 'test_helper'

module RVT
  class ColorsTest < ActiveSupport::TestCase
    setup do
      @colors = Colors.new %w( #7f7f7f #ff0000 #00ff00 #ffff00 #5c5cff #ff00ff #00ffff #ffffff )
    end

    test '.[] is an alias for .themes#[]' do
      @colors.class.themes.expects(:[]).with(:light).once
      @colors.class[:light]
    end

    test '.register_theme creates Colors instance for the block' do
      @colors.class.register_theme(:test) { |c| assert c.is_a?(Colors) }
    end

    test '#background is the first color if not specified' do
      assert_equal '#7f7f7f', @colors.background
    end

    test '#background can be explicitly specified' do
      @colors.background '#00ff00'
      assert_equal '#00ff00', @colors.background
    end

    test '#background= is an alias of #background' do
      @colors.background = '#00ff00'
      assert_equal '#00ff00', @colors.background
    end

    test '#foreground is the last color if not specified' do
      assert_equal '#ffffff', @colors.foreground
    end

    test '#foreground can be explicitly specified' do
      @colors.foreground '#f0f0f0'
      assert_equal '#f0f0f0', @colors.foreground
    end

    test '#foreground= is an alias of #foreground' do
      @colors.foreground = '#f0f0f0'
      assert_equal '#f0f0f0', @colors.foreground
    end

    test '#to_json includes the background and the foreground' do
      @colors.background = '#00ff00'
      @colors.foreground = '#f0f0f0'

      expected_json = '["#7f7f7f","#ff0000","#00ff00","#ffff00","#5c5cff","#ff00ff","#00ffff","#ffffff","#00ff00","#f0f0f0"]'
      assert_equal expected_json, @colors.to_json
    end

    test '#default is :light' do
      assert_equal @colors.class.default, @colors.class.themes[:light]
    end
  end
end
