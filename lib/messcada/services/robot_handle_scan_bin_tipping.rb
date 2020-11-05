# frozen_string_literal: true

module MesscadaApp
  class RobotHandleScanBinTipping < BaseService
    attr_reader :robot_interface, :robot, :robot_params, :request, :system_user

    def initialize(robot_interface)
      @robot_interface = robot_interface
      @robot = robot_interface.robot
      @robot_params = robot_interface.robot_params
      @request = robot_interface.request
      @system_user = robot_interface.system_user
    end

    def call # rubocop:disable Metrics/AbcSize
      interactor = MesscadaApp::MesscadaInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      params = { bin_number: robot_params[:barcode], device: robot.system_resource_code }
      res = interactor.tip_rmt_bin(params)
      # TODO: Handle needs supervisor etc. Also for KR, create bin from old system if it does not exist...
      feedback = interactor.bin_tipping_response(res, params)
      robot_interface.respond(feedback, res.success)

      # BINTIP states...
      # - scan : invalid (already tipped, can't find bin -- log somewhere line/run/supervisor/run :: unknown_bins_tipped table linked to runs)
      # - supervisor logon
      # - allow: yes: B3, no: B4
      # - or scan valid bin (clears state)
    end
  end
end
