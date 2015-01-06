require 'test_helper'

module RVT
  class ConsoleSessionTest < ActionView::TestCase
    include ActiveModel::Lint::Tests

    setup do
      PTY.stubs(:spawn).returns([StringIO.new, StringIO.new, Random.rand(20000)])
      ConsoleSession::INMEMORY_STORAGE.clear
      @model1 = @model = ConsoleSession.new
      @model2 = ConsoleSession.new
    end

    test 'raises ConsoleSession::Unavailable on not found sessions' do
      assert_raises(ConsoleSession::Unavailable) { ConsoleSession.find(-1) }
    end

    test 'find coerces ids' do
      assert_equal @model.persist, ConsoleSession.find("#{@model.pid}")
    end

    test 'not found exceptions are JSON serializable' do
      exception = assert_raises(ConsoleSession::Unavailable) { ConsoleSession.find(-1) }
      assert_equal '{"error":"Session unavailable"}', exception.to_json
    end

    test 'can be used as slave as the methods are delegated' do
      slave_methods = Slave.instance_methods - @model.methods
      slave_methods.each { |method| assert @model.respond_to?(method) }
    end

    test 'slave methods are cached on the singleton' do
      assert_not @model.singleton_methods.include?(:pending_output?)
      @model.pending_output? rescue nil
      assert @model.singleton_methods.include?(:pending_output?)
    end

    test 'persisted models knows that they are in memory' do
      assert_not @model.persisted?
      @model.persist
      assert @model.persisted?
    end

    test 'persisted models knows about their keys' do
      assert_nil @model.to_key
      @model.persist
      assert_not_nil @model.to_key
    end

    test 'create gives already persisted models' do
      assert ConsoleSession.create.persisted?
    end

    test 'no gives not persisted models' do
      assert_not ConsoleSession.new.persisted?
    end
  end
end
