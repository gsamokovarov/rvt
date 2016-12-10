require 'test_helper'

module RVT
  class ConsoleSessionsControllerTest < ActionController::TestCase
    setup do
      PTY.stubs(:spawn).returns([StringIO.new, StringIO.new, Random.rand(20000)])
      RVT.config.whitelisted_ips.stubs(:include?).returns(true)
    end

    test 'index is successful' do
      get :index, use_route: 'rvt'
      assert_response :success
    end

    test 'GET index creates new console session' do
      assert_difference 'ConsoleSession::INMEMORY_STORAGE.size' do
        get :index, use_route: 'rvt'
      end
    end

    test 'PUT input validates for missing input' do
      get :index, use_route: 'rvt'

      assert_not_nil console_session = assigns(:console_session)

      console_session.instance_variable_get(:@slave).stubs(:send_input).raises(ArgumentError)
      put :input, id: console_session.pid, uid: console_session.uid, use_route: 'rvt'

      assert_response :unprocessable_entity
    end

    test 'PUT input sends input to the slave' do
      get :index, use_route: 'rvt'

      assert_not_nil console_session = assigns(:console_session)

      console_session.expects(:send_input)
      put :input, use_route: 'rvt', input: ' ', id: console_session.pid, uid: console_session.uid
    end

    test 'GET pending_output gives the slave pending output' do
      get :index, use_route: 'rvt'

      assert_not_nil console_session = assigns(:console_session)
      console_session.expects(:pending_output)

      get :pending_output, use_route: 'rvt', id: console_session.pid, uid: console_session.uid
    end

    test 'GET pending_output raises 410 on exited slave processes' do
      get :index, use_route: 'rvt'

      assert_not_nil console_session = assigns(:console_session)
      console_session.stubs(:pending_output).raises(ConsoleSession::Unavailable)

      get :pending_output, use_route: 'rvt', id: console_session.pid, uid: console_session.uid
      assert_response :gone
    end

    test 'PUT configuration adjust the terminal size' do
      get :index, use_route: 'rvt'

      assert_not_nil console_session = assigns(:console_session)
      console_session.expects(:configure).with(
        'id'     => console_session.pid.to_s,
        'uid'    => console_session.uid,
        'width'  => '80',
        'height' => '24',
      )

      put :configuration, id: console_session.pid, uid: console_session.uid, width: 80, height: 24, use_route: 'rvt'
      assert_response :success
    end

    test 'blocks requests from non-whitelisted ips' do
      RVT.config.whitelisted_ips.stubs(:include?).returns(false)
      get :index, use_route: 'rvt'
      assert_response :unauthorized
    end

    test 'allows requests from whitelisted ips' do
      RVT.config.whitelisted_ips.stubs(:include?).returns(true)
      get :index, use_route: 'rvt'
      assert_response :success
    end

    private

    def get(*)
      ActiveSupport::Deprecation.silence { super }
    end

    def put(*)
      ActiveSupport::Deprecation.silence { super }
    end
  end
end
