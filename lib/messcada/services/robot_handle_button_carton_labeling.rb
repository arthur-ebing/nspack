# frozen_string_literal: true

module MesscadaApp
  class RobotHandleButtonCartonLabeling < BaseService
    attr_reader :robot_interface, :robot, :robot_params, :request, :system_user

    def initialize(robot_interface)
      @robot_interface = robot_interface
      @robot = robot_interface.robot
      @robot_params = robot_interface.robot_params
      @request = robot_interface.request
      @system_user = robot_interface.system_user
    end

    def call
      params = { device: "#{robot.system_resource_code}-#{robot_params[:button]}", card_reader: '', identifier: robot_params[:id] }
      feedback = MesscadaApp::RobotFeedback.new(device: params[:device],
                                                status: true,
                                                short1: 'Label printed')
      robot_interface.respond(feedback, true, type: :user)
    end
  end
end
