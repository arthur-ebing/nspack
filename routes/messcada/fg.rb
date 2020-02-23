# frozen_string_literal: true

class Nspack < Roda
  route 'fg', 'messcada' do |r|
    # --------------------------------------------------------------------------
    # CARTON/FG BIN LABELING
    # view-source:http://192.168.50.106:9296/messcada/production/carton_labeling?device=CLM-101B1
    # --------------------------------------------------------------------------
    r.on 'pallet_weighing' do
      interactor = MesscadaApp::MesscadaInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on do
        r.is do
          r.get do
            res = interactor.fg_pallet_weighing(params)
            feedback = if res.success
                         MesscadaApp::RobotFeedback.new(device: params[:device],
                                                        status: true,
                                                        line2: "Pallet: #{res.instance[:pallet_number]}",
                                                        line3: "Weight: #{res.instance[:gross_weight]}")
                       else
                         MesscadaApp::RobotFeedback.new(device: params[:device],
                                                        status: false,
                                                        msg: unwrap_failed_response(res))
                       end
            Crossbeams::RobotResponder.new(feedback).render
          end
        end
      end
    end
  end
end
