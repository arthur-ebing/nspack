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

      r.on 'multi_bin_weighing' do
      end
    end
  end

  # def bin_tipping_response(res)
  #   if res.success
  #     MesscadaApp::RobotFeedback.new(device: params[:device],
  #                                    status: true,
  #                                    line1: "#{res.message} - run:#{res.instance[:run_id]}, tipped: #{res.instance[:bins_tipped]}",
  #                                    line2: "farm:#{res.instance[:farm_code]}",
  #                                    line3: "puc:#{res.instance[:puc_code]}",
  #                                    line4: "orch:#{res.instance[:orchard_code]}",
  #                                    line5: "cult group: #{res.instance[:cultivar_group_code]}",
  #                                    line6: "cult:#{res.instance[:cultivar_name]}",
  #                                    short1: res.message,
  #                                    short2: "run:#{res.instance[:run_id]}, tipped: #{res.instance[:bins_tipped]}",
  #                                    short3: "farm:#{res.instance[:farm_code]}, puc:#{res.instance[:puc_code]}, orch:#{res.instance[:orchard_code]}",
  #                                    short4: "cult: #{res.instance[:cultivar_group_code]}, / #{res.instance[:cultivar_name]}")
  #   else
  #     MesscadaApp::RobotFeedback.new(device: params[:device],
  #                                    status: false,
  #                                    line1: unwrap_failed_response(res))
  #   end
  # end
end
# rubocop:enable Metrics/BlockLength
