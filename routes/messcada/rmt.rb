# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda
  route 'rmt', 'messcada' do |r| # rubocop:disable Metrics/BlockLength
    # --------------------------------------------------------------------------
    # RMT BIN WEIGHING
    # view-source:http://192.168.43.254:9296/messcada/rmt/bin_weighing?bin_number=1234&gross_weight=600.23&measurement_unit=KG
    # --------------------------------------------------------------------------
    r.on 'bin_weighing' do
      interactor = MesscadaApp::MesscadaInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.is do
        r.get do       # WEIGH BIN
          res = interactor.update_rmt_bin_weights(params)
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

    # --------------------------------------------------------------------------
    # RMT BIN TIPPING
    # view-source:http://192.168.43.254:9296/messcada/rmt/bin_tipping?bin_number=1234&device=BTM-01
    # --------------------------------------------------------------------------
    r.on 'bin_tipping' do
      interactor = MesscadaApp::MesscadaInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      r.is do
        r.get do       # TIP BIN
          res = interactor.tip_rmt_bin(params)
          feedback = interactor.bin_tipping_response(res, params)
          Crossbeams::RobotResponder.new(feedback).render
        end
      end

      # --------------------------------------------------------------------------
      # RMT BIN TIPPING/WEIGHING
      # view-source:192.168.43.254:9296/messcada/rmt/bin_tipping/weighing?bin_number=12345&gross_weight=600.23&measurement_unit=kg&device=BTM-01
      # --------------------------------------------------------------------------
      r.on 'weighing' do       # WEIGH/TIP BIN
        interactor.update_bin_weights_and_tip_bin(params)
      end

      # --------------------------------------------------------------------------
      # RMT BIN TIPPING/WEIGHING
      # view-source:http://192.168.43.254:9296/messcada/rmt/bin_tipping/multi_bin_weighing?bin_number=11111803,11111804&gross_weight=600.23&measurement_unit=kg&device=CLM-0226
      # --------------------------------------------------------------------------
      r.on 'multi_bin_weighing' do
        interactor.multi_update_bin_weights_and_tip_bin(params)
      end
    end

    # --------------------------------------------------------------------------
    # CAN TIP BIN
    # view-source:http://192.168.43.254:9296/messcada/rmt/can_tip_bin?bin_number=1234&device=BTM-01
    # --------------------------------------------------------------------------
    r.on 'can_tip_bin' do
      interactor = MesscadaApp::MesscadaInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})

      res = interactor.can_tip_bin?(params)
      feedback = interactor.bin_tipping_response(res, params)
      Crossbeams::RobotResponder.new(feedback).render
    end
  end
end
# rubocop:enable Metrics/BlockLength
