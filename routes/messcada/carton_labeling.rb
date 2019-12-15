# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'production', 'messcada' do |r|
    # --------------------------------------------------------------------------
    # CARTON/FG BIN LABELING
    # view-source:http://192.168.50.106:9296/messcada/production/carton_labeling?device=CLM-101B1
    # --------------------------------------------------------------------------
    r.on 'carton_labeling' do
      interactor = MesscadaApp::MesscadaInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})

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

    r.on 'carton_verification' do
      interactor = MesscadaApp::MesscadaInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on 'weighing' do # rubocop:disable Metrics/BlockLength
        r.on 'labeling' do
          # --------------------------------------------------------------------------
          # CARTON/FG BIN VERIFICATION + WEIGHING + LABELING
          # view-source:http://192.168.50.106:9296/messcada/production/carton_verification/weighing/labeling?carton_number=123&gross_weight=600.23&measurement_unit=kg&device=CLM-01-B01
          # --------------------------------------------------------------------------

          # r.on do
          # r.is do
          r.get do
            res = interactor.carton_verification_and_weighing_and_labeling(params, request.ip)
            if res.success
              <<~HTML
                <carton_verification>
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
                </carton_verification>
              HTML
              # wrap_content_in_style("<CartonVerification Status='true' Red='false' Green='true' Orange='false' Msg='#{res.message}' LCD1='' LCD2='' LCD3='' LCD4='' LCD5='' LCD6='' /> ", nil)
            else
              <<~HTML
                <carton_verification>
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
                </carton_verification>
              HTML
              # wrap_content_in_style("<CartonVerification Status='false' Red='true' Green='false' Orange='false' Msg='#{unwrap_failed_response(res)}' LCD1='' LCD2='' LCD3='' LCD4='' LCD5='' LCD6='' /> ", nil)
            end
          end
          # end
          # end
        end

        # --------------------------------------------------------------------------
        # CARTON/FG BIN VERIFICATION + WEIGHING
        # view-source:http://192.168.50.106:9296/messcada/production/carton_verification/weighing?carton_number=123&gross_weight=600.23&measurement_unit=kg&device=CLM-01-B01
        # --------------------------------------------------------------------------
        # r.on do
        #   r.is do
        r.get do
          res = interactor.carton_verification_and_weighing(params)
          if res.success
            <<~HTML
              <carton_verification>
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
              </carton_verification>
            HTML
            # wrap_content_in_style("<CartonVerification Status='true' Red='false' Green='true' Orange='false' Msg='#{res.message}' LCD1='' LCD2='' LCD3='' LCD4='' LCD5='' LCD6='' /> ", nil)
          else
            <<~HTML
              <carton_verification>
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
              </carton_verification>
            HTML
            # wrap_content_in_style("<CartonVerification Status='false' Red='true' Green='false' Orange='false' Msg='#{unwrap_failed_response(res)}' LCD1='' LCD2='' LCD3='' LCD4='' LCD5='' LCD6='' /> ", nil)
          end
        end
        #   end
        # end
      end

      # --------------------------------------------------------------------------
      # PURE CARTON/FG BIN VERIFICATION
      # view-source:http://192.168.50.106:9296/messcada/production/carton_verification?carton_number=123&device=CLM-01-B01
      # --------------------------------------------------------------------------
      r.on do
        r.is do
          r.get do
            res = interactor.carton_verification(params)
            if res.success
              <<~HTML
                <carton_verification>
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
                </carton_verification>
              HTML
              # wrap_content_in_style("<CartonVerification Status='true' Red='false' Green='true' Orange='false' Msg='#{res.message}' LCD1='' LCD2='' LCD3='' LCD4='' LCD5='' LCD6='' /> ", nil)
            else
              <<~HTML
                <carton_verification>
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
                </carton_verification>
              HTML
              # wrap_content_in_style("<CartonVerification Status='false' Red='true' Green='false' Orange='false' Msg='#{unwrap_failed_response(res)}' LCD1='' LCD2='' LCD3='' LCD4='' LCD5='' LCD6='' /> ", nil)
            end
          end
        end
      end
    end

    # --------------------------------------------------------------------------
    # FG PALLET WEIGHING
    # view-source:http://192.168.50.106:9296/messcada/production/fg_pallet_weighing?pallet_number=123&gross_weight=600.23&measurement_unit=kg
    # --------------------------------------------------------------------------
    # r.on 'fg' do
    #   r.on 'pallet_weighing' do
    #     interactor = MesscadaApp::MesscadaInteractor.new(system_user, {}, { route_url: request.path, request_ip: request.ip }, {})
    #     r.on do
    #       r.is do
    #         r.get do
    #           res = interactor.fg_pallet_weighing(params)
    #           if res.success
    #             <<~HTML
    #               <fg_pallet_weighing>
    #                 <status>true</status>
    #                 <red>false</red>
    #                 <green>true</green>
    #                 <orange>false</orange>
    #                 <msg>#{res.message}</msg>
    #                 <lcd1></lcd1>
    #                 <lcd2></lcd2>
    #                 <lcd3></lcd3>
    #                 <lcd4></lcd4>
    #                 <lcd5></lcd5>
    #                 <lcd6></lcd6>
    #               </fg_pallet_weighing>
    #             HTML
    #           else
    #             <<~HTML
    #               <fg_pallet_weighing>
    #                 <status>false</status>
    #                 <red>true</red>
    #                 <green>false</green>
    #                 <orange>false</orange>
    #                 <msg>#{unwrap_failed_response(res)}</msg>
    #                 <lcd1></lcd1>
    #                 <lcd2></lcd2>
    #                 <lcd3></lcd3>
    #                 <lcd4></lcd4>
    #                 <lcd5></lcd5>
    #                 <lcd6></lcd6>
    #               </fg_pallet_weighing>
    #             HTML
    #           end
    #         end
    #       end
    #     end
    #   end
    # end
  end
end
# rubocop:enable Metrics/BlockLength
