require_dependency 'rvt/application_controller'

module RVT
  class ConsoleSessionsController < ApplicationController
    rescue_from ConsoleSession::Unavailable do |exception|
      render json: exception, status: :gone
    end

    rescue_from ConsoleSession::Invalid do |exception|
      render json: exception, status: :unprocessable_entity
    end

    rescue_from ConsoleSession::Unauthorized do |exception|
      render json: exception, status: :unauthorized
    end

    def index
      @console_session = ConsoleSession.create
    end

    def input
      @console_session = ConsoleSession.find_by_pid_and_uid(params[:id], params[:uid])
      @console_session.send_input(console_session_params[:input])

      render nothing: true
    end

    def configuration
      @console_session = ConsoleSession.find_by_pid_and_uid(params[:id], params[:uid])
      @console_session.configure(console_session_params)

      render nothing: true
    end

    def pending_output
      @console_session = ConsoleSession.find_by_pid_and_uid(params[:id], params[:uid])

      render json: { output: @console_session.pending_output }
    end

    private

    def console_session_params
      params.permit(:id, :uid, :input, :width, :height)
    end
  end
end
