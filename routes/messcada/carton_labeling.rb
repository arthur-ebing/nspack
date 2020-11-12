# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda
  route 'production', 'messcada' do |r|
    # --------------------------------------------------------------------------
    # CARTON/FG BIN LABELING
    # view-source:http://192.168.50.106:9296/messcada/production/carton_labeling?device=CLM-101B1
    # --------------------------------------------------------------------------
    r.on 'carton_labeling' do
      interactor = MesscadaApp::MesscadaInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.is do
        r.get do
          res = interactor.merge_system_resource_incentive(params, has_button: true)
          res = interactor.carton_labeling(res.instance) if res.success
          if res.success
            res.instance
          else
            feedback = MesscadaApp::RobotFeedback.new(device: params[:device],
                                                      status: false,
                                                      msg: unwrap_failed_response(res),
                                                      line1: 'Label printing failed',
                                                      line6: 'Label printing failed')
            Crossbeams::RobotResponder.new(feedback).render
          end
        end
      end
    end

    r.on 'carton_verification' do
      interactor = MesscadaApp::MesscadaInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'weighing' do # rubocop:disable Metrics/BlockLength
        r.on 'labeling' do
          # --------------------------------------------------------------------------
          # CARTON/FG BIN VERIFICATION + WEIGHING + LABELING
          # view-source:http://192.168.50.106:9296/messcada/production/carton_verification/weighing/labeling?carton_number=123&gross_weight=600.23&measurement_unit=kg&device=CLM-01-B01
          # --------------------------------------------------------------------------

          r.get do
            res = interactor.carton_verification_and_weighing_and_labeling(params, request.ip)
            feedback = if res.success
                         MesscadaApp::RobotFeedback.new(device: params[:device],
                                                        status: true,
                                                        line1: res.message)
                       else
                         MesscadaApp::RobotFeedback.new(device: params[:device],
                                                        status: false,
                                                        line1: unwrap_failed_response(res))
                       end
            Crossbeams::RobotResponder.new(feedback).render
          end
        end

        # --------------------------------------------------------------------------
        # CARTON/FG BIN VERIFICATION + WEIGHING
        # view-source:http://192.168.50.106:9296/messcada/production/carton_verification/weighing?carton_number=123&gross_weight=600.23&measurement_unit=kg&device=CLM-01-B01
        # --------------------------------------------------------------------------
        r.get do
          res = interactor.carton_verification_and_weighing(params)
          feedback = if res.success
                       MesscadaApp::RobotFeedback.new(device: params[:device],
                                                      status: true,
                                                      line1: res.message)
                     else
                       MesscadaApp::RobotFeedback.new(device: params[:device],
                                                      status: false,
                                                      line1: unwrap_failed_response(res))
                     end
          Crossbeams::RobotResponder.new(feedback).render
        end
      end

      # --------------------------------------------------------------------------
      # PURE CARTON/FG BIN VERIFICATION
      # view-source:http://192.168.50.106:9296/messcada/production/carton_verification?carton_number=123&device=CLM-01-B01
      # --------------------------------------------------------------------------
      r.get do
        res = interactor.carton_verification(params)
        feedback = if res.success
                     MesscadaApp::RobotFeedback.new(device: params[:device],
                                                    status: true,
                                                    line1: res.message)
                   else
                     MesscadaApp::RobotFeedback.new(device: params[:device],
                                                    status: false,
                                                    line1: unwrap_failed_response(res))
                   end
        Crossbeams::RobotResponder.new(feedback).render
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
