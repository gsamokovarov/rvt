require 'pty'
require 'stringio'
require 'test_helper'

module RVT
  class SlaveTest < ActiveSupport::TestCase
    setup do
      PTY.stubs(:spawn).returns([StringIO.new, StringIO.new, Random.rand(20000)])
      @slave = Slave.new
    end

    test '#send_input raises ArgumentError on bad input' do
      assert_raises(ArgumentError) { @slave.send_input(nil) }
      assert_raises(ArgumentError) { @slave.send_input('') }
    end

    test '#pending_output returns nil on no pending output' do
      @slave.stubs(:pending_output?).returns(false)
      assert_nil @slave.pending_output
    end

    test '#pending_output returns a string with the current output' do
      @slave.stubs(:pending_output?).returns(true)
      @slave.instance_variable_get(:@output).stubs(:read_nonblock).returns('foo', nil)
      assert_equal 'foo', @slave.pending_output
    end

    test '#pending_output always encodes output in UTF-8' do
      @slave.stubs(:pending_output?).returns(true)
      @slave.instance_variable_get(:@output).stubs(:read_nonblock).returns('foo', nil)
      assert_equal Encoding::UTF_8, @slave.pending_output.encoding
    end

    Slave::READING_ON_CLOSED_END_ERRORS.each do |exception|
      test "#pending_output raises Slave::Closed when the end raises #{exception}" do
        @slave.stubs(:pending_output?).returns(true)
        @slave.instance_variable_get(:@output).stubs(:read_nonblock).raises(exception)

        assert_raises(Slave::Closed) { @slave.pending_output }
      end
    end

    test '#configure changes @input dimentions' do
      @slave.instance_variable_get(:@input).expects(:winsize=).with([32, 64])
      @slave.configure(height: 32, width: 64)
    end

    test '#configure only changes the @input dimentions if width is zero' do
      @slave.instance_variable_get(:@input).expects(:winsize=).never
      @slave.configure(height: 32, width: 0)
    end

    test '#configure only changes the @input dimentions if height is zero' do
      @slave.instance_variable_get(:@input).expects(:winsize=).never
      @slave.configure(height: 0, width: 64)
    end

    { dispose: :SIGTERM, dispose!: :SIGKILL }.each do |method, signal|
      test "##{method} sends #{signal} to the process and detaches it" do
        Process.expects(:kill).with(signal, @slave.pid)
        @slave.public_send(method)
      end

      test "##{method} can reraise Errno::ESRCH if requested" do
        Process.expects(:kill).with(signal, @slave.pid)
        Process.stubs(:detach).raises(Errno::ESRCH)

        assert_raises(Errno::ESRCH) { @slave.public_send(method, raise: true) }
      end
    end
  end
end
