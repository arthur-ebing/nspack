# frozen_string_literal: true

class Nspack < Roda
  route 'rmt_bin_weighing', 'messcada' do |r|
    # --------------------------------------------------------------------------
    # RMT BIN WEIGHING
    # view-source:http://192.168.50.32:9296/messcada/rmt_bin_weighing?bin_number=1234&gross_weight=600.23&measurement_unit=KG
    # --------------------------------------------------------------------------
    r.on do
      interactor = MesscadaApp::MesscadaInteractor.new(current_user, {}, { route_url: request.path }, {})

      r.is do
        r.get do       # WEIGH BIN
          res = interactor.update_rmt_bin_weights(params)
          if res.success
            wrap_content_in_style("<BinWeighing Status='true' Red='false' Green='true' Orange='false' Msg='#{res.message}' LCD1='' LCD2='' LCD3='' LCD4='' LCD5='' LCD6='' /> ", nil)
          else
            wrap_content_in_style("<BinWeighing Status='false' Red='true' Green='false' Orange='false' Msg='#{res.message}' LCD1='' LCD2='' LCD3='' LCD4='' LCD5='' LCD6='' /> ", nil)
          end
        end
      end
    end
  end
end
