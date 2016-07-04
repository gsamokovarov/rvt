require 'test_helper'

module RVT
  class ConsoleSessionsControllerTest < ActionController::TestCase
    setup do
      PTY.stubs(:spawn).returns([StringIO.new, StringIO.new, Random.rand(20000)])
      @request.stubs(:remote_ip).returns('127.0.0.1')
    end

    test 'index is successful' do
      get :index
      assert_response :success
    end

    test 'GET index creates new console session' do
      assert_difference 'ConsoleSession::INMEMORY_STORAGE.size' do
        get :index
      end
    end

    test 'PUT input validates for missing input' do
      get :index

      assert_not_nil console_session = assigns(:console_session)

      console_session.instance_variable_get(:@slave).stubs(:send_input).raises(ArgumentError)
      put :input, params: { id: console_session.pid, uid: console_session.uid }

      assert_response :unprocessable_entity
    end

    test 'PUT input sends input to the slave' do
      get :index

      assert_not_nil console_session = assigns(:console_session)

      console_session.expects(:send_input)
      put :input, params: { input: ' ', id: console_session.pid, uid: console_session.uid }
    end

    test 'GET pending_output gives the slave pending output' do
      get :index

      assert_not_nil console_session = assigns(:console_session)
      console_session.expects(:pending_output)

      get :pending_output, params: { id: console_session.pid, uid: console_session.uid }
    end

    test 'GET pending_output raises 410 on exitted slave processes' do
      get :index

      assert_not_nil console_session = assigns(:console_session)
      console_session.stubs(:pending_output).raises(ConsoleSession::Unavailable)

      get :pending_output, params: { id: console_session.pid, uid: console_session.uid }
      assert_response :gone
    end

    test 'PUT configuration adjust the terminal size' do
      get :index

      assert_not_nil console_session = assigns(:console_session)
      console_session.expects(:configure).with(
        'id'     => console_session.pid.to_s,
        'uid'    => console_session.uid,
        'width'  => '80',
        'height' => '24',
      )

      put :configuration, params: { id: console_session.pid, uid: console_session.uid, width: 80, height: 24 }
      assert_response :success
    end

    test 'blocks requests from non-whitelisted ips' do
      @request.stubs(:remote_ip).returns('128.0.0.1')
      get :index
      assert_response :unauthorized
    end

    test 'allows requests from whitelisted ips' do
      @request.stubs(:remote_ip).returns('127.0.0.1')
      get :index
      assert_response :success
    end

    test 'index generated path' do
      assert_generates mount_path, {
        controller: 'console_sessions'
      }, {}, {controller: 'console_sessions'}
    end

    private

    def mount_path
      RVT::Engine.config.rvt.default_mount_path
    end
  end
end
