# frozen_string_literal: true

class Nspack < Roda
  route 'production', 'messcada' do |r|
    # --------------------------------------------------------------------------
    # CARTON/FG BIN LABELING
    # view-source:http://192.168.50.106:9296/messcada/production/carton_labeling?device=CLM-101B1
    # --------------------------------------------------------------------------
    r.on 'carton_labeling' do
      interactor = MesscadaApp::MesscadaInteractor.new(system_user, {}, { route_url: request.path }, {})

      r.is do
        r.get do
          res = interactor.carton_labeling(params)
          if res.success
            <<~HTML
              #{res.instance}
            HTML
          else
            <<~HTML
              <label><status>false</status>
              <lcd1>Label printing failed</lcd1>
              <lcd2></lcd2>
              <lcd3></lcd3>
              <lcd4></lcd4>
              <lcd5></lcd5>
              <lcd6>Label printing failed.</lcd6>
              <msg>#{unwrap_failed_response(res)}</msg>
              </label>
            HTML
          end
        end
      end
    end
  end
end
