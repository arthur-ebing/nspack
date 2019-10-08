# frozen_string_literal: true

class Nspack < Roda
  route 'rmt_bin_tipping', 'messcada' do |r| # rubocop:disable Metrics/BlockLength
    # --------------------------------------------------------------------------
    # RMT BIN TIPPING
    # --------------------------------------------------------------------------
    r.on do
      interactor = MesscadaApp::MesscadaInteractor.new(current_user, {}, { route_url: request.path }, {})

      r.is do
        r.get do       # TIP BIN
          res = interactor.tip_rmt_bin(params)
          if res.success
            wrap_content_in_style("<BinTipping Status='true' Red='false' Green='true' Orange='false' Msg='#{res.message}' LCD1='run:#{res.instance[:run_id]}, tipped: #{res.instance[:bins_tipped]}' LCD2='farm:#{res.instance[:farm_code]}' LCD3='puc:#{res.instance[:puc_code]}' LCD4='orch:#{res.instance[:orchard_code]}' LCD5='cult group: #{res.instance[:cultivar_group_code]}' LCD6='cult:#{res.instance[:cultivar_name]}' /> ", nil)
          else
            wrap_content_in_style("<BinTipping Status='false' Red='true' Green='false' Orange='false' Msg='#{res.message}' LCD1='' LCD2='' LCD3='' LCD4='' LCD5='' LCD6='' /> ", nil)
          end
        end
      end

      r.on 'weighing' do
        res = interactor.update_rmt_bin_weights(params)
        if res.success
          res = interactor.tip_rmt_bin(params) # if this fails, should interactor.update_rmt_bin_weights be allowed to commit?
          if res.success
            wrap_content_in_style("<BinTipping Status='true' Red='false' Green='true' Orange='false' Msg='#{res.message}' LCD1='run:#{res.instance[:run_id]}, tipped: #{res.instance[:bins_tipped]}' LCD2='farm:#{res.instance[:farm_code]}' LCD3='puc:#{res.instance[:puc_code]}' LCD4='orch:#{res.instance[:orchard_code]}' LCD5='cult group: #{res.instance[:cultivar_group_code]}' LCD6='cult:#{res.instance[:cultivar_name]}' /> ", nil)
          else
            wrap_content_in_style("<BinTipping Status='false' Red='true' Green='false' Orange='false' Msg='#{res.message}' LCD1='' LCD2='' LCD3='' LCD4='' LCD5='' LCD6='' /> ", nil)
          end
        else
          wrap_content_in_style("<BinWeighing Status='false' Red='true' Green='false' Orange='false' Msg='#{res.message}' LCD1='' LCD2='' LCD3='' LCD4='' LCD5='' LCD6='' /> ", nil)
        end
      end
    end
  end
end
