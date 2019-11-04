# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'rmt', 'messcada' do |r| # rubocop:disable Metrics/BlockLength
    # --------------------------------------------------------------------------
    # RMT BIN WEIGHING
    # view-source:http://192.168.43.254:9296/messcada/rmt/bin_weighing?bin_number=1234&gross_weight=600.23&measurement_unit=KG
    # --------------------------------------------------------------------------
    r.on 'bin_weighing' do
      interactor = MesscadaApp::MesscadaInteractor.new(system_user, {}, { route_url: request.path }, {})

      r.is do
        r.get do       # WEIGH BIN
          res = interactor.update_rmt_bin_weights(params)
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

    # --------------------------------------------------------------------------
    # RMT BIN TIPPING
    # view-source:http://192.168.43.254:9296/messcada/rmt/bin_tipping?bin_number=1234&device=BTM-01
    # --------------------------------------------------------------------------
    r.on 'bin_tipping' do
      interactor = MesscadaApp::MesscadaInteractor.new(system_user, {}, { route_url: request.path }, {})

      r.is do
        r.get do       # TIP BIN
          res = interactor.tip_rmt_bin(params)
          bin_tipping_response(res)
        end
      end

      # --------------------------------------------------------------------------
      # RMT BIN TIPPING/WEIGHING
      # view-source:192.168.43.254:9296/messcada/rmt/bin_tipping/weighing?bin_number=12345&gross_weight=600.23&measurement_unit=kg&device=BTM-01
      # --------------------------------------------------------------------------
      r.on 'weighing' do       # WEIGH/TIP BIN
        res = interactor.update_rmt_bin_weights(params)
        if res.success
          res = interactor.tip_rmt_bin(params) # if this fails, should interactor.update_rmt_bin_weights be allowed to commit?
          bin_tipping_response(res)
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

  def bin_tipping_response(res) # rubocop:disable Metrics/AbcSize
    if res.success
      <<~HTML
        <bin_tipping>
          <status>true</status>
          <red>false</red>
          <green>true</green>
          <orange>false</orange>
          <msg></msg>
          <lcd1>#{res.message} - run:#{res.instance[:run_id]}, tipped: #{res.instance[:bins_tipped]}</lcd1>
          <lcd2>farm:#{res.instance[:farm_code]}</lcd2>
          <lcd3>puc:#{res.instance[:puc_code]}</lcd3>
          <lcd4>orch:#{res.instance[:orchard_code]}</lcd4>
          <lcd5>cult group: #{res.instance[:cultivar_group_code]}</lcd5>
          <lcd6>cult:#{res.instance[:cultivar_name]}</lcd6>
        </bin_tipping>"
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
# rubocop:enable Metrics/BlockLength
