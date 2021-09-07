# frozen_string_literal: true

class Nspack < Roda
  route 'browser', 'messcada' do |r|
    # --------------------------------------------------------------------------
    # ROBOT page loader
    # --------------------------------------------------------------------------
    r.on 'robot' do
      interactor = MesscadaApp::MesscadaInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      device = interactor.device_code_from_ip_address(request.ip, params)
      raise Crossbeams::TaskNotPermittedError, 'This is not a valid robot' if device.nil?

      # device = if params[:device] && AppConst.development?
      #            params[:device]
      #          else
      #            # 'CLM-06' # Get from system_resource for this ip address...
      #            ProductionApp::ResourceRepo.new.device_code_from_ip_address(request.ip)
      #          end
      # use ip address
      # Get device from ip address
      # robot_interactor to handle robot-building methods?
      # get device from ip

      r.is do
        @robot_page = interactor.build_robot(device)
        view('browser_robot_page', layout: 'layout_browser_robot')
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
      # { device: device, packpoint: packpoint, card_reader: '', bin_number: bin_number, identifier: identifier, identifier_is_person: true }
      # params = xml_interpreter.params_for_carton_labeling
      # res = MesscadaApp::AddSystemResourceIncentiveToParams.call(params)
      res = MesscadaApp::AddSystemResourceIncentiveToParams.call(params, has_button: true)
      # res = interactor.carton_labeling(res.instance) if res.success
      res = interactor.send_label_to_printer(res.instance) if res.success
      # res = interactor.carton_labeling(res.instance) if res.success
      # res = MesscadaApp::AddSystemResourceIncentiveToParams.call(params, has_button: true)
      # res = interactor.carton_labeling(res.instance) if res.success
      # res = interactor.browser_carton_label(params)
      if res.success
        # append to printlog
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
