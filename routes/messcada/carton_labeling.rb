# frozen_string_literal: true

class Nspack < Roda
  route 'carton_labeling', 'messcada' do |r| # rubocop:disable Metrics/BlockLength
    # --------------------------------------------------------------------------
    # CARTON/FG BIN LABELING
    # view-source:http://192.168.50.106:9296/messcada/carton_labeling?device=CLM-101B1
    # --------------------------------------------------------------------------
    r.on do # rubocop:disable Metrics/BlockLength
      interactor = MesscadaApp::MesscadaInteractor.new(current_user, {}, { route_url: request.path }, {})

      r.is do # rubocop:disable Metrics/BlockLength
        r.get do # rubocop:disable Metrics/BlockLength
          res = interactor.carton_labeling(params)
          if res.success
            wrap_content_in_style("<label><status>true</status>
            <template>#{res.instance[:label_name]}</template>
            <quantity>1</quantity>
            #{res.instance[:print_command]}
            <lcd1>Label #{res.instance[:label_name]}</lcd1>
            <lcd2>Label printed...</lcd2>
            <lcd3></lcd3>
            <lcd4></lcd4>
            <lcd5></lcd5>
            <lcd6></lcd6>
            <msg>#{res.message}</msg>
            </label>", nil)
          else
            wrap_content_in_style("<label><status>false</status>
            <template>#{res.instance[:label_name]}</template>
            <quantity>1</quantity>
            #{res.instance[:print_command]}
            <lcd1>Label #{res.instance[:label_name]}</lcd1>
            <lcd2>Label printing failed</lcd2>
            <lcd3></lcd3>
            <lcd4></lcd4>
            <lcd5></lcd5>
            <lcd6>Label printing failed.</lcd6>
            <msg>#{unwrap_failed_response(res)}</msg>
            </label>", nil)
          end
        end
      end
    end
  end
end
