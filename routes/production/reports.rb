# frozen_string_literal: true

class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'reports', 'production' do |r| # rubocop:disable Metrics/BlockLength
    # PACKOUT RUNS REPORT
    # --------------------------------------------------------------------------
    r.on 'packout_runs' do
      r.get do
        show_page { Production::Reports::Packout::SearchPackoutRuns.call }
      end

      r.post do
        interactor = ProductionApp::ProductionRunInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

        params[:packout_runs_report].delete_if { |_k, v| v.nil_or_empty? }
        store_locally(:dispatches_only, params[:packout_runs_report].delete(:dispatches_only))
        store_locally(:use_derived_weight, params[:packout_runs_report].delete(:use_derived_weight))
        res = interactor.find_packout_runs(params[:packout_runs_report])
        if res.success
          r.redirect("/list/packout_runs/multi?key=standard&ids=#{res.instance}")
        else
          flash[:error] = res.message
          r.redirect('/production/reports/packout_runs')
        end
      end
    end

    r.on 'packout_runs_report' do # rubocop:disable Metrics/BlockLength
      use_derived_weight = retrieve_from_local_store(:use_derived_weight)
      dispatches_only = retrieve_from_local_store(:dispatches_only)
      res = if AppConst::JASPER_NEW_METHOD
              jasper_params = JasperParams.new('packout_runs',
                                               current_user.login_name,
                                               production_run_id: "#{multiselect_grid_choices(params).join(',')}|intarray",
                                               carton_or_bin: AppConst::DEFAULT_FG_PACKAGING_TYPE.capitalize,
                                               use_packed_weight: use_derived_weight != 't',
                                               use_derived_weight: use_derived_weight == 't',
                                               dispatched_only: dispatches_only == 't')
              CreateJasperReportNew.call(jasper_params)
            else
              CreateJasperReport.call(report_name: 'packout_runs',
                                      user: current_user.login_name,
                                      file: 'packout_runs',
                                      params: { production_run_id: "#{multiselect_grid_choices(params).join(',')}|intarray",
                                                carton_or_bin: AppConst::DEFAULT_FG_PACKAGING_TYPE.capitalize,
                                                use_packed_weight: use_derived_weight != 't' ? 'true|boolean' : 'false|boolean',
                                                use_derived_weight: use_derived_weight == 't' ? 'true|boolean' : 'false|boolean',
                                                dispatched_only: dispatches_only == 't' ? 'true|boolean' : 'false|boolean',
                                                keep_file: false })
            end

      store_locally(:dispatches_only, dispatches_only)
      store_locally(:use_derived_weight, use_derived_weight)
      if res.success
        change_window_location_via_json(UtilityFunctions.cache_bust_url(res.instance), request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    # AVAILABLE PALLET NUMBERS
    # --------------------------------------------------------------------------
    r.on 'available_pallet_numbers' do
      show_page { Production::Reports::AvailablePallets::Show.call }
    end

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
