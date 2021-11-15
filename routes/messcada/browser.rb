# frozen_string_literal: true

class Nspack < Roda
  route 'browser', 'messcada' do |r|
    # --------------------------------------------------------------------------
    # ROBOT page loader
    # --------------------------------------------------------------------------
    r.on 'robot' do
      interactor = MesscadaApp::MesscadaInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      res = interactor.device_code_from_ip_address(request.ip, params)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success

      device = res.instance # This could be more - include printer

      r.is do
        @robot_page = interactor.build_robot(device)
        view('browser_robot_page', layout: 'layout_browser_robot')
      end
    end

    r.on 'robot_re_terminal' do
      interactor = MesscadaApp::MesscadaInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      res = interactor.device_code_from_ip_address(request.ip, params)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success

      device = res.instance # This could be more - include printer

      r.is do
        @robot_page = interactor.build_robot(device)
        view('re_terminal_page', layout: 'layout_browser_robot')
      end
    end

    r.on 'login_status', String do |device|
      interactor = MesscadaApp::MesscadaInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      res = interactor.login_state(device)
      # device = params[:device]

      { success: true, message: res.message, payload: res.instance }.to_json
    end

    r.on 'carton_labeling' do
      interactor = MesscadaApp::MesscadaInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      res = MesscadaApp::AddSystemResourceIncentiveToParams.call(params, has_button: true)

      res = interactor.check_carton_label_weight(res.instance) if res.success && r.remaining_path == '/weighing'

      res = interactor.send_label_to_printer(res.instance) if res.success
      if res.success
        show_json_notice(res.message)
      else
        show_json_exception(res.message)
      end

      # r.is do
      #   r.get do
      #     res = MesscadaApp::AddSystemResourceIncentiveToParams.call(params, has_button: true)
      #     res = interactor.carton_labeling(res.instance) if res.success
      #     if res.success
      #       res.instance
      #     else
      #       feedback = MesscadaApp::RobotFeedback.new(device: params[:device],
      #                                                 status: false,
      #                                                 msg: unwrap_failed_response(res),
      #                                                 line1: 'Label printing failed',
      #                                                 line6: 'Label printing failed')
      #       Crossbeams::RobotResponder.new(feedback).render
      #     end
      #   end
      # end
    end
  end
end
