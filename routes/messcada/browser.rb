# frozen_string_literal: true

class Nspack < Roda
  route 'browser', 'messcada' do |r|
    # --------------------------------------------------------------------------
    # ROBOT page loader
    # --------------------------------------------------------------------------
    r.on 'robot' do
      interactor = MesscadaApp::MesscadaInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      # robot_interactor to handle robot-building methods?
      # get device from ip

      r.is do
        @robot_page = interactor.build_robot
        view('browser_robot_page', layout: 'layout_browser_robot')
      end
    end
  end
end
