# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
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
            if res.success
              <<~HTML
                <bin_tipping>
                  <status>true</status>
                  <red>false</red>
                  <green>true</green>
                  <orange>false</orange>
                  <msg>#{res.message}</msg>
                  <lcd1></lcd1>
                  <lcd2></lcd2>
                  <lcd3></lcd3>
                  <lcd4></lcd4>
                  <lcd5></lcd5>
                  <lcd6></lcd6>
                </bin_tipping>
              HTML
            else
              <<~HTML
                <bin_tipping>
                  <status>false</status>
                  <red>true</red>
                  <green>false</green>
                  <orange>false</orange>
                  <msg>#{unwrap_failed_response(res)}</msg>
                  <lcd1></lcd1>
                  <lcd2></lcd2>
                  <lcd3></lcd3>
                  <lcd4></lcd4>
                  <lcd5></lcd5>
                  <lcd6></lcd6>
                </bin_tipping>
              HTML
            end
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
