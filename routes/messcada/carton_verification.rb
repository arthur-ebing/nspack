# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'carton_verification', 'messcada' do |r| # rubocop:disable Metrics/BlockLength
    # CARTON/FG BIN VERIFICATION

    interactor = MesscadaApp::MesscadaInteractor.new(system_user, {}, { route_url: request.path }, {})
    r.on 'weighing' do # rubocop:disable Metrics/BlockLength
      r.on 'labeling' do
        # --------------------------------------------------------------------------
        # CARTON/FG BIN VERIFICATION + WEIGHING + LABELING
        # view-source:http://192.168.50.106:9296/messcada/carton_verification/weighing/labeling?carton_number=123&gross_weight=600.23&measurement_unit=kg&device=CLM-01-B01
        # --------------------------------------------------------------------------

        r.on do
          r.is do
            r.get do
              res = interactor.carton_verification_and_weighing_and_labeling(params)
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
      # CARTON/FG BIN VERIFICATION + WEIGHING
      # view-source:http://192.168.50.106:9296/messcada/carton_verification/weighing?carton_number=123&gross_weight=600.23&measurement_unit=kg&device=CLM-01-B01
      # --------------------------------------------------------------------------
      r.on do
        r.is do
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
        end
      end
    end

    # --------------------------------------------------------------------------
    # PURE CARTON/FG BIN VERIFICATION
    # view-source:http://192.168.50.106:9296/messcada/carton_verification?carton_number=123&device=CLM-01-B01
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
end
# rubocop:enable Metrics/BlockLength
