# frozen_string_literal: true

class Nspack < Roda
  route 'reports', 'production' do |r| # rubocop:disable Metrics/BlockLength
    # AGGREGATE PACKOUT REPORT
    # --------------------------------------------------------------------------
    r.on 'aggregate_packout' do
      show_page { Production::Reports::Packout::Edit.call }
    end

    r.on 'aggregate_packout_print' do # rubocop:disable Metrics/BlockLength
      attrs = params[:packout_report]
      line = attrs[:line_resource_id].nil_or_empty? ? '' : BaseRepo.new.get(:plant_resources, attrs[:line_resource_id], :plant_resource_code)
      puc = attrs[:puc_id].nil_or_empty? ? '' : BaseRepo.new.get(:pucs, attrs[:puc_id], :puc_code)
      orchard = attrs[:orchard_id].nil_or_empty? ? nil : BaseRepo.new.get(:orchards, attrs[:orchard_id], :orchard_code)
      cultivar = attrs[:cultivar_id].nil_or_empty? ? '' : BaseRepo.new.get(:cultivars, attrs[:cultivar_id], :cultivar_name)

      res = if AppConst::JASPER_NEW_METHOD
              jasper_params = JasperParams.new('packout_summary',
                                               current_user.login_name,
                                               FromDate: "#{attrs[:from_date]} 00:00:00",
                                               ToDate: "#{attrs[:to_date]} 00:00:00",
                                               detail_level: attrs[:detail_level] == 't' ? 'Detail' : 'Summary',
                                               dispatched_only: attrs[:dispatched_only] == 't' ? 'true|boolean' : 'false|boolean',
                                               line: line,
                                               puc: puc,
                                               orchard: orchard.nil_or_empty? ? nil : orchard,
                                               cultivar: cultivar)
              CreateJasperReportNew.call(jasper_params)
            else
              CreateJasperReport.call(report_name: 'packout_summary',
                                      user: current_user.login_name,
                                      file: 'packout_summary',
                                      params: { FromDate: "#{attrs[:from_date]} 00:00:00|date",
                                                ToDate: "#{attrs[:to_date]} 00:00:00|date",
                                                detail_level: attrs[:detail_level] == 't' ? 'Detail' : 'Summary',
                                                dispatched_only: attrs[:dispatched_only] == 't' ? 'true|boolean' : 'false|boolean',
                                                line: line,
                                                puc: puc,
                                                orchard: orchard.nil_or_empty? ? nil : "#{orchard}|string",
                                                cultivar: cultivar,
                                                keep_file: false })
            end
      if res.success
        change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    r.on 'packhouse_changed' do
      lines = if params[:changed_value].blank?
                []
              else
                ProductionApp::ResourceRepo.new.packhouse_lines(params[:changed_value])
              end
      json_actions([OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'packout_report_line_resource_id',
                                   options_array: lines)])
    end

    r.on 'puc_changed' do
      orchards = if params[:changed_value].blank?
                   []
                 else
                   MasterfilesApp::FarmRepo.new.selected_puc_orchard_codes(params[:changed_value])
                 end
      json_actions([OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'packout_report_orchard_id',
                                   options_array: orchards),
                    OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'packout_report_cultivar_id',
                                   options_array: MasterfilesApp::CultivarRepo.new.for_select_cultivars)])
    end

    r.on 'orchard_changed' do
      cultivar_repo = MasterfilesApp::CultivarRepo.new
      if params[:changed_value].blank?
        cultivars = cultivar_repo.for_select_cultivars
      else
        orchard = MasterfilesApp::FarmRepo.new.find_orchard(params[:changed_value])
        cultivars = orchard.cultivar_ids.nil_or_empty? ? cultivar_repo.for_select_cultivars : cultivar_repo.for_select_cultivars(where: { id: orchard.cultivar_ids.to_a })
      end
      json_actions([OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'packout_report_cultivar_id',
                                   options_array: cultivars)])
    end
  end
end
