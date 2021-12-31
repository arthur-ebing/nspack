# frozen_string_literal: true

module ProductionApp
  class ReworksRunInteractor < BaseInteractor
    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::ReworksRun.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def reworks_run_errors_grid(rw_run_id)
      row_defs = repo.get(:reworks_runs, :errors, rw_run_id)
      col_defs = reworks_run_errors_grid_col_defs
      {
        columnDefs: col_defs,
        rowDefs: row_defs
      }.to_json
    end

    def edit_suggested_runs(row_defs)
      col_defs = edit_suggested_runs_col_defs
      {
        extraContext: { keyColumn: 'id' },
        fieldUpdateUrl: '/production/reworks/tip_bin/$:id$',
        columnDefs: col_defs,
        rowDefs: row_defs
      }.to_json
    end

    def edit_suggested_runs_col_defs
      col_names = suggested_runs_col_names

      Crossbeams::DataGrid::ColumnDefiner.new.make_columns do |mk|
        make_columns_for(col_names).each do |col|
          col[:options].merge!(editable: true, cellEditor: 'numericCellEditor', cellEditorType: 'integer') if col[:field] == 'enter_tip_run_id'
          mk.col col[:field], col[:options][:caption], col[:options]
        end
      end
    end

    def bins_grid_with_suggested_runs(selection)
      row_defs = delivery_repo.find_suggested_runs_for_untipped_bins(selection)
      col_defs = suggested_runs_col_defs
      {
        columnDefs: col_defs,
        rowDefs: row_defs
      }
    end

    def suggested_runs_col_defs
      col_names = suggested_runs_col_names

      Crossbeams::DataGrid::ColumnDefiner.new(for_multiselect: true).make_columns do |mk|
        make_columns_for(col_names).each do |col|
          mk.col col[:field], col[:options][:caption], col[:options] unless col[:field] == 'enter_tip_run_id'
        end
      end
    end

    def suggested_runs_col_names
      persistor = Crossbeams::Dataminer::YamlPersistor.new('grid_definitions/dataminer_queries/suggested_tip_runs_for_bins.yml')
      rpt = Crossbeams::Dataminer::Report.load(persistor)
      rpt.columns
    end

    def make_columns_for(col_names)
      cols = []
      col_names.each { |name, column_def| cols << col_with_attrs(name, column_def) }
      cols
    end

    def col_with_attrs(name, column_def)
      col = { field: name }
      opts = column_def.to_hash
      col.merge(options: opts)
    end

    def bulk_tip_bins(bulk_bintip_ids, suggested_runs)
      bulk_tip_bins = suggested_runs.find_all { |r| bulk_bintip_ids.include?(r[:id]) && r[:suggested_tip_run_id] }
      bins_to_be_tipped_individually = suggested_runs - bulk_tip_bins
      bg_job_bins = bulk_tip_bins.map { |b| { bin_id: b[:id], run_id: b[:suggested_tip_run_id], bulk_bin: true } }

      success_response('bulk bin_tipping queued up successfully', runs: bins_to_be_tipped_individually, bg_job_bins: bg_job_bins)
    end

    def tip_bin_against_run(id, column_value, bg_job_bins, bins_with_editable_suggested_runs)
      # TODO
      # validate_if_tiping

      if column_value.zero?
        bg_job_bins.delete_if { |r| r[:bin_id] == id }
      elsif (bg_bin = bg_job_bins.find { |b| b[:bin_id] == id })
        bg_bin[:run_id] = column_value
      else
        bg_job_bins.push(bin_id: id, run_id: column_value, bulk_bin: false)
      end

      if (edit_bin = bins_with_editable_suggested_runs.find { |b| b[:id] == id })
        edit_bin[:enter_tip_run_id] = column_value.zero? ? nil : column_value
      end
      success_response("bin: #{id} queued up for tipping", bg_job_bins: bg_job_bins, bins_with_editable_suggested_runs: bins_with_editable_suggested_runs)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def build_view_summary_grid(bg_job_bins)
      row_defs = bg_job_bins.group_by { |t| t[:run_id] }.map do |k, v|
        { run_id: k,
          qty_bulk_tipped: v.find_all { |d| d[:bulk_bin] }.length,
          qty_edited: v.find_all { |d| !d[:bulk_bin] }.length }
      end

      col_defs = summary_col_defs
      grid_def = {
        columnDefs: col_defs,
        rowDefs: row_defs
      }.to_json

      success_response('ok', grid_def)
    end

    def complete_bulk_tipping(bg_job_bins) # rubocop:disable Metrics/AbcSize
      return failed_response('No bins were tipped') if bg_job_bins.empty?

      repo.transaction do
        rw_run_id = repo.create_reworks_run(user: @user.user_name,
                                            reworks_run_type_id: repo.get_value(:reworks_run_types, :id, run_type: AppConst::RUN_TYPE_TIP_BINS_AGAINST_SUGGESTED_RUN),
                                            pallets_selected: "{ #{bg_job_bins.map { |i| i[:bin_id] }.join(',')} }",
                                            pallets_affected: "{ #{bg_job_bins.map { |i| i[:bin_id] }.join(',')} }")

        ProductionApp::Job::BulkTipBins.enqueue(rw_run_id, bg_job_bins.map { |b| { bin_id: b[:bin_id], run_id: b[:run_id] } })
      end
      success_response('bulk bin_tipping completed')
    end

    def stepper(key)
      @stepper ||= BulkBinTippingStep.new(key, @user, @context.request_ip)
    end

    def summary_col_defs
      Crossbeams::DataGrid::ColumnDefiner.new.make_columns do |mk|
        mk.col 'run_id', 'Production Run'
        mk.col 'qty_bulk_tipped', 'Qty Bulk Tipped'
        mk.col 'qty_edited', 'Qty Edited'
      end
    end

    def reworks_run_errors_grid_col_defs
      Crossbeams::DataGrid::ColumnDefiner.new.make_columns do |mk|
        mk.col 'id', 'Bin'
        mk.col 'error', 'Error'
        mk.col 'suggested_tip_run_id', 'Suggested Tip Run'
      end
    end

    def validate_change_run_details_params(params)
      res = validate_production_run_params(params)
      return validation_failed_response(res) if res.failure?

      res = validate_production_run_input(res)
      return validation_failed_response(res) unless res.success

      success_response('ok', params)
    end

    def validate_production_run_input(params)
      production_run_id = params[:production_run_id]
      production_run = repo.production_run_exists?(production_run_id)
      return OpenStruct.new(success: false, messages: { production_run_id: ["#{production_run_id} doesn't exist"] }, production_run_id: production_run_id) if production_run.nil_or_empty?

      OpenStruct.new(success: true, instance:  params)
    end

    def resolve_run_orchard_change(params, orchard_id)
      run = production_run(params[:production_run_id])
      params = params.merge({ orchard_id: orchard_id,
                              allow_orchard_mixing: run[:allow_orchard_mixing],
                              allow_cultivar_mixing: run[:allow_cultivar_mixing],
                              allow_cultivar_group_mixing: run[:allow_cultivar_group_mixing] })
      res = resolve_missing_tipped_orchards(add_run_labeling_attrs(params))
      return res unless res.success

      res = resolve_missing_tipped_cultivars(params)
      return res unless res.success

      success_response('ok', res.instance)
    end

    def add_run_labeling_attrs(attrs)
      run = production_run(attrs[:production_run_id])
      attrs[:labeling] = run[:labeling]
      attrs[:reconfiguring] = run[:labeling] ? true : run[:reconfiguring]
      attrs[:setup_complete] = run[:labeling] ? false : run[:setup_complete]
      attrs
    end

    def resolve_missing_tipped_orchards(params) # rubocop:disable Metrics/AbcSize
      return success_response('ok', params.to_h) if params[:allow_orchard_mixing]

      orchard_ids = repo.find_rmt_bin_column_ids(:orchard_id,
                                                 where: { production_run_tipped_id: params[:production_run_id].to_i },
                                                 exclude: { orchard_id: params[:orchard_id].to_i })
      return success_response('ok', params.to_h) if orchard_ids.nil_or_empty?

      orchard_codes = repo.select_values(:orchards, :orchard_code, { id: orchard_ids }).sort
      msg = "Note: Some tipped bins have different orchard than the run.<br> Orchards:<br> #{orchard_codes.join('<br>')} <br> Set allow orchard_mixing."
      failed_response(msg, params)
    end

    def resolve_missing_tipped_cultivars(params) # rubocop:disable Metrics/AbcSize
      return resolve_missing_tipped_orchards(params) unless params[:allow_orchard_mixing]

      return success_response('ok', params.to_h) if params[:allow_cultivar_mixing]

      orchard_cultivar_ids = farm_repo.find_orchard(params[:orchard_id].to_i)&.cultivar_ids.to_a
      cultivar_ids = repo.find_rmt_bin_column_ids(:cultivar_id,
                                                  where: { production_run_tipped_id: params[:production_run_id].to_i },
                                                  exclude: { cultivar_id: orchard_cultivar_ids })
      return success_response('ok', params.to_h) if cultivar_ids.nil_or_empty?

      cultivar_codes = repo.select_values(:cultivars, :cultivar_name, { id: cultivar_ids }).sort
      msg = "Note: Some tipped bins have different cultivar than the run.<br> Cultivars:<br> #{cultivar_codes.join('<br>')} <br> Set allow allow_cultivar_mixing."
      failed_response(msg, params)
    end

    def change_run_orchard(params) # rubocop:disable Metrics/AbcSize
      res = validate_run_cultivar_group_mixing(params)
      return validation_failed_response(res) unless res.success

      res = validate_reworks_change_run_orchard_params(res.instance)
      return validation_failed_response(res) if res.failure?

      Job::ApplyRunOrchardChanges.enqueue(res.to_h, @user.user_name)
      success_response('Production run orchard changes has been enqued.')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      failed_response(e.message)
    end

    def validate_run_cultivar_group_mixing(params) # rubocop:disable Metrics/AbcSize
      return success_response('ok', params) if params[:allow_cultivar_group_mixing]

      bin_cultivar_group_id = repo.select_values(:rmt_bins, :cultivar_group_id, { production_run_tipped_id: params[:production_run_id] }).uniq.first
      return success_response('ok', params) if bin_cultivar_group_id.nil_or_empty?

      orchard_cultivar_ids = farm_repo.find_orchard(params[:orchard_id].to_i)&.cultivar_ids.to_a
      orchard_cultivar_group_id = repo.select_values(:cultivars, :cultivar_group_id, { id: orchard_cultivar_ids }).uniq.first
      message = "INVALID CULTIVAR GROUP: Tipped Bins requires: #{find_cultivar_group_code(bin_cultivar_group_id)}. Orchard is: #{cultivar_group_code(orchard_cultivar_group_id)}"
      return OpenStruct.new(success: false,  messages: { orchard_id: [message] }, orchard_id: params[:orchard_id]) unless orchard_cultivar_group_id == bin_cultivar_group_id

      success_response('ok', params)
    end

    def find_cultivar_group_code(cultivar_group_id)
      repo.get(:cultivar_groups, :cultivar_group_code, cultivar_group_id)
    end

    def production_run_objects(production_run_id)
      repo.production_run_objects(production_run_id)
    end

    def update_run_cultivar(params) # rubocop:disable Metrics/AbcSize
      params[:allow_cultivar_mixing] = false
      res = validate_reworks_change_run_cultivar_params(add_run_labeling_attrs(params))
      return validation_failed_response(res) if res.failure?

      message = 'INVALID CULTIVAR: Selected cultivar is the same for all objects.'
      return failed_response(message, res.to_h) unless repo.any_different_cultivar?(res)

      Job::ApplyRunCultivarChanges.enqueue(res.to_h, @user.user_name)
      success_response('Production run cultivar changes has been enqued.')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      failed_response(e.message)
    end

    def validate_change_bin_delivery_params(params)
      res = validate_delivery_params(params)
      return validation_failed_response(res) if res.failure?

      res = validate_rmt_deliveries(res)
      return validation_failed_response(res) unless res.success

      success_response('ok', params)
    end

    def validate_rmt_deliveries(params)
      from_delivery_id = params[:from_delivery_id]
      to_delivery_id = params[:to_delivery_id]
      from_delivery = repo.details_for_rmt_delivery(from_delivery_id)
      return OpenStruct.new(success: false, messages: { from_delivery_id: ["#{from_delivery_id} doesn't exist"] }, from_delivery_id: from_delivery_id) if from_delivery.nil_or_empty?

      return OpenStruct.new(success: false, messages: { to_delivery_id: ['From delivery same as to delivery. Please enter a different delivery'] }, to_delivery_id: to_delivery_id) if from_delivery_id == to_delivery_id

      to_delivery = repo.details_for_rmt_delivery(to_delivery_id)
      return OpenStruct.new(success: false, messages: { to_delivery_id: ["#{to_delivery_id} doesn't exist"] }, to_delivery_id: to_delivery_id) if to_delivery.nil_or_empty?

      error_msg = resolve_setup_requirements(from_delivery, to_delivery)
      return OpenStruct.new(success: false, messages: { to_delivery_id: [error_msg] }, to_delivery_id: to_delivery_id) unless error_msg.nil_or_empty?

      OpenStruct.new(success: true, instance:  params)
    end

    def resolve_setup_requirements(from_instance, to_instance) # rubocop:disable Metrics/AbcSize
      return "INVALID FARM: From: #{from_instance[:farm_code]}. To: #{to_instance[:farm_code]}" unless from_instance[:farm_id] == to_instance[:farm_id]
      return "INVALID ORCHARD: From: #{from_instance[:orchard_code]}. To: #{to_instance[:orchard_code]}" unless from_instance[:orchard_id] == to_instance[:orchard_id]
      return "INVALID CULTIVAR GROUP: From: #{from_instance[:cultivar_group_code]}. To: #{to_instance[:cultivar_group_code]}" unless from_instance[:cultivar_group_id] == to_instance[:cultivar_group_id]
      return "INVALID CULTIVAR: From: #{from_instance[:cultivar_name]}. To: #{to_instance[:cultivar_name]}" unless from_instance[:cultivar_id] == to_instance[:cultivar_id]
    end

    def change_bin_delivery(reworks_run_type_id, multiselect_list, attrs) # rubocop:disable Metrics/AbcSize
      res = resolve_rmt_bins_from_multiselect(reworks_run_type_id, multiselect_list)
      return validation_failed_response(res) unless res.success

      rmt_bin_ids = res.instance[:pallets_selected].split("\n")
      repo.transaction do
        repo.update_rmt_bin(rmt_bin_ids, { rmt_delivery_id: attrs[:to_delivery_id] })
        id = repo.create_reworks_run({ user: @user.user_name,
                                       reworks_run_type_id: attrs[:reworks_run_type_id],
                                       pallets_selected: "{ #{rmt_bin_ids.join(',')} }",
                                       pallets_affected: "{ #{rmt_bin_ids.join(',')} }",
                                       changes_made: resolve_changes_made(before: { rmt_delivery_id: attrs[:from_delivery_id] },
                                                                          after: { rmt_delivery_id: attrs[:to_delivery_id] }) })
        log_status(:reworks_runs, id, 'CREATED')
        log_multiple_statuses(:rmt_bins, rmt_bin_ids, AppConst::REWORKS_ACTION_CHANGE_BIN_DELIVERY)
        log_transaction
      end
      success_response('Bin delivery change was successful.')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      failed_response(e.message)
    end

    def validate_change_delivery_orchard_screen_params(params)
      res = validate_only_cultivar_change(params)
      if res.failure?
        error_res = validation_failed_response(res)
        error_res.message = "#{error_res.message}: you must allow_cultivar_mixing when changing only the cultivar"
        return error_res
      end

      res = validate_change_delivery_orchard_params(params)
      return validation_failed_response(res) if res.failure?

      res = validate_changes_made?(params)
      return failed_response('No Changes were made') unless res

      if params[:allow_cultivar_mixing] == 'f'
        res = validate_from_cultivar_param(params)
        return validation_failed_response(res) if res.failure?
      end

      ok_response
    end

    def validate_only_cultivar_change(params)
      params[:allow_cultivar_mixing] = nil if (params[:from_orchard] == params[:to_orchard]) && (!params[:to_cultivar].nil_or_empty? && params[:allow_cultivar_mixing] == 'f')
      ChangeCultivarOnlyCultivarSchema.call(params)
    end

    def validate_changes_made?(params)
      return false if params[:from_orchard] == params[:to_orchard] && params[:from_cultivar] == params[:to_cultivar]

      true
    end

    def validate_from_cultivar_param(params)
      FromCultivarSchema.call(params)
    end

    def resolve_deliveries_from_multiselect(params, multiselect_list) # rubocop:disable Metrics/AbcSize
      return failed_response('Delivery selection cannot be empty') if multiselect_list.nil_or_empty?

      rmt_deliveries = selected_deliveries(multiselect_list)
      deliveries_farms = repo.deliveries_farms(rmt_deliveries)
      return failed_response("INVALID FARMS: #{deliveries_farms.join(',')} deliveries must all have the same farm") unless deliveries_farms.length == 1

      same_cultivar_group = deliveries_cultivar_group(params[:from_cultivar].to_i) == deliveries_cultivar_group(params[:to_cultivar].to_i)
      return failed_response('INVALID CULTIVAR: cultivars must be within the same cultivar group') unless same_cultivar_group

      params[:affected_deliveries] = rmt_deliveries.join("\n")
      success_response('', params)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def change_deliveries_orchards(params) # rubocop:disable Metrics/AbcSize
      delivery_ids = params[:affected_deliveries].split("\n").map(&:strip).reject(&:empty?)
      allow_cultivar_mixing = params[:allow_cultivar_mixing] == 't'
      ignore_runs_that_allow_mixing = params[:ignore_runs_that_allow_mixing] == 't'
      allow_cultivar_group_mixing = false unless AppConst::CR_PROD.can_mix_cultivar_groups? && !params[:allow_cultivar_group_mixing].nil?

      change_attrs = { delivery_ids: resolve_deliveries(delivery_ids),
                       from_orchard: params[:from_orchard].to_i,
                       from_cultivar: params[:from_cultivar].to_i,
                       to_orchard: params[:to_orchard].to_i,
                       to_cultivar: params[:to_cultivar].to_i,
                       allow_cultivar_mixing: allow_cultivar_mixing,
                       ignore_runs_that_allow_mixing: ignore_runs_that_allow_mixing }

      reworks_run_attrs = { allow_cultivar_mixing: allow_cultivar_mixing,
                            user: @user.user_name,
                            pallets_affected: delivery_ids,
                            pallets_selected: delivery_ids,
                            reworks_run_type_id: params[:reworks_run_type_id],
                            changes_made: calc_changes_made(params[:to_orchard].to_i, params[:to_cultivar].to_i, delivery_ids),
                            allow_cultivar_group_mixing: allow_cultivar_group_mixing }

      return failed_response(reworks_run_attrs[:changes_made]) if reworks_run_attrs[:changes_made].is_a?(String)

      res = validate_reworks_run_params(reworks_run_attrs)
      return validation_failed_response(res) if res.failure?

      # rw_res = ProductionApp::ChangeDeliveriesOrchards.call(change_attrs, reworks_run_attrs)
      # return failed_response(unwrap_failed_response(rw_res), attrs) unless rw_res.success

      attrs = { change_attrs: change_attrs, reworks_run_attrs: reworks_run_attrs }
      Job::ApplyDeliveriesOrchardChanges.enqueue(attrs)

      success_response('Change Deliveries Orchard has been enqued.')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      failed_response(e.message)
    end

    def resolve_deliveries(affected_deliveries)
      affected_deliveries.map { |x| x.gsub(/['"]/, '').to_i }
    end

    def apply_change_deliveries_orchard_changes(allow_cultivar_mixing, to_orchard, to_cultivar, delivery_ids, reworks_run_type_id) # rubocop:disable Metrics/AbcSize
      reworks_run_attrs = { allow_cultivar_mixing: allow_cultivar_mixing == 't', user: @user.user_name, pallets_affected: delivery_ids.split(','), pallets_selected: delivery_ids.split(','), reworks_run_type_id: reworks_run_type_id }
      res = validate_reworks_run_params(reworks_run_attrs)
      return validation_failed_response(res) if res.failure?

      reworks_run_attrs[:changes_made] = calc_changes_made(to_orchard.to_i, to_cultivar.to_i, delivery_ids)
      return failed_response(reworks_run_attrs[:changes_made]) if reworks_run_attrs[:changes_made].is_a?(String)

      return failed_response('Cannot proceed. Some bins in some of the deliveries are in production_runs that do not allow orchard mixing') unless check_bins_production_runs_allow_mixing?(delivery_ids.join(','))

      repo.transaction do
        repo.bin_bulk_update(delivery_ids.split(','), to_orchard, to_cultivar)
        repo.update(:rmt_deliveries, delivery_ids.split(','), orchard_id: to_orchard, cultivar_id: to_cultivar)

        log_deliveries_and_bins_statuses(delivery_ids)

        create_change_deliveries_orchards_reworks_run(reworks_run_attrs)
      end
      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      failed_response(e.message)
    end

    def check_bins_production_runs_allow_mixing?(delivery_ids)
      repo.bins_production_runs_allow_mixing?(delivery_ids)
    end

    def create_change_deliveries_orchards_reworks_run(reworks_run_attrs)
      reworks_run_attrs[:pallets_affected] = "{ #{reworks_run_attrs[:pallets_affected].join(',')} }"
      reworks_run_attrs[:pallets_selected] = "{ #{reworks_run_attrs[:pallets_selected].join(',')} }"
      reworks_run_attrs[:changes_made] = reworks_run_attrs[:changes_made].to_json
      repo.create_reworks_run(reworks_run_attrs)
    end

    def calc_changes_made(to_orchard, to_cultivar, delivery_ids) # rubocop:disable Metrics/AbcSize
      orchard = farm_repo.find_farm_orchard_by_orchard_id(to_orchard)
      cultivar = MasterfilesApp::CultivarRepo.new.find_cultivar(to_cultivar)&.cultivar_name

      changes = []
      repo.find_from_deliveries_cultivar(resolve_deliveries(delivery_ids).join(',')).group_by { |h| h[:cultivar_name] }.each do |_k, v|
        change = { before: {}, after: {}, change_descriptions: { before: {}, after: {} } }

        if to_orchard != v[0][:orchard_id]
          change[:before].store(:orchard_id, v[0][:orchard_id])
          change[:after].store(:orchard_id, to_orchard)

          change[:change_descriptions][:before].store(:orchard, v[0][:farm_orchard_code])
          change[:change_descriptions][:after].store(:orchard, orchard)
        end

        if to_cultivar != v[0][:cultivar_id]
          change[:before].store(:cultivar_id, v[0][:cultivar_id])
          change[:after].store(:cultivar_id, to_cultivar)

          change[:change_descriptions][:before].store(:cultivar, v[0][:cultivar_name])
          change[:change_descriptions][:after].store(:cultivar, cultivar)
        end

        changes << change
      end

      return 'No Changes were applied. No Changes were made' if changes.length == 1 && changes[0][:before].empty?

      { pallets: { pallet_sequences: { changes: changes } } }
    end

    def log_deliveries_and_bins_statuses(delivery_ids)
      repo.find_bins(delivery_ids).each do |bin|
        log_status(:rmt_bins, bin[:id], 'DELIVERY ORCHARD CHANGE')
      end

      repo.find_deliveries(delivery_ids).each do |del|
        log_status(:rmt_deliveries, del[:id], 'DELIVERY ORCHARD CHANGE')
      end
    end

    def resolve_pallet_numbers_from_multiselect(reworks_run_type_id, multiselect_list)
      return failed_response('Pallet selection cannot be empty') if multiselect_list.nil_or_empty?

      pallet_numbers = repo.select_values(:pallets, :pallet_number, id: multiselect_list).uniq
      instance = { reworks_run_type_id: reworks_run_type_id,
                   pallets_selected: pallet_numbers.join("\n") }
      success_response('', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def resolve_rmt_bins_from_multiselect(reworks_run_type_id, multiselect_list)
      return failed_response('Bin selection cannot be empty') if multiselect_list.nil_or_empty?

      reworks_run_type = reworks_run_type(reworks_run_type_id)
      rmt_bins = case reworks_run_type
                 when AppConst::RUN_TYPE_BULK_BIN_RUN_UPDATE, AppConst::RUN_TYPE_UNTIP_BINS, AppConst::RUN_TYPE_CHANGE_BIN_DELIVERY
                   selected_bins(multiselect_list)
                 else
                   selected_rmt_bins(multiselect_list)
                 end
      instance = { reworks_run_type_id: reworks_run_type_id,
                   pallets_selected: rmt_bins.join("\n") }
      success_response('', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def resolve_cartons_from_multiselect(reworks_run_type_id, multiselect_list)
      return failed_response('Carton selection cannot be empty') if multiselect_list.nil_or_empty?

      carton_labels = repo.carton_carton_label(multiselect_list)
      instance = { reworks_run_type_id: reworks_run_type_id,
                   pallets_selected: carton_labels.join("\n") }
      success_response('', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def bulk_production_run_update(reworks_run_type_id, multiselect_list, attrs) # rubocop:disable Metrics/AbcSize
      return failed_response('Pallet sequence selection cannot be empty') if multiselect_list.nil_or_empty?

      reworks_run_type = reworks_run_type(reworks_run_type_id)
      res = resolve_input_from_multiselect(reworks_run_type, reworks_run_type_id, multiselect_list)
      return validation_failed_response(res) unless res.success

      attrs[:pallets_selected] = res.instance[:pallets_selected].split("\n")
      res = assert_reworks_in_stock_pallets_permissions(reworks_run_type, attrs[:pallets_selected])
      return validation_failed_response(res) unless res.success

      id = nil
      repo.transaction do
        res = resolve_update_selected_input(reworks_run_type, attrs)
        reworks_run_attrs = { user: attrs[:user],
                              reworks_run_type_id: attrs[:reworks_run_type_id],
                              pallets_selected: "{ #{attrs[:pallets_selected].join(',')} }",
                              pallets_affected: "{ #{attrs[:pallets_selected].join(',')} }",
                              changes_made: res[:changes_made] }
        reworks_run_attrs = reworks_run_attrs.merge(allow_cultivar_group_mixing: attrs[:allow_cultivar_group_mixing]) if attrs[:allow_cultivar_group_mixing]

        id = repo.create_reworks_run(reworks_run_attrs)
        resolve_log_reworks_runs_status_and_transaction(reworks_run_type, id, res[:children])
      end
      success_response((res[:message]).to_s, reworks_run_id: id)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def resolve_input_from_multiselect(reworks_run_type, reworks_run_type_id, multiselect_list)
      case reworks_run_type
      when AppConst::RUN_TYPE_BULK_PRODUCTION_RUN_UPDATE
        resolve_pallet_numbers_from_multiselect(reworks_run_type_id, multiselect_list)
      when AppConst::RUN_TYPE_BULK_BIN_RUN_UPDATE
        resolve_rmt_bins_from_multiselect(reworks_run_type_id, multiselect_list)
      end
    end

    def resolve_update_selected_input(reworks_run_type, attrs) # rubocop:disable Metrics/AbcSize
      change_descriptions = {}
      case reworks_run_type
      when AppConst::RUN_TYPE_BULK_PRODUCTION_RUN_UPDATE
        message = "#{AppConst::REWORKS_ACTION_BULK_PALLET_RUN_UPDATE} was successful"
        children = repo.select_values(:pallet_sequences, :id, { pallet_number: attrs[:pallets_selected], production_run_id: attrs[:from_production_run_id] })
        before_attrs = production_run_attrs(attrs[:from_production_run_id], production_run(attrs[:from_production_run_id]))
        after_attrs = production_run_attrs(attrs[:to_production_run_id], production_run(attrs[:to_production_run_id]))
        change_descriptions = { before: production_run_details(attrs[:from_production_run_id]).sort.to_h,
                                after: production_run_details(attrs[:to_production_run_id]).sort.to_h }
        repo.update_pallet_sequence(children, after_attrs)
      when AppConst::RUN_TYPE_BULK_BIN_RUN_UPDATE
        message = "#{AppConst::REWORKS_ACTION_BULK_BIN_RUN_UPDATE} was successful"
        children = attrs[:pallets_selected]
        before_attrs = { production_run_tipped_id: attrs[:from_production_run_id] }
        after_attrs = { production_run_tipped_id: attrs[:to_production_run_id] }
        res = move_bin(attrs[:to_production_run_id], children)
        return res unless res.success

        repo.update_rmt_bin(children, after_attrs)
      end
      changes_made = resolve_changes_made(before: before_attrs.sort.to_h,
                                          after: after_attrs.sort.to_h,
                                          change_descriptions: change_descriptions)
      { children: children, after_attrs: after_attrs, changes_made: changes_made, message: message }
    end

    def move_bin(production_run_id, children)
      location_id = repo.find_run_location_id(production_run_id)
      return failed_response('Location does not exist') if location_id.nil_or_empty?

      children.each do |bin_number|
        res = FinishedGoodsApp::MoveStock.call(AppConst::BIN_STOCK_TYPE, bin_number, location_id, AppConst::REWORKS_MOVE_BIN_BUSINESS_PROCESS, nil)
        return res unless res.success
      end
      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def resolve_changes_made(changes_made)
      changes = {}
      changes['pallets'] = { pallet_sequences: { changes: changes_made } }
      changes.to_json
    end

    def resolve_log_reworks_runs_status_and_transaction(reworks_run_type, reworks_run_id, children)
      case reworks_run_type
      when AppConst::RUN_TYPE_BULK_PRODUCTION_RUN_UPDATE
        children.each do |sequence_id|
          sequence = pallet_sequence(sequence_id)
          log_reworks_runs_status_and_transaction(reworks_run_id, sequence[:pallet_id], sequence_id, AppConst::REWORKS_ACTION_BULK_PALLET_RUN_UPDATE)
        end
      when AppConst::RUN_TYPE_BULK_BIN_RUN_UPDATE
        log_multiple_statuses(:rmt_bins, children, AppConst::REWORKS_ACTION_BULK_BIN_RUN_UPDATE)
        log_status(:reworks_runs, reworks_run_id, 'CREATED')
        log_transaction
      end
    end

    def create_reworks_run(reworks_run_type_id, params) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      reworks_run_type = reworks_run_type(reworks_run_type_id)

      if AppConst::RUN_TYPE_WEIGH_RMT_BINS == reworks_run_type
        res = ReworksWeighRmtBinsContract.new.call(params.merge(pallets_selected: Array(params[:pallets_selected]).reject(&:empty?)))
        return validation_failed_response(res) if res.failure?

        if res[:pallets_selected].nil_or_empty?
          rmt_bin_id = repo.get_id(:rmt_bins, bin_asset_number: res[:bin_asset_number])
          return validation_failed_response(OpenStruct.new(success: false, messages: { bin_asset_number: ["#{res[:bin_asset_number]} doesn't exist"] }, bin_asset_number: res[:bin_asset_number])) if rmt_bin_id.nil_or_empty?

          params[:pallets_selected] = rmt_bin_id.to_s
        end
      end

      res = validate_pallets_selected_input(reworks_run_type, params)
      return validation_failed_response(res) unless res.success

      params[:pallets_selected] = res.instance[:pallet_numbers]
      res = validate_reworks_permissions(reworks_run_type, params[:pallets_selected])
      return validation_failed_response(res) unless res.success

      params[:allow_orchard_mixing] = true if AppConst::RUN_TYPE_TIP_MIXED_ORCHARDS == reworks_run_type
      params[:tip_orchard_mixing] =  AppConst::RUN_TYPE_TIP_MIXED_ORCHARDS == reworks_run_type

      res = validate_reworks_run_new_params(reworks_run_type, params)
      return validation_failed_response(res) if res.failure?

      make_changes = make_changes?(reworks_run_type)
      attrs = res.to_h.merge(user: @user.user_name, make_changes: make_changes, pallets_affected: nil, pallet_sequence_id: nil, affected_sequences: nil)
      return success_response('ok', attrs.merge(display_page: display_page(reworks_run_type))) if make_changes

      return manually_tip_bins(attrs) if [AppConst::RUN_TYPE_TIP_BINS,
                                          AppConst::RUN_TYPE_TIP_MIXED_ORCHARDS].include?(reworks_run_type)

      return manually_untip_bins(attrs) if AppConst::RUN_TYPE_UNTIP_BINS == reworks_run_type

      return bulk_weigh_bins(attrs) if AppConst::RUN_TYPE_BULK_WEIGH_BINS == reworks_run_type

      return bulk_update_pallet_dates(attrs) if AppConst::RUN_TYPE_BULK_UPDATE_PALLET_DATES == reworks_run_type

      return restore_repacked_pallets(attrs) if AppConst::RUN_TYPE_RESTORE_REPACKED_PALLET == reworks_run_type

      rw_res = failed_response('create_reworks_run_record')
      repo.transaction do
        rw_res = create_reworks_run_record(attrs, nil, nil)
        log_reworks_runs_status_and_transaction(rw_res.instance[:reworks_run_id], nil, nil, nil)
      end
      rw_res
    rescue Crossbeams::InfoError => e
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    rescue StandardError => e
      puts e
      puts e.backtrace.join("\n")
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      failed_response(e.message)
    end

    def validate_pallets_selected_input(reworks_run_type, params)
      case AppConst::REWORKS_RUN_NON_PALLET_RUNS[reworks_run_type]
      when :bin
        validate_rmt_bins(reworks_run_type, params[:pallets_selected])
      when :prodrun
        validate_production_runs(reworks_run_type, params)
      when :carton
        validate_carton_labels(reworks_run_type, params[:pallets_selected])
      else
        validate_pallet_numbers(reworks_run_type, params[:pallets_selected])
      end
    end

    def validate_reworks_permissions(reworks_run_type, pallets_selected)
      res = assert_reworks_in_stock_pallets_permissions(reworks_run_type, pallets_selected)
      return res unless res.success

      res = assert_govt_inspected_pallets_reworks_permissions(reworks_run_type, pallets_selected)
      return res unless res.success

      ok_response
    end

    def display_page(reworks_run_type)
      case reworks_run_type
      when AppConst::RUN_TYPE_WEIGH_RMT_BINS
        'edit_rmt_bin_gross_weight'
      when AppConst::RUN_TYPE_SINGLE_BIN_EDIT
        'edit_rmt_bin'
      when AppConst::RUN_TYPE_SINGLE_PALLET_EDIT,
         AppConst::RUN_TYPE_BATCH_PALLET_EDIT
        'edit_pallet'
      when AppConst::RUN_TYPE_BULK_PRODUCTION_RUN_UPDATE,
          AppConst::RUN_TYPE_BULK_BIN_RUN_UPDATE
        'edit_bulk_production_run'
      end
    end

    def create_reworks_run_record(attrs, reworks_action, changes) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      attrs[:allow_cultivar_group_mixing] = false unless AppConst::CR_PROD.can_mix_cultivar_groups? && !attrs[:allow_cultivar_group_mixing].nil?

      res = validate_reworks_run_params(attrs)
      return validation_failed_response(res) if res.failure?

      reworks_run_type = repo.find_reworks_run_type(attrs[:reworks_run_type_id])[:run_type]
      return create_scrap_bin_reworks_run(res) if reworks_run_type == AppConst::RUN_TYPE_SCRAP_BIN
      return create_unscrap_bin_reworks_run(res) if reworks_run_type == AppConst::RUN_TYPE_UNSCRAP_BIN
      return create_scrap_carton_reworks_run(res) if reworks_run_type == AppConst::RUN_TYPE_SCRAP_CARTON
      return create_unscrap_carton_reworks_run(res) if reworks_run_type == AppConst::RUN_TYPE_UNSCRAP_CARTON

      rw_res = ProductionApp::CreateReworksRun.call(res, reworks_action, changes)
      return failed_response(unwrap_failed_response(rw_res), attrs) unless rw_res.success

      success_response('Pallet change was successful', reworks_run_id: rw_res.instance[:reworks_run_id])
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_scrap_bin_reworks_run(params)
      repo.scrapped_bin_bulk_update(params)
      reworks_run_attrs = resolve_reworks_run_attrs(params)
      reworks_run_attrs[:bins_scrapped] = repo.array_for_db_col(params[:pallets_selected])
      id = repo.create_reworks_run(reworks_run_attrs)
      log_multiple_statuses(:rmt_bins, params[:pallets_selected], AppConst::REWORKS_SCRAPPED_STATUS)
      success_response('Bins scrapped successfully', reworks_run_id: id)
    end

    def create_unscrap_bin_reworks_run(params)
      repo.unscrapped_bin_bulk_update(params)
      reworks_run_attrs = resolve_reworks_run_attrs(params)
      reworks_run_attrs[:bins_unscrapped] = repo.array_for_db_col(params[:pallets_selected])
      id = repo.create_reworks_run(reworks_run_attrs)
      log_multiple_statuses(:rmt_bins, params[:pallets_selected], AppConst::BIN_EXIT_REF_UNSCRAPPED)
      success_response('Bins unscrapped successfully', reworks_run_id: id)
    end

    def create_scrap_carton_reworks_run(res)
      carton_ids = repo.select_values(:cartons, :id, carton_label_id: res[:pallets_selected])
      mesc_repo.update_carton(carton_ids, { scrapped: true, scrapped_at: Time.now, scrapped_reason: res[:remarks] })
      reworks_run_attrs = resolve_reworks_run_attrs(res)
      reworks_run_attrs[:cartons_scrapped] = repo.array_for_db_col(carton_ids)
      id = repo.create_reworks_run(reworks_run_attrs)
      log_multiple_statuses(:cartons, carton_ids, AppConst::REWORKS_SCRAPPED_STATUS)
      success_response('Cartons scrapped successfully', reworks_run_id: id)
    end

    def create_unscrap_carton_reworks_run(res)
      carton_ids = repo.select_values(:cartons, :id, carton_label_id: res[:pallets_selected])
      mesc_repo.update_carton(carton_ids, { scrapped: false, scrapped_at: nil, scrapped_reason: nil })
      reworks_run_attrs = resolve_reworks_run_attrs(res)
      reworks_run_attrs[:cartons_unscrapped] = repo.array_for_db_col(carton_ids)
      id = repo.create_reworks_run(reworks_run_attrs)
      log_multiple_statuses(:cartons, carton_ids, 'UNSCRAPPED')
      success_response('Cartons unscrapped successfully', reworks_run_id: id)
    end

    def resolve_reworks_run_attrs(params)
      {
        user: params[:user],
        reworks_run_type_id: params[:reworks_run_type_id],
        scrap_reason_id: params[:scrap_reason_id],
        remarks: params[:remarks],
        pallets_selected: params[:pallets_selected],
        pallets_affected: params[:pallets_selected],
        changes_made: nil,
        pallets_unscrapped: nil
      }
    end

    def print_reworks_pallet_label(pallet_number, params)
      res = validate_print_params(params)
      return validation_failed_response(res) if res.failure?

      instance = reworks_run_pallet_print_data(pallet_number)
      label_name = label_template_name(res[:label_template_id])
      repo.transaction do
        LabelPrintingApp::PrintLabel.call(label_name, instance, no_of_prints: res[:no_of_prints], printer: res[:printer])
        log_transaction
      end
      success_response('Pallet Label printed successfully', pallet_number: pallet_number)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def print_reworks_carton_label(sequence_id, params)
      res = validate_print_params(params)
      return validation_failed_response(res) if res.failure?

      instance = reworks_run_carton_print_data(sequence_id)
      label_name = label_template_name(res[:label_template_id])
      repo.transaction do
        LabelPrintingApp::PrintLabel.call(label_name, instance, no_of_prints: res[:no_of_prints], printer: res[:printer], supporting_data: { packed_date: instance[:packed_date] })
        log_transaction
      end
      success_response('Carton Label printed successfully')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def print_reworks_carton_label_for_sequence(sequence_id, params) # rubocop:disable Metrics/AbcSize
      res = validate_print_params(params)
      return validation_failed_response(res) if res.failure?

      labels = reworks_run_carton_print_data_for_sequence(sequence_id)
      label_name = label_template_name(res[:label_template_id])

      repo.transaction do
        labels.each do |label|
          LabelPrintingApp::PrintLabel.call(label_name,
                                            label,
                                            no_of_prints: 1,
                                            printer: res[:printer],
                                            supporting_data: { packed_date: label[:packed_date] })
        end
        log_transaction
      end
      success_response("#{labels.length} Carton Labels on sequence printed successfully")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def clone_pallet_sequence(params) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      res = validate_clone_sequence_params(params)
      return validation_failed_response(res) if res.failure?

      return failed_response('Marketing Varieties Error. Cultivar change invalidates existing marketing_varieties') if res[:allow_cultivar_mixing] && invalidates_marketing_varieties?(res)

      old_sequence_instance = pallet_sequence(res[:pallet_sequence_id])
      return failed_response('Sequence cannot be cloned', pallet_number: old_sequence_instance[:pallet_number]) if sequence_carton_equals_pallet?(res[:pallet_sequence_id])

      instance = nil
      repo.transaction do
        new_id = repo.clone_pallet_sequence(res)
        reworks_run_attrs = reworks_run_attrs(new_id, res[:reworks_run_type_id])
        instance = pallet_sequence(new_id)
        rw_res = create_reworks_run_record(reworks_run_attrs,
                                           AppConst::REWORKS_ACTION_CLONE,
                                           before: {}, after: instance)
        return failed_response(unwrap_failed_response(rw_res)) unless rw_res.success

        log_reworks_runs_status_and_transaction(rw_res.instance[:reworks_run_id], instance[:pallet_id], res[:pallet_sequence_id], AppConst::REWORKS_ACTION_CLONE)
      end
      success_response('Pallet Sequence cloned successfully', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def invalidates_marketing_varieties?(args)
      repo.invalidates_sequence_marketing_varieties?(args)
    end

    def sequence_carton_equals_pallet?(pallet_sequence_id)
      repo.sequence_carton_equals_pallet?(pallet_sequence_id)
    end

    def reworks_run_attrs(sequence_id, reworks_run_type_id)
      {
        user: @user.user_name,
        reworks_run_type_id: reworks_run_type_id,
        pallets_selected: pallet_sequence_pallet_number(sequence_id),
        pallets_affected: nil,
        pallet_sequence_id: sequence_id,
        affected_sequences: nil,
        make_changes: true
      }
    end

    def remove_pallet_sequence(sequence_id, reworks_run_type_id) # rubocop:disable Metrics/AbcSize
      arr = %i[pallet_number pallet_id removed_from_pallet removed_from_pallet_at removed_from_pallet_id carton_quantity exit_ref]
      before_attrs = pallet_sequence(sequence_id).to_h.slice(*arr)
      return failed_response('Sequence cannot be removed', pallet_number: before_attrs[:pallet_number]) if cannot_remove_sequence(before_attrs[:pallet_id])

      repo.transaction do
        reworks_run_attrs = reworks_run_attrs(sequence_id, reworks_run_type_id)
        repo.remove_pallet_sequence(sequence_id)
        rw_res = create_reworks_run_record(reworks_run_attrs,
                                           AppConst::REWORKS_ACTION_REMOVE,
                                           before: before_attrs.sort.to_h, after: pallet_sequence(sequence_id).to_h.slice(*arr).sort.to_h)
        return failed_response(unwrap_failed_response(rw_res)) unless rw_res.success

        log_reworks_runs_status_and_transaction(rw_res.instance[:reworks_run_id], before_attrs[:pallet_id], sequence_id, AppConst::REWORKS_ACTION_REMOVE)
      end
      success_response('Pallet Sequence removed successfully', pallet_number: before_attrs.to_h[:pallet_number])
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def scrap_pallet_sequence(sequence_id, reworks_run_type_id) # rubocop:disable Metrics/AbcSize
      arr = %i[pallet_number pallet_id removed_from_pallet removed_from_pallet_at removed_from_pallet_id carton_quantity exit_ref]
      before_attrs = pallet_sequence(sequence_id).to_h.slice(*arr)
      return failed_response('Sequence cannot be scrapped', pallet_number: before_attrs[:pallet_number]) unless allow_sequence_scrapping?(sequence_id)

      carton_id = repo.get_value(:cartons, :id, pallet_sequence_id: sequence_id)
      repo.transaction do
        reworks_run_attrs = reworks_run_attrs(sequence_id, reworks_run_type_id)
        repo.scrap_carton(carton_id)
        repo.remove_pallet_sequence(sequence_id)
        rw_res = create_reworks_run_record(reworks_run_attrs,
                                           AppConst::REWORKS_ACTION_REMOVE,
                                           before: before_attrs.sort.to_h, after: pallet_sequence(sequence_id).to_h.slice(*arr).sort.to_h)
        return failed_response(unwrap_failed_response(rw_res)) unless rw_res.success

        log_reworks_runs_status_and_transaction(rw_res.instance[:reworks_run_id], before_attrs[:pallet_id], sequence_id, AppConst::REWORKS_ACTION_REMOVE)
      end
      success_response('Pallet Sequence scrapped successfully', pallet_number: before_attrs.to_h[:pallet_number])
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def edit_carton_quantities(sequence_id, reworks_run_type_id, params) # rubocop:disable Metrics/AbcSize
      res = validate_edit_carton_quantity_params(params)
      return validation_failed_response(res) if res.failure?

      instance = pallet_sequence(sequence_id)
      repo.transaction do
        repo.edit_carton_quantities(sequence_id, params[:column_value])
        reworks_run_attrs = reworks_run_attrs(sequence_id, reworks_run_type_id)
        rw_res = create_reworks_run_record(reworks_run_attrs,
                                           AppConst::REWORKS_ACTION_EDIT_CARTON_QUANTITY,
                                           before: { carton_quantity: instance[:carton_quantity] }, after: { carton_quantity: params[:column_value] })
        return failed_response(unwrap_failed_response(rw_res)) unless rw_res.success

        log_reworks_runs_status_and_transaction(rw_res.instance[:reworks_run_id], instance[:pallet_id], sequence_id, AppConst::REWORKS_ACTION_EDIT_CARTON_QUANTITY)
      end
      success_response('Pallet Sequence carton quantity updated successfully', pallet_number: instance.to_h[:pallet_number])
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_reworks_run_pallet_sequence(params) # rubocop:disable Metrics/AbcSize
      if AppConst::CR_MF.basic_pack_equals_standard_pack?
        standard_pack_id = repo.get_value(:basic_packs_standard_packs, :standard_pack_id, basic_pack_id: params[:basic_pack_code_id])
        params[:standard_pack_code_id] = standard_pack_id
      end

      params[:fruit_actual_counts_for_pack_id] = find_fruit_actual_counts_for_pack_id(params[:basic_pack_code_id].to_i, params[:std_fruit_size_count_id].to_i)
      res = SequenceSetupDataContract.new.call(params)
      return validation_failed_response(res) if res.failure?

      rejected_fields = %i[id product_setup_template_id pallet_label_name]
      attrs = res.to_h.reject { |k, _| rejected_fields.include?(k) }

      success_response('Ok', attrs)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def recalc_marketing_attrs?(params)
      recalc = AppConst::CR_PROD.use_marketing_puc?
      recalc = false unless params.include?(:marketing_org_party_role_id)
      recalc
    end

    def update_pallet_sequence_record(sequence_id, reworks_run_type_id, res, batch_pallet_numbers = nil) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      batch_update = batch_pallet_numbers.nil_or_empty? ? false : true
      before_attrs = sequence_setup_attrs(sequence_id).sort.to_h

      attrs = res.to_h
      changed_attrs = attrs.reject { |k, v|  before_attrs.key?(k) && before_attrs[k] == v }
      changed_attrs = changed_attrs.merge(treatment_ids: resolve_col_array(changed_attrs.delete(:treatment_ids)))
      attrs = attrs.merge(treatment_ids: resolve_col_array(attrs.delete(:treatment_ids))) if attrs.key?(:treatment_ids)

      if AppConst::CR_PROD.use_packing_specifications?
        changed_attrs = changed_attrs.merge(resolve_packing_spec_ids(changed_attrs))
        attrs = attrs.merge(resolve_packing_spec_ids(attrs))
      end

      changed_attrs = changed_attrs.merge(marketing_attrs(attrs.merge(repo.find_sequence_farm_attrs(sequence_id)))) if recalc_marketing_attrs?(changed_attrs)
      changed_attrs = changed_attrs.merge(gtin_code: prod_setup_repo.find_gtin_code_for_update(pallet_sequence(sequence_id))) if prod_setup_repo.recalc_gtin_code?(changed_attrs)
      return failed_response('Changed attributes cannot be empty') if changed_attrs.nil_or_empty?

      before_descriptions_state = sequence_setup_data(sequence_id)
      before_changed_attrs = {}
      changed_attrs.keys.map { |k| before_changed_attrs[k] = before_attrs[k] }

      sequences = batch_update ? affected_pallet_sequences(pallet_number_sequences(batch_pallet_numbers), before_changed_attrs) : sequence_id
      affected_pallets = affected_pallet_numbers(sequences, changed_attrs)

      reworks_run_attrs = {
        user: @user.user_name,
        reworks_run_type_id: reworks_run_type_id,
        pallets_selected: batch_update ? batch_pallet_numbers : pallet_sequence_pallet_number(sequences),
        pallets_affected: affected_pallets,
        pallet_sequence_id: batch_update ? nil : sequences,
        affected_sequences: batch_update ? Array(sequences) : nil,
        make_changes: true
      }
      msg = ''
      repo.transaction do
        batch_update ? repo.existing_records_batch_update(affected_pallets, sequences, changed_attrs) : repo.update_pallet_sequence(sequences, changed_attrs)
        change_descriptions = { before: before_descriptions_state.sort.to_h, after: sequence_setup_data(sequence_id).sort.to_h }
        rw_res = create_reworks_run_record(reworks_run_attrs,
                                           batch_update ? AppConst::REWORKS_ACTION_BATCH_EDIT : AppConst::REWORKS_ACTION_SINGLE_EDIT,
                                           before: before_attrs, after: attrs.sort.to_h, change_descriptions: change_descriptions)
        return failed_response(unwrap_failed_response(rw_res)) unless rw_res.success

        if batch_update
          msg = 'Batch update was successful'
          sequences.each do |id|
            repo.update_carton_labels_for_pallet_sequence(id, changed_attrs) if repo.individual_cartons?(id)
            sequence = pallet_sequence(id)
            log_reworks_runs_status_and_transaction(rw_res.instance[:reworks_run_id], sequence[:pallet_id], id, AppConst::REWORKS_ACTION_BATCH_EDIT)
          end
        else
          msg = 'Pallet Sequence updated successfully'
          repo.update_carton_labels_for_pallet_sequence(sequence_id, changed_attrs) if repo.individual_cartons?(sequence_id)
          pallet_id = pallet_sequence(sequence_id)[:pallet_id]
          log_reworks_runs_status_and_transaction(rw_res.instance[:reworks_run_id], pallet_id, sequence_id, AppConst::RW_PALLET_SINGLE_EDIT)
        end

        if AppConst::CR_FG.lookup_extended_fg_code?
          pallet_ids = repo.select_values(:pallet_sequences, :pallet_id, id: sequences)
          FinishedGoodsApp::Job::CalculateExtendedFgCodesFromSeqs.enqueue(pallet_ids)
        end
      end
      instance = { pallet_number: pallet_sequence_pallet_number(sequence_id).first,
                   batch_update: batch_update }
      success_response("#{msg}.", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def resolve_col_array(ids)
      repo.array_for_db_col(ids) unless ids.nil?
    end

    def resolve_packing_spec_ids(attrs)
      {
        fruit_sticker_ids: resolve_col_array(attrs.delete(:fruit_sticker_ids)),
        tu_sticker_ids: resolve_col_array(attrs.delete(:tu_sticker_ids))
      }
    end

    def reject_pallet_sequence_changes(sequence_id)
      success_response('Changes to Pallet sequence have been discarded', pallet_number: pallet_sequence_pallet_number(sequence_id).first)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def resolve_selected_pallet_numbers(pallets_selected)
      return '' if pallets_selected.nil_or_empty?

      pallet_numbers = pallets_selected.join(',').split(/\n|,/).map(&:strip).reject(&:empty?)
      pallet_numbers = pallet_numbers.map { |x| x.gsub(/['"]/, '') }
      pallet_numbers.join("\n")
    end

    def update_reworks_production_run(params) # rubocop:disable Metrics/AbcSize
      res = validate_update_reworks_production_run_params(params)
      return validation_failed_response(res) if res.failure?

      attrs = res.to_h
      sequence_id = attrs[:pallet_sequence_id]
      sequence = pallet_sequence(sequence_id)
      before_attrs = production_run_attrs(attrs[:old_production_run_id], sequence)
      after_attrs = production_run_attrs(attrs[:production_run_id], production_run(attrs[:production_run_id]))

      before_descriptions_state = production_run_description_changes(attrs[:old_production_run_id], vw_flat_sequence_data(sequence_id))
      repo.transaction do
        reworks_run_attrs = reworks_run_attrs(sequence_id, attrs[:reworks_run_type_id])
        repo.update_pallet_sequence(sequence_id, after_attrs)
        after_descriptions_state = production_run_description_changes(attrs[:production_run_id], vw_flat_sequence_data(sequence_id))
        change_descriptions = { before: before_descriptions_state.sort.to_h, after: after_descriptions_state.sort.to_h }
        rw_res = create_reworks_run_record(reworks_run_attrs.merge(allow_cultivar_group_mixing: attrs[:allow_cultivar_group_mixing]),
                                           AppConst::REWORKS_ACTION_CHANGE_PRODUCTION_RUN,
                                           before: before_attrs.sort.to_h, after: after_attrs.sort.to_h, change_descriptions: change_descriptions)
        return failed_response(unwrap_failed_response(rw_res)) unless rw_res.success

        log_reworks_runs_status_and_transaction(rw_res.instance[:reworks_run_id], sequence[:pallet_id], sequence_id, AppConst::REWORKS_ACTION_CHANGE_PRODUCTION_RUN)
      end
      instance = pallet_sequence(sequence_id)
      success_response('Pallet Sequence production_run_id changed successfully', pallet_number: instance[:pallet_number])
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def production_run_attrs(production_run_id, instance)
      { production_run_id: production_run_id,
        packhouse_resource_id: instance[:packhouse_resource_id],
        production_line_id: instance[:production_line_id] }.merge(farm_details_attrs(instance))
    end

    def farm_details_attrs(instance)
      attrs = { farm_id: instance[:farm_id],
                puc_id: instance[:puc_id],
                orchard_id: instance[:orchard_id],
                cultivar_group_id: instance[:cultivar_group_id],
                cultivar_id: instance[:cultivar_id],
                season_id: instance[:season_id] }
      attrs = attrs.merge(marketing_attrs(instance)) if AppConst::CR_PROD.use_marketing_puc?
      attrs
    end

    def marketing_attrs(res)
      marketing_puc_id = mesc_repo.find_marketing_puc(res[:marketing_org_party_role_id], res[:farm_id])
      { marketing_puc_id: marketing_puc_id, marketing_orchard_id: mesc_repo.find_marketing_orchard(marketing_puc_id, res[:cultivar_id]) }
    end

    def production_run_description_changes(production_run_id, instance_data)
      { production_run_id: production_run_id,
        packhouse: instance_data[:packhouse],
        line: instance_data[:line] }.merge(farm_detail_description_changes(instance_data))
    end

    def farm_detail_description_changes(instance_data)
      attrs = { farm: instance_data[:farm],
                puc: instance_data[:puc],
                orchard: instance_data[:orchard],
                cultivar_group: instance_data[:cultivar_group],
                cultivar: instance_data[:cultivar],
                season: instance_data[:season] }
      attrs = attrs.merge(marketing_descriptions(instance_data)) if AppConst::CR_PROD.use_marketing_puc?
      attrs
    end

    def marketing_descriptions(res)
      { marketing_puc: res[:marketing_puc],
        marketing_orchard: res[:marketing_orchard] }
    end

    def update_reworks_farm_details(params) # rubocop:disable Metrics/AbcSize
      res = validate_update_reworks_farm_details_params(params)
      return validation_failed_response(res) if res.failure?

      attrs = res.to_h
      sequence_id = attrs.delete(:pallet_sequence_id)
      reworks_run_type_id = attrs.delete(:reworks_run_type_id)
      after_attrs = attrs

      instance = pallet_sequence(sequence_id)
      before_attrs = farm_details_attrs(instance)
      before_descriptions_state = farm_detail_description_changes(vw_flat_sequence_data(sequence_id))

      repo.transaction do
        reworks_run_attrs = reworks_run_attrs(sequence_id, reworks_run_type_id)
        repo.update_pallet_sequence(sequence_id, after_attrs)
        after_descriptions_state = farm_detail_description_changes(vw_flat_sequence_data(sequence_id))
        change_descriptions = { before: before_descriptions_state.sort.to_h, after: after_descriptions_state.sort.to_h }
        rw_res = create_reworks_run_record(reworks_run_attrs,
                                           AppConst::REWORKS_ACTION_CHANGE_FARM_DETAILS,
                                           before: before_attrs.sort.to_h, after: after_attrs.sort.to_h, change_descriptions: change_descriptions)
        return failed_response(unwrap_failed_response(rw_res)) unless rw_res.success

        log_reworks_runs_status_and_transaction(rw_res.instance[:reworks_run_id], instance[:pallet_id], sequence_id, AppConst::REWORKS_ACTION_CHANGE_FARM_DETAILS)
      end
      success_response('Pallet Sequence farm details changed successfully', pallet_number: instance[:pallet_number])
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def log_reworks_runs_status_and_transaction(id, pallet_id, sequence_id, status)
      log_status(:pallets, pallet_id, status) unless pallet_id.nil_or_empty?
      log_status(:pallet_sequences, sequence_id, status) unless sequence_id.nil_or_empty?
      log_status(:reworks_runs, id, 'CREATED')
      log_transaction
    end

    def log_reworks_rmt_bin_status_and_transaction(id, rmt_bin_id, status)
      log_status(:rmt_bins, rmt_bin_id, status)
      log_status(:reworks_runs, id, 'CREATED')
      log_transaction
    end

    def update_pallet_gross_weight(params) # rubocop:disable Metrics/AbcSize
      res = validate_update_gross_weight_params(params)
      return validation_failed_response(res) if res.failure?

      attrs = res.to_h
      instance = pallet(attrs[:pallet_number])
      pallet_number = instance[:pallet_number]
      standard_pack_code_id = pallet_standard_pack_code(pallet_number)
      same_standard_pack = (standard_pack_code_id == attrs[:standard_pack_code_id])
      before_state = { gross_weight: instance[:gross_weight], standard_pack_code_id: standard_pack_code_id }
      after_state = { gross_weight: attrs[:gross_weight], standard_pack_code_id: attrs[:standard_pack_code_id] }
      before_descriptions_state = { gross_weight: instance[:gross_weight], standard_pack: standard_pack(standard_pack_code_id) }
      after_descriptions_state = { gross_weight: attrs[:gross_weight], standard_pack: standard_pack(attrs[:standard_pack_code_id]) }
      change_descriptions = { before: before_descriptions_state.sort.to_h, after: after_descriptions_state.sort.to_h }
      repo.transaction do
        repo.update_pallet_gross_weight(instance[:id], attrs, same_standard_pack)
        reworks_run_attrs = { user: @user.user_name, reworks_run_type_id: attrs[:reworks_run_type_id], pallets_selected: Array(pallet_number),
                              pallets_affected: nil, pallet_sequence_id: nil, affected_sequences: nil, make_changes: true }
        rw_res = create_reworks_run_record(reworks_run_attrs,
                                           AppConst::REWORKS_ACTION_SET_GROSS_WEIGHT,
                                           before: before_state, after: after_state, change_descriptions: change_descriptions)
        return failed_response(unwrap_failed_response(rw_res)) unless rw_res.success

        log_reworks_runs_status_and_transaction(rw_res.instance[:reworks_run_id], instance[:id], nil, AppConst::REWORKS_ACTION_SET_GROSS_WEIGHT)
      end
      success_response('Pallet gross_weight updated successfully', pallet_number: pallet_number)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_pallet_details(params) # rubocop:disable Metrics/AbcSize
      res = validate_update_pallet_params(params)
      return validation_failed_response(res) if res.failure?

      attrs = res.to_h
      reworks_run_type_id = attrs.delete(:reworks_run_type_id)
      pallet_number = attrs.delete(:pallet_number)
      instance = pallet(pallet_number)

      requires_material_owner = repo.pallet_requires_material_owner?(pallet_number)
      before_attrs = { fruit_sticker_pm_product_id: instance[:fruit_sticker_pm_product_id],
                       fruit_sticker_pm_product_2_id: instance[:fruit_sticker_pm_product_2_id] }
      before_attrs[:batch_number] = instance[:batch_number] if AppConst::CR_PROD.capture_batch_number_for_pallets?
      before_attrs[:rmt_container_material_owner_id] = instance[:rmt_container_material_owner_id] if requires_material_owner

      change_descriptions = { before: resolve_pallet_state(instance, requires_material_owner).sort.to_h, after: resolve_pallet_state(attrs, requires_material_owner).sort.to_h }
      repo.transaction do
        repo.update_pallet(instance[:id], attrs)
        reworks_run_attrs = { user: @user.user_name, reworks_run_type_id: reworks_run_type_id, pallets_selected: Array(pallet_number),
                              pallets_affected: nil, pallet_sequence_id: nil, affected_sequences: nil, make_changes: true }
        rw_res = create_reworks_run_record(reworks_run_attrs,
                                           AppConst::REWORKS_ACTION_UPDATE_PALLET_DETAILS,
                                           before: before_attrs, after: attrs, change_descriptions: change_descriptions)
        return failed_response(unwrap_failed_response(rw_res)) unless rw_res.success

        log_reworks_runs_status_and_transaction(rw_res.instance[:reworks_run_id], instance[:id], nil, AppConst::REWORKS_ACTION_UPDATE_PALLET_DETAILS)
      end
      success_response('Pallet details updated successfully', pallet_number: pallet_number)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def resolve_pallet_state(instance, requires_material_owner)
      attrs = { fruit_sticker: fruit_sticker(instance[:fruit_sticker_pm_product_id]),
                fruit_sticker_2: fruit_sticker(instance[:fruit_sticker_pm_product_2_id]) }
      attrs[:batch_number] = instance[:batch_number] if AppConst::CR_PROD.capture_batch_number_for_pallets?
      attrs[:rmt_container_material_owner] = prod_setup_repo.rmt_container_material_owner_for(instance[:rmt_container_material_owner_id]) if requires_material_owner
      attrs
    end

    def manually_tip_bins(attrs) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      attrs = attrs.to_h
      avg_gross_weight = attrs[:gross_weight].nil_or_empty? ? false : true
      before_state = manually_tip_bin_before_state(attrs, avg_gross_weight)

      rw_res = nil
      repo.transaction do
        repo.update_production_run(attrs[:production_run_id], prod_run_attrs(attrs)) if attrs[:allow_cultivar_mixing] || attrs[:tip_orchard_mixing]
        rw_res = ProductionApp::ManuallyTipBins.call(attrs)
        return failed_response(unwrap_failed_response(rw_res)) unless rw_res.success

        if avg_gross_weight
          rw_res = ProductionApp::BulkWeighBins.call(attrs, true, avg_gross_weight)
          return failed_response(unwrap_failed_response(rw_res), attrs) unless rw_res.success

        end

        reworks_run_attrs = { user: @user.user_name, reworks_run_type_id: attrs[:reworks_run_type_id], pallets_selected: attrs[:pallets_selected],
                              pallets_affected: nil, pallet_sequence_id: nil, affected_sequences: nil, make_changes: false,
                              allow_cultivar_mixing: attrs[:allow_cultivar_mixing], allow_orchard_mixing: attrs[:allow_orchard_mixing] }
        rw_res = create_reworks_run_record(reworks_run_attrs,
                                           nil,
                                           before: before_state.sort.to_h, after: manually_tip_bin_after_state(attrs, avg_gross_weight).sort.to_h)
        return failed_response(unwrap_failed_response(rw_res)) unless rw_res.success

        log_status(:production_runs, attrs[:production_run_id], AppConst::REWORKS_ORCHARD_MIX) if attrs[:tip_orchard_mixing]
        log_status(:reworks_runs, rw_res.instance[:reworks_run_id], AppConst::RMT_BIN_TIPPED_MANUALLY)
      end
      success_response('RMT Bin tipped successfully', pallet_number: attrs[:pallets_selected])
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def prod_run_attrs(attrs)
      defaults = {}
      defaults[:allow_cultivar_mixing] = true if attrs[:allow_cultivar_mixing]
      defaults[:allow_orchard_mixing] = true if attrs[:tip_orchard_mixing]
      defaults
    end

    def manually_tip_bin_before_state(attrs, avg_gross_weight = false)
      defaults = { bin_tipped_date_time: nil,
                   production_run_tipped_id: nil,
                   tipped_asset_number: nil,
                   bin_asset_number: attrs[:pallets_selected].first,
                   exit_ref_date_time: nil,
                   bin_tipped: false,
                   exit_ref: nil,
                   tipped_manually: false }
      defaults = defaults.merge(allow_cultivar_mixing: production_run_allow_cultivar_mixing(attrs[:production_run_id])) if attrs[:allow_cultivar_mixing]
      defaults = defaults.merge(manually_weigh_rmt_bin_state(attrs[:pallets_selected].first)) if avg_gross_weight
      if attrs[:tip_orchard_mixing]
        defaults = defaults.merge(tip_orchard_mixing: false,
                                  allow_orchard_mixing: repo.get(:production_runs, :allow_orchard_mixing, attrs[:production_run_id]))
      end
      defaults
    end

    def manually_tip_bin_after_state(attrs, avg_gross_weight = false)
      defaults = { bin_tipped_date_time: Time.now,
                   production_run_tipped_id: attrs[:production_run_id],
                   tipped_asset_number: attrs[:pallets_selected].first,
                   bin_asset_number: nil,
                   exit_ref_date_time: Time.now,
                   bin_tipped: true,
                   exit_ref: 'TIPPED',
                   tipped_manually: true }
      defaults = defaults.merge(allow_cultivar_mixing: attrs[:allow_cultivar_mixing]) if attrs[:allow_cultivar_mixing]
      defaults = defaults.merge(manually_weigh_rmt_bin_state(attrs[:pallets_selected].first)) if avg_gross_weight
      if attrs[:tip_orchard_mixing]
        defaults = defaults.merge(tip_orchard_mixing: attrs[:tip_orchard_mixing],
                                  allow_orchard_mixing: attrs[:allow_orchard_mixing])
      end
      defaults
    end

    def manually_untip_bins(attrs) # rubocop:disable Metrics/AbcSize
      attrs = attrs.to_h
      res = repo.where_hash(:rmt_bins, id: attrs[:pallets_selected].first)

      change_attrs = { bin_tipped_date_time: nil,
                       production_run_tipped_id: nil,
                       exit_ref_date_time: nil,
                       bin_tipped: false,
                       exit_ref: nil,
                       tipped_manually: false }
      change_attrs = change_attrs.merge(asset_number_attrs(res))

      rw_res = nil
      repo.transaction do
        repo.update_rmt_bin(attrs[:pallets_selected], change_attrs)
        location_to_id = MasterfilesApp::LocationRepo.new.find_location_by_location_long_code(AppConst::UNTIP_LOCATION)&.id
        return failed_response('Location does not exist') if location_to_id.nil_or_empty?

        attrs[:pallets_selected].each do |bin_number|
          res = FinishedGoodsApp::MoveStock.call(AppConst::BIN_STOCK_TYPE, bin_number, location_to_id, AppConst::REWORKS_MOVE_BIN_BUSINESS_PROCESS, nil)
          return res unless res.success
        end

        reworks_run_attrs = { user: @user.user_name, reworks_run_type_id: attrs[:reworks_run_type_id], pallets_selected: attrs[:pallets_selected],
                              pallets_affected: nil, pallet_sequence_id: nil, affected_sequences: nil, make_changes: true,
                              allow_cultivar_mixing: false }
        rw_res = create_reworks_run_record(reworks_run_attrs,
                                           nil,
                                           before: manually_untip_bin_before_state(res).sort.to_h, after: change_attrs.sort.to_h)
        return failed_response(unwrap_failed_response(rw_res)) unless rw_res.success

        log_status(:reworks_runs, rw_res.instance[:reworks_run_id], AppConst::RMT_BIN_UNTIPPED_MANUALLY)
      end
      success_response('RMT Bin untipped successfully', pallet_number: attrs[:pallets_selected])
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def asset_number_attrs(res)
      { bin_asset_number: res[:tipped_asset_number],
        tipped_asset_number: nil }
    end

    def manually_untip_bin_before_state(res)
      { bin_tipped_date_time: res[:bin_tipped_date_time],
        production_run_tipped_id: res[:production_run_tipped_id],
        tipped_asset_number: res[:tipped_asset_number],
        bin_asset_number: res[:bin_asset_number],
        exit_ref_date_time: res[:exit_ref_date_time],
        bin_tipped: true,
        exit_ref: 'TIPPED',
        tipped_manually: true }
    end

    def bulk_weigh_bins(attrs) # rubocop:disable Metrics/AbcSize
      attrs = attrs.to_h
      before_state = manually_weigh_rmt_bin_state(attrs[:pallets_selected].first)

      rw_res = nil
      repo.transaction do
        rw_res = ProductionApp::BulkWeighBins.call(attrs, true, attrs[:avg_gross_weight])
        return failed_response(unwrap_failed_response(rw_res), attrs) unless rw_res.success

        reworks_run_attrs = { user: @user.user_name, reworks_run_type_id: attrs[:reworks_run_type_id], pallets_selected: attrs[:pallets_selected],
                              pallets_affected: nil, pallet_sequence_id: nil, affected_sequences: nil, make_changes: false }
        rw_res = create_reworks_run_record(reworks_run_attrs,
                                           nil,
                                           before: before_state, after: manually_weigh_rmt_bin_state(attrs[:pallets_selected].first))
        return failed_response(unwrap_failed_response(rw_res)) unless rw_res.success

        log_status(:reworks_runs, rw_res.instance[:reworks_run_id], AppConst::BULK_WEIGH_RMT_BINS)
      end
      success_response('RMT Bulk Bin Weighing was successfully', pallet_number: attrs[:pallets_selected])
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def bulk_update_pallet_dates(attrs) # rubocop:disable Metrics/AbcSize
      attrs = attrs.to_h
      instance = pallet(attrs[:pallets_selected].first)
      before_state = { first_cold_storage_at: instance[:first_cold_storage_at] }

      pallet_ids = repo.find_pallet_ids_from_pallet_number(attrs[:pallets_selected])
      change_attrs = { first_cold_storage_at: attrs[:first_cold_storage_at] }

      repo.transaction do
        repo.update_pallet(pallet_ids, change_attrs)
        reworks_run_attrs = { user: @user.user_name,
                              reworks_run_type_id: attrs[:reworks_run_type_id],
                              pallets_selected: "{ #{attrs[:pallets_selected].join(',')} }",
                              pallets_affected: "{ #{attrs[:pallets_selected].join(',')} }",
                              changes_made: resolve_changes_made(before: before_state.sort.to_h,
                                                                 after: change_attrs.sort.to_h) }
        reworks_run_id = repo.create_reworks_run(reworks_run_attrs)
        log_multiple_statuses(:pallets, pallet_ids, AppConst::REWORKS_BULK_UPDATE_PALLET_DATES)
        log_status(:reworks_runs, reworks_run_id, 'CREATED')
        log_transaction
      end
      success_response('Bulk pallet dates update was successfully', pallet_number: attrs[:pallets_selected])
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def manually_weigh_rmt_bin(params) # rubocop:disable Metrics/AbcSize
      res = validate_manually_weigh_rmt_bin_params(params)
      return validation_failed_response(res) if res.failure?

      attrs = res.to_h
      rmt_bin_id = find_rmt_bin(attrs[:bin_number])
      before_state = manually_weigh_rmt_bin_state(rmt_bin_id)

      rw_res = nil
      repo.transaction do
        options = { force_find_by_id: true, weighed_manually: true, avg_gross_weight: false }
        rw_res = MesscadaApp::UpdateBinWeights.call(attrs, options)
        return failed_response(unwrap_failed_response(rw_res), attrs) unless rw_res.success

        # repo.update_rmt_bin(rmt_bin_id, weighed_manually: true)
        reworks_run_attrs = { user: @user.user_name, reworks_run_type_id: attrs[:reworks_run_type_id], pallets_selected: Array(attrs[:bin_number]),
                              pallets_affected: nil, pallet_sequence_id: nil, affected_sequences: nil, make_changes: false }
        rw_res = create_reworks_run_record(reworks_run_attrs,
                                           nil,
                                           before: before_state, after: manually_weigh_rmt_bin_state(rmt_bin_id))
        return failed_response(unwrap_failed_response(rw_res)) unless rw_res.success

        log_reworks_rmt_bin_status_and_transaction(rw_res.instance[:reworks_run_id], rmt_bin_id, AppConst::RMT_BIN_WEIGHED_MANUALLY)
      end
      success_response('RMT Bin weighed successfully', pallet_number: attrs[:bin_number])
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def manually_weigh_rmt_bin_state(rmt_bin_id)
      instance = rmt_bin(rmt_bin_id)
      { gross_weight: instance[:gross_weight],
        nett_weight: instance[:nett_weight],
        weighed_manually: instance[:weighed_manually],
        avg_gross_weight: instance[:avg_gross_weight] }
    end

    def update_rmt_bin_record(params) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      arr = %i[rmt_class_id rmt_size_id rmt_container_material_type_id rmt_material_owner_party_role_id]

      res = validate_edit_rmt_bin_params(params)
      return validation_failed_response(res) if res.failure?

      before_state = rmt_bin(res[:bin_number]).slice(*arr)
      after_state = res.to_h.slice(*arr)
      changed_attrs = after_state.reject { |k, v|  before_state.key?(k) && before_state[k] == v }
      return failed_response('INVALID CHANGES: There are no changes made.', after_state) if changed_attrs.empty?

      repo.transaction do
        # repo.update_rmt_bin(res[:bin_number], after_state)
        repo.update(:rmt_bins, res[:bin_number], after_state)
        reworks_run_id = repo.create_reworks_run({ user: @user.user_name,
                                                   reworks_run_type_id: res[:reworks_run_type_id],
                                                   pallets_selected: Array(res[:bin_number]),
                                                   pallets_affected: Array(res[:bin_number]),
                                                   changes_made: resolve_changes_made(before: before_state,
                                                                                      after: after_state,
                                                                                      change_descriptions: { before: rmt_bin_state(before_state), after: rmt_bin_state(after_state) }) })
        log_reworks_rmt_bin_status_and_transaction(reworks_run_id, res[:bin_number], AppConst::REWORKS_ACTION_SINGLE_BIN_EDIT)

        if changed_attrs.include?(:rmt_container_material_type_id)
          res = ProductionApp::RecalcBinsNettWeight.call(recalc_bin_nett_weight_reworks_run_attrs, Array(res[:bin_number]))
          raise Crossbeams::InfoError, res.message unless res.success
        end
      end
      success_response('RMT Bin updated successfully', pallet_number: res[:bin_number])
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def recalc_bin_nett_weight_reworks_run_attrs
      { user: @user.user_name,
        reworks_run_type_id: repo.get_reworks_run_type_id(AppConst::RUN_TYPE_RECALC_BIN_NETT_WEIGHT),
        pallets_selected: '{ }',
        pallets_affected: '{ }' }
    end

    def rmt_bin_state(attrs)
      owner_id = repo.get_value(:rmt_container_material_owners,
                                :id,
                                attrs.slice(:rmt_container_material_type_id, :rmt_material_owner_party_role_id))
      { rmt_class: repo.get(:rmt_classes, :rmt_class_code, attrs[:rmt_class_id]),
        rmt_size: repo.get(:rmt_sizes, :size_code, attrs[:rmt_size_id]),
        rmt_container_material_type: repo.get(:rmt_container_material_types, :container_material_type_code, attrs[:rmt_container_material_type_id]),
        rmt_material_owner: prod_setup_repo.rmt_container_material_owner_for(owner_id) }
    end

    def clone_carton(params)
      res = validate_clone_carton_params(params)
      return validation_failed_response(res) if res.failure?

      attrs = res.to_h

      res = nil
      repo.transaction do
        res = MesscadaApp::CloneAutopackPalletCarton.call(attrs)
        log_transaction
      end
      success_response('Carton cloned successfully', pallet_sequence_id: attrs[:pallet_sequence_id])
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def scrap_carton(carton_id, reworks_run_type_id) # rubocop:disable Metrics/AbcSize
      arr = %i[scrapped scrapped_at scrapped_reason pallet_sequence_id scrapped_sequence_id pallet_id pallet_number]
      before_attrs = carton_scrap_attributes(carton_id).to_h.slice(*arr)
      return failed_response('Carton cannot be scrapped. Scrap the pallet sequence instead', pallet_sequence_id: before_attrs[:pallet_sequence_id]) if cannot_scrap_carton(before_attrs[:pallet_sequence_id])

      repo.transaction do
        original_pallet_sequence_id = before_attrs[:pallet_sequence_id]
        repo.scrap_carton(carton_id)
        prod_repo.decrement_sequence(original_pallet_sequence_id) unless original_pallet_sequence_id.nil?
        after_attrs = carton_scrap_attributes(carton_id).to_h.slice(*arr)
        reworks_run_attrs = { user: @user.user_name,
                              reworks_run_type_id: reworks_run_type_id,
                              pallets_selected: "{ #{before_attrs[:pallet_number]} }",
                              pallets_affected: "{ #{before_attrs[:pallet_number]} }",
                              changes_made: resolve_changes_made(before: before_attrs.sort.to_h,
                                                                 after: after_attrs.sort.to_h) }
        reworks_run_id = repo.create_reworks_run(reworks_run_attrs)
        log_status(:cartons, carton_id, AppConst::REWORKS_ACTION_SCRAP_CARTON)
        log_status(:reworks_runs, reworks_run_id, 'CREATED')
        log_transaction
      end
      success_response('Carton scrapped successfully', pallet_sequence_id: before_attrs.to_h[:pallet_sequence_id])
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def restore_repacked_pallets(attrs) # rubocop:disable Metrics/AbcSize
      attrs = attrs.to_h
      pallet_ids = repo.select_values(:pallet_sequences, :pallet_id, pallet_number: attrs[:pallets_selected]).uniq
      pallet_sequence_ids = repo.pallet_sequence_ids(pallet_ids)

      res = nil
      original_pallet_ids = []
      repo.transaction do
        pallet_ids.each do |pallet_id|
          res = FinishedGoodsApp::RestoreRepackedPallet.call(pallet_id)
          return res unless res.success

          original_pallet_ids << res.instance[:original_pallet_id]
        end

        reworks_run_attrs = { user: @user.user_name, reworks_run_type_id: attrs[:reworks_run_type_id], pallets_selected: attrs[:pallets_selected],
                              pallets_affected: nil, pallet_sequence_id: nil, affected_sequences: nil, make_changes: false }
        res = create_reworks_run_record(reworks_run_attrs, nil, nil)
        return failed_response(unwrap_failed_response(res)) unless res.success

        log_multiple_statuses(:pallets, pallet_ids, AppConst::REWORKS_SCRAPPED_STATUS)
        log_multiple_statuses(:pallet_sequences, pallet_sequence_ids, AppConst::REWORKS_SCRAPPED_STATUS)
        log_multiple_statuses(:pallets, original_pallet_ids, AppConst::REWORKS_RESTORE_REPACKED_PALLET_STATUS)
        log_multiple_statuses(:pallet_sequences, repo.pallet_sequence_ids(original_pallet_ids), AppConst::REWORKS_RESTORE_REPACKED_PALLET_STATUS)
      end
      res
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      puts e.message
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def production_run_details_table(production_run_id)
      Crossbeams::Layout::Table.new([], repo.production_run_details(production_run_id), [], pivot: true).render
    end

    def farm_pucs(farm_id)
      farm_repo.selected_farm_pucs(where: { farm_id: farm_id })
    end

    def puc_orchards(farm_id, puc_id)
      farm_repo.for_select_orchards(where: { farm_id: farm_id, puc_id: puc_id })
    end

    def orchard_cultivars(cultivar_group_id, orchard_id)
      orchard = farm_repo.find_orchard(orchard_id)
      orchard.cultivar_ids.nil_or_empty? ? MasterfilesApp::CultivarRepo.new.for_select_cultivars(where: { cultivar_group_id: cultivar_group_id }) : MasterfilesApp::CultivarRepo.new.for_select_cultivars(where: { id: orchard.cultivar_ids.to_a })
    end

    def for_select_basic_pack_actual_counts(basic_pack_code_id, std_fruit_size_count_id)
      fruit_size_repo.for_select_fruit_actual_counts_for_packs(
        where: { basic_pack_code_id: basic_pack_code_id, std_fruit_size_count_id: std_fruit_size_count_id }
      )
    end

    def find_fruit_actual_counts_for_pack_id(basic_pack_code_id, std_fruit_size_count_id)
      args = { basic_pack_code_id: basic_pack_code_id, std_fruit_size_count_id: std_fruit_size_count_id }
      repo.get_value(:fruit_actual_counts_for_packs, :id, args)
    end

    def for_select_actual_count_standard_pack_codes(standard_pack_ids)
      return [] if standard_pack_ids.empty?

      fruit_size_repo.for_select_standard_packs(where: { id: standard_pack_ids })
    end

    def for_select_standard_pack_codes(requires_standard_counts, basic_pack_code_id, standard_pack_ids)
      args = requires_standard_counts ? { id: standard_pack_ids } : { basic_pack_code_id: basic_pack_code_id }
      fruit_size_repo.for_select_standard_packs(where: args)
    end

    def for_select_actual_count_size_references(requires_standard_counts, size_reference_ids)
      requires_standard_counts ? fruit_size_repo.for_select_fruit_size_references(where: { id: size_reference_ids }) : fruit_size_repo.for_select_fruit_size_references
    end

    def for_select_customer_varieties(packed_tm_group_id, marketing_variety_id)
      MasterfilesApp::MarketingRepo.new.for_select_customer_varieties(
        where: { packed_tm_group_id: packed_tm_group_id, marketing_variety_id: marketing_variety_id }
      )
    end

    def for_select_packed_group_tms(packed_tm_group_id)
      MasterfilesApp::TargetMarketRepo.new.for_select_packed_group_tms(
        where: { target_market_group_id: packed_tm_group_id }
      )
    end

    def for_select_pallet_formats(pallet_base_id, pallet_stack_type_id)
      MasterfilesApp::PackagingRepo.new.for_select_pallet_formats(where: { pallet_base_id: pallet_base_id,
                                                                           pallet_stack_type_id: pallet_stack_type_id })
    end

    def for_select_cartons_per_pallets(pallet_format_id, basic_pack_code_id)
      MasterfilesApp::PackagingRepo.new.for_select_cartons_per_pallet(where: { pallet_format_id: pallet_format_id,
                                                                               basic_pack_id: basic_pack_code_id })
    end

    def for_select_pm_type_pm_subtypes(pm_type_id)
      MasterfilesApp::BomRepo.new.for_select_pm_subtypes(where: { pm_type_id: pm_type_id })
    end

    def for_select_setup_pm_boms(commodity_id, std_fruit_size_count_id, basic_pack_code_id)
      MasterfilesApp::BomRepo.new.for_select_setup_pm_boms(commodity_id, std_fruit_size_count_id, basic_pack_code_id)
    end

    def pm_bom_products_table(pm_bom_id, pm_mark_id = nil)
      pm_bom_products = MasterfilesApp::BomRepo.new.pm_bom_products(pm_bom_id)
      add_pm_bom_products_packaging_marks(pm_bom_products, pm_mark_id) unless pm_mark_id.nil_or_empty?

      Crossbeams::Layout::Table.new([], pm_bom_products, [],
                                    alignment: { quantity: :right, composition_level: :right },
                                    cell_transformers: { quantity: :decimal }).render
    end

    def add_pm_bom_products_packaging_marks(pm_bom_products, pm_mark_id)
      packaging_marks = MasterfilesApp::BomRepo.new.find_packaging_marks_by_fruitspec_mark(pm_mark_id)
      return pm_bom_products if packaging_marks.nil_or_empty?

      items = repo.array_of_text_for_db_col(packaging_marks)
      items.each_with_index do |_val, index|
        next if pm_bom_products[index].nil_or_empty?

        composition_level = pm_bom_products[index][:composition_level].to_i
        pm_bom_products[index][:mark] = items[composition_level - 1].to_s
      end
      pm_bom_products
    end

    def second_fruit_stickers(fruit_sticker_pm_product_id)
      repo.for_selected_second_pm_products(AppConst::PM_SUBTYPE_FRUIT_STICKER, fruit_sticker_pm_product_id)
    end

    def for_select_to_orchards(from_orchard_id)
      cultivar_and_farm = repo.find_orchard_cultivar_group_and_farm(from_orchard_id)
      cultivar_and_farm ? repo.find_to_farm_orchards(cultivar_and_farm) : []
    end

    def edit_representative_pallet_sequence(res)
      attrs = res.to_h

      success_response('ok', attrs)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def find_reworks_runs_with(pallet_number)
      # return failed_response("Pallet number : #{pallet_number} doesn't exist") unless repo.pallet_numbers_exists?(pallet_number)

      reworks_runs_ids = repo.find_reworks_runs_with(pallet_number)
      return validation_failed_response(messages: { pallet_number: ["There are no reworks runs for pallet number : #{pallet_number}"] }) if reworks_runs_ids.nil_or_empty?

      success_response('ok', reworks_runs_ids)
    end

    def reject_bulk_production_run_update(reworks_run_type_id)
      reworks_run_type = reworks_run_type(reworks_run_type_id)
      case reworks_run_type
      when AppConst::RUN_TYPE_BULK_PRODUCTION_RUN_UPDATE
        message = "Changes to #{AppConst::REWORKS_ACTION_BULK_PALLET_RUN_UPDATE} has been discarded"
      when AppConst::RUN_TYPE_BULK_BIN_RUN_UPDATE
        message = "Changes to #{AppConst::REWORKS_ACTION_BULK_BIN_RUN_UPDATE} has been discarded"
      end
      success_response('ok', message)
    end

    def production_run_orchard(production_run_id)
      repo.get(:production_runs, :orchard_id, production_run_id)
    end

    def pallet_sequence_pallet_number(sequence_id)
      repo.selected_pallet_numbers(sequence_id)
    end

    def recalc_bins_nett_weight
      Job::RecalculateBinNettWeight.enqueue(recalc_bin_nett_weight_reworks_run_attrs)
      success_response('Recalculate bin nett_weight has been enqued.')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      failed_response(e.message)
    end

    def resolve_work_in_progress_attrs(reworks_run_type_id)
      reworks_run_type = reworks_run_type(reworks_run_type_id)
      attrs = case reworks_run_type
              when AppConst::RUN_TYPE_WIP_PALLETS
                { grid: 'pallets_view', wip_ids: repo.select_values(:wip_pallets, :pallet_id).uniq }
              when AppConst::RUN_TYPE_WIP_BINS
                { grid: 'rmt_bins_reworks', wip_ids: repo.select_values(:wip_bins, :rmt_bin_id).uniq }
              end

      success_response('ok', attrs)
    end

    def create_work_in_progress_lock(reworks_run_type_id, params) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      reworks_run_type = reworks_run_type(reworks_run_type_id)
      res = validate_pallets_selected_input(reworks_run_type, params)
      return validation_failed_response(res) unless res.success

      wip_ids = if reworks_run_type == AppConst::RUN_TYPE_WIP_PALLETS
                  repo.select_values(:pallets, :id, pallet_number: res.instance[:pallet_numbers])
                else
                  res.instance[:pallet_numbers]
                end
      res = validate_wip_objects(reworks_run_type, wip_ids, res.instance[:pallet_numbers])
      return validation_failed_response(res) unless res.success

      repo.transaction do
        res =  case reworks_run_type
               when AppConst::RUN_TYPE_WIP_PALLETS
                 repo.add_pallets_to_wip(wip_ids, params[:context], @user.user_name)
               when AppConst::RUN_TYPE_WIP_BINS
                 repo.add_bins_to_wip(wip_ids, params[:context], @user.user_name)
               end
        raise Crossbeams::InfoError, res.message unless res.success
      end
      success_response('Work In Progress Lock created successfully.')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def validate_wip_objects(reworks_run_type, wip_ids, pallet_numbers)
      res = case reworks_run_type
            when AppConst::RUN_TYPE_WIP_PALLETS
              repo.are_pallets_out_of_wip?(wip_ids)
            when AppConst::RUN_TYPE_WIP_BINS
              repo.are_bins_out_of_wip?(wip_ids)
            end
      unless res.success
        in_wip_ids = reworks_run_type == AppConst::RUN_TYPE_WIP_PALLETS ? repo.select_values(:pallets, :pallet_number, id: res.instance) : res.instance
        msg = "#{reworks_run_type}: #{in_wip_ids.join(', ')} are works in progress"
        return OpenStruct.new(success: false, messages: { pallets_selected: [msg] }, pallets_selected: pallet_numbers)
      end

      ok_response
    end

    def remove_work_in_progress_lock(reworks_run_type_id, multiselect_list) # rubocop:disable Metrics/AbcSize
      reworks_run_type = reworks_run_type(reworks_run_type_id)
      return failed_response('WIP id selection cannot be empty') if multiselect_list.nil_or_empty?

      repo.transaction do
        res =  case reworks_run_type
               when AppConst::RUN_TYPE_WIP_PALLETS
                 repo.remove_pallets_from_wip(multiselect_list, @user.user_name)
               when AppConst::RUN_TYPE_WIP_BINS
                 repo.remove_bins_from_wip(multiselect_list, @user.user_name)
               end
        raise Crossbeams::InfoError, res.message unless res.success
      end
      success_response('Work In Progress Lock released successfully.')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def validate_pallet_reprint_carton_labels(pallet_number, params)
      params[:pallet_id] = repo.get_id(:pallets, pallet_number: pallet_number)
      res = validate_pallet_reprint_carton_labels_params(params)
      return validation_failed_response(res) if res.failure?

      success_response('ok', res.to_h)
    end

    def reprint_pallet_carton_labels(carton_ids, params)
      return failed_response('Carton selection cannot be empty') if carton_ids.nil_or_empty?

      label_name = repo.get(:label_templates, :label_template_name, params[:label_template_id])
      labels = repo.reworks_run_pallet_seq_print_data_for_cartons(carton_ids)
      labels.each do |label|
        LabelPrintingApp::PrintLabel.call(label_name,
                                          label,
                                          no_of_prints: 1,
                                          printer: params[:printer],
                                          supporting_data: { packed_date: label[:packed_date] })
      end
      success_response("#{labels.length} Pallet Carton Labels printed successfully")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def repo
      @repo ||= ReworksRepo.new
    end

    def delivery_repo
      @delivery_repo ||= RawMaterialsApp::RmtDeliveryRepo.new
    end

    def prod_repo
      @prod_repo ||= ProductionApp::ProductionRunRepo.new
    end

    def mesc_repo
      @mesc_repo ||= MesscadaApp::MesscadaRepo.new
    end

    def prod_setup_repo
      @prod_setup_repo ||= ProductionApp::ProductSetupRepo.new
    end

    def fruit_size_repo
      @fruit_size_repo ||= MasterfilesApp::FruitSizeRepo.new
    end

    def farm_repo
      @farm_repo ||= MasterfilesApp::FarmRepo.new
    end

    def reworks_run(id)
      repo.find_reworks_run(id)
    end

    def reworks_run_type(id)
      repo.get(:reworks_run_types, :run_type, id)
    end

    def selected_pallet_numbers(reworks_run_type, sequence_ids)
      if AppConst::RUN_TYPE_UNSCRAP_PALLET == reworks_run_type
        repo.selected_scrapped_pallet_numbers(sequence_ids)
      else
        repo.selected_pallet_numbers(sequence_ids)
      end
    end

    def selected_rmt_bins(rmt_bin_ids)
      repo.selected_rmt_bins(rmt_bin_ids)
    end

    def selected_bins(rmt_bin_ids)
      repo.selected_bins(rmt_bin_ids)
    end

    def selected_pallet_sequences(sequence_ids)
      repo.selected_pallet_sequences(sequence_ids)
    end

    def selected_deliveries(rmt_deliveries_ids)
      repo.selected_deliveries(rmt_deliveries_ids)
    end

    def affected_pallet_numbers(sequence_id, attrs)
      repo.affected_pallet_numbers(sequence_id, attrs)
    end

    def pallet(pallet_number)
      repo.where_hash(:pallets, pallet_number: pallet_number)
    end

    def pallet_sequence(id)
      repo.where_hash(:pallet_sequences, id: id)
    end

    def carton_scrap_attributes(id)
      repo.carton_scrap_attributes(id)
    end

    def find_rmt_bin(bin_number)
      repo.find_rmt_bin(bin_number.to_i)
    end

    def rmt_bin(id)
      repo.where_hash(:rmt_bins, id: id)
    end

    def production_run(id)
      repo.where_hash(:production_runs, id: id)
    end

    def production_run_details(id)
      repo.production_run_details(id)[0]
    end

    def sequence_setup_attrs(id)
      repo.sequence_setup_attrs(id)
    end

    def sequence_setup_data(id)
      repo.sequence_setup_data(id)
    end

    def pallet_number_sequences(pallet_numbers)
      repo.find_sequence_ids_from_pallet_number(pallet_numbers)
    end

    def affected_pallet_sequences(pallet_number, attrs)
      repo.affected_pallet_sequences(pallet_number, attrs)
    end

    # def reworks_run_pallet_print_data(sequence_id)
    #   repo.reworks_run_pallet_data(sequence_id)
    # end
    def reworks_run_pallet_print_data(pallet_number)
      repo.reworks_run_pallet_print_data(pallet_number)
    end

    def reworks_run_carton_print_data(sequence_id)
      repo.reworks_run_pallet_seq_print_data(sequence_id)
    end

    def reworks_run_carton_print_data_for_sequence(sequence_id)
      repo.reworks_run_pallet_seq_print_data_for_sequence(sequence_id)
    end

    def vw_flat_sequence_data(sequence_id)
      repo.reworks_run_pallet_seq_data(sequence_id)
    end

    def label_template_name(label_template_id)
      MasterfilesApp::LabelTemplateRepo.new.find_label_template(label_template_id)&.label_template_name
    end

    def cannot_remove_sequence(pallet_id)
      repo.unscrapped_sequences_count(pallet_id).<= 1
    end

    def allow_sequence_scrapping?(pallet_sequence_id)
      pallet_id = repo.get(:pallet_sequences, :pallet_id, pallet_sequence_id)
      allow = repo.individual_cartons?(pallet_sequence_id)
      allow = false unless repo.pallet_sequence_carton_quantity(pallet_sequence_id) == 1
      allow = false if cannot_remove_sequence(pallet_id)
      allow
    end

    def cannot_scrap_carton(pallet_sequence_id)
      repo.pallet_sequence_carton_quantity(pallet_sequence_id).<= 1
    end

    def standard_pack(standard_pack_code_id)
      return nil if standard_pack_code_id.nil_or_empty?

      repo.get(:standard_pack_codes, :standard_pack_code, standard_pack_code_id)
    end

    def fruit_sticker(fruit_sticker_id)
      return nil if fruit_sticker_id.nil_or_empty?

      repo.get(:pm_products, :product_code, fruit_sticker_id)
    end

    def oldest_sequence_id(pallet_number)
      repo.oldest_sequence_id(pallet_number)
    end

    def pallet_standard_pack_code(pallet_number)
      repo.where_hash(:pallet_sequences, id: oldest_sequence_id(pallet_number))[:standard_pack_code_id]
    end

    def production_run_allow_cultivar_mixing(production_run_id)
      repo.production_run_allow_cultivar_mixing(production_run_id)
    end

    def production_run_allow_cultivar_group_mixing(production_run_id)
      repo.production_run_allow_cultivar_group_mixing(production_run_id)
    end

    def includes_in_stock_pallets?(pallet_numbers)
      repo.includes_in_stock_pallets?(pallet_numbers)
    end

    def deliveries_cultivar_group(cultivar_id)
      repo.deliveries_cultivar_group(cultivar_id)
    end

    def make_changes?(reworks_run_type)
      case reworks_run_type
      when AppConst::RUN_TYPE_SCRAP_PALLET,
           AppConst::RUN_TYPE_SCRAP_BIN,
           AppConst::RUN_TYPE_UNSCRAP_PALLET,
           AppConst::RUN_TYPE_UNSCRAP_BIN,
           AppConst::RUN_TYPE_REPACK,
           AppConst::RUN_TYPE_TIP_BINS,
           AppConst::RUN_TYPE_UNTIP_BINS,
           AppConst::RUN_TYPE_RECALC_NETT_WEIGHT,
           AppConst::RUN_TYPE_BULK_WEIGH_BINS,
           AppConst::RUN_TYPE_BULK_UPDATE_PALLET_DATES,
           AppConst::RUN_TYPE_TIP_MIXED_ORCHARDS,
           AppConst::RUN_TYPE_RESTORE_REPACKED_PALLET,
           AppConst::RUN_TYPE_SCRAP_CARTON,
           AppConst::RUN_TYPE_UNSCRAP_CARTON
        false
      else
        true
      end
    end

    def assert_reworks_in_stock_pallets_permissions(reworks_run_type, pallet_numbers)
      return ok_response unless [AppConst::RUN_TYPE_SINGLE_PALLET_EDIT,
                                 AppConst::RUN_TYPE_BATCH_PALLET_EDIT,
                                 AppConst::RUN_TYPE_BULK_PRODUCTION_RUN_UPDATE].include?(reworks_run_type)

      in_stock_pallets = repo.in_stock_pallets?(pallet_numbers)
      unless in_stock_pallets.nil_or_empty?
        message = "The following pallets #{in_stock_pallets.join(', ')} are in stock and requires user with 'can_change_in_stock_pallets' permission"
        return OpenStruct.new(success: false, messages: { pallets_selected: [message] }, pallets_selected: pallet_numbers) unless can_change_reworks_in_stock_pallets(pallet_numbers)
      end

      success_response('', { pallet_numbers: pallet_numbers })
    end

    def can_change_reworks_in_stock_pallets(pallet_numbers)
      includes_in_stock_pallets?(pallet_numbers) && Crossbeams::Config::UserPermissions.can_user?(@user, :reworks, :can_change_in_stock_pallets)  unless @user&.permission_tree.nil?
    end

    def assert_govt_inspected_pallets_reworks_permissions(reworks_run_type, pallet_numbers)
      return ok_response unless [AppConst::RUN_TYPE_SCRAP_PALLET,
                                 AppConst::RUN_TYPE_UNSCRAP_PALLET].include?(reworks_run_type)

      govt_inspected_pallets = repo.govt_inspected_pallets(pallet_numbers)
      unless govt_inspected_pallets.nil_or_empty?
        can_change = Crossbeams::Config::UserPermissions.can_user?(@user, :reworks, :can_change_govt_inspected_pallets) unless @user&.permission_tree.nil?
        message = "#{govt_inspected_pallets.join(', ')} have passed the govt_inspection and requires user with 'can_change_govt_inspected_pallets' permission"
        return OpenStruct.new(success: false, messages: { pallets_selected: [message] }, pallets_selected: pallet_numbers) unless can_change
      end

      success_response('', { pallet_numbers: pallet_numbers })
    end

    def validate_pallet_numbers(reworks_run_type, pallet_numbers, production_run_id = nil) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      pallet_numbers = pallet_numbers.split(/\n|,/).map(&:strip).reject(&:empty?)
      pallet_numbers = pallet_numbers.map { |x| x.gsub(/['"]/, '') }

      invalid_pallet_numbers = pallet_numbers.reject { |x| x.match(/\A\d+\Z/) }
      return OpenStruct.new(success: false, messages: { pallets_selected: ["#{invalid_pallet_numbers.join(', ')} must be numeric"] }, pallets_selected: pallet_numbers) unless invalid_pallet_numbers.nil_or_empty?

      existing_pallet_numbers = repo.pallet_numbers_exists?(pallet_numbers)
      missing_pallet_numbers = (pallet_numbers - existing_pallet_numbers)
      return OpenStruct.new(success: false, messages: { pallets_selected: ["#{missing_pallet_numbers.join(', ')} doesn't exist"] }, pallets_selected: pallet_numbers) unless missing_pallet_numbers.nil_or_empty?

      if AppConst::RUN_TYPE_RESTORE_REPACKED_PALLET == reworks_run_type
        repacked_pallets = repo.repacked_pallets?(pallet_numbers, where: { repacked: true })
        missing_pallets = (pallet_numbers - repacked_pallets)
        return OpenStruct.new(success: false, messages: { pallets_selected: ["#{missing_pallets.join(', ')} cannot be restored - they are not repacked"] }, pallets_selected: pallet_numbers) unless missing_pallets.nil_or_empty?
      else
        repacked_pallets = repo.repacked_pallets?(pallet_numbers, where: { exit_ref:  AppConst::PALLET_EXIT_REF_REPACKED })
        return OpenStruct.new(success: false, messages: { pallets_selected: ["#{repacked_pallets.join(', ')} have been repacked."] }, pallets_selected: pallet_numbers) unless repacked_pallets.nil_or_empty?
      end

      shipped_pallets = repo.shipped_pallets?(pallet_numbers)
      return OpenStruct.new(success: false, messages: { pallets_selected: ["#{shipped_pallets.join(', ')} have been shipped."] }, pallets_selected: pallet_numbers) unless shipped_pallets.nil_or_empty?

      if [AppConst::RUN_TYPE_SCRAP_PALLET, AppConst::RUN_TYPE_RESTORE_REPACKED_PALLET].include?(reworks_run_type)
        allocated_pallets = repo.allocated_pallets?(pallet_numbers)
        return OpenStruct.new(success: false, messages: { pallets_selected: ["#{allocated_pallets.join(', ')} have been allocated."] }, pallets_selected: pallet_numbers) unless allocated_pallets.nil_or_empty?
      end

      if AppConst::RUN_TYPE_SCRAP_PALLET == reworks_run_type
        inspection_pallets = repo.open_govt_inspection_sheet_pallets(pallet_numbers)
        msg = "An open Government Inspection Sheet is preventing the scrapping of the following pallets: #{inspection_pallets.join(', ')}."
        return OpenStruct.new(success: false, messages: { pallets_selected: [msg] }, pallets_selected: pallet_numbers) unless inspection_pallets.nil_or_empty?
      end

      scrapped_pallets = repo.scrapped_pallets?(pallet_numbers)
      if AppConst::RUN_TYPE_UNSCRAP_PALLET == reworks_run_type
        unscrapped_pallets = (pallet_numbers - scrapped_pallets)
        return OpenStruct.new(success: false, messages: { pallets_selected: ["#{unscrapped_pallets.join(', ')} cannot be unscrapped - they are not scrapped"] }, pallets_selected: pallet_numbers) unless unscrapped_pallets.nil_or_empty?
      else
        return OpenStruct.new(success: false, messages: { pallets_selected: ["#{scrapped_pallets.join(', ')} already scrapped"] }, pallets_selected: pallet_numbers) unless scrapped_pallets.nil_or_empty?
      end

      if AppConst::RUN_TYPE_BULK_PRODUCTION_RUN_UPDATE == reworks_run_type
        production_run_pallets = repo.production_run_pallets?(pallet_numbers, production_run_id)
        extra_pallets = (pallet_numbers - production_run_pallets)
        return OpenStruct.new(success: false, messages: { pallets_selected: ["#{extra_pallets.join(', ')} are not from production run #{production_run_id}"] }, pallets_selected: pallet_numbers) unless extra_pallets.nil_or_empty?
      end
      OpenStruct.new(success: true, instance: { pallet_numbers: pallet_numbers })
    end

    def validate_rmt_bins(reworks_run_type, rmt_bins, production_run_id = nil) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      rmt_bins = rmt_bins.split(/\n|,/).map(&:strip).reject(&:empty?)
      rmt_bins = rmt_bins.map { |x| x.gsub(/['"]/, '') }

      invalid_rmt_bins = rmt_bins.reject { |x| x.match(/\A\d+\Z/) }
      return OpenStruct.new(success: false, messages: { pallets_selected: ["#{invalid_rmt_bins.join(', ')} must be numeric"] }, pallets_selected: rmt_bins) unless invalid_rmt_bins.nil_or_empty?

      existing_rmt_bins = repo.rmt_bins_exists?(rmt_bins)
      missing_rmt_bins = (rmt_bins - existing_rmt_bins.map(&:to_s))
      return OpenStruct.new(success: false, messages: { pallets_selected: ["#{missing_rmt_bins.join(', ')} doesn't exist"] }, pallets_selected: rmt_bins) unless missing_rmt_bins.nil_or_empty?

      if [AppConst::RUN_TYPE_TIP_BINS, AppConst::RUN_TYPE_TIP_MIXED_ORCHARDS].include?(reworks_run_type)
        tipped_bins = repo.tipped_bins?(rmt_bins)
        return OpenStruct.new(success: false, messages: { pallets_selected: ["#{tipped_bins.join(', ')} already tipped"] }, pallets_selected: rmt_bins) unless tipped_bins.nil_or_empty?
      end

      if AppConst::RUN_TYPE_UNTIP_BINS == reworks_run_type
        untipped_bins = repo.untipped_bins?(rmt_bins)
        return OpenStruct.new(success: false, messages: { pallets_selected: ["#{untipped_bins.join(', ')} not tipped"] }, pallets_selected: rmt_bins) unless untipped_bins.nil_or_empty?
      end

      scrapped_bins = repo.scrapped_bins?(rmt_bins)
      if AppConst::RUN_TYPE_UNSCRAP_BIN == reworks_run_type
        unscrapped_bins = (rmt_bins - scrapped_bins.map(&:to_s))
        return OpenStruct.new(success: false, messages: { pallets_selected: ["#{unscrapped_bins.join(', ')} not scrapped"] }, pallets_selected: rmt_bins) unless unscrapped_bins.nil_or_empty?
      else
        return OpenStruct.new(success: false, messages: { pallets_selected: ["#{scrapped_bins.join(', ')} already scrapped"] }, pallets_selected: rmt_bins) unless scrapped_bins.nil_or_empty?
      end

      if AppConst::RUN_TYPE_BULK_BIN_RUN_UPDATE == reworks_run_type
        production_run_bins = repo.production_run_bins?(rmt_bins, production_run_id)
        extra_bins = (rmt_bins - production_run_bins.map(&:to_s))
        return OpenStruct.new(success: false, messages: { pallets_selected: ["#{extra_bins.join(', ')} are not from production run #{production_run_id}"] }, pallets_selected: rmt_bins) unless extra_bins.nil_or_empty?
      end

      # TO DO: The staging process sets an attribute on a rmt_bin to indicate on which presort staging run it is staged
      # Reworks can check that field. Only allow bins in reworks if that field is null.
      # if AppConst::RUN_TYPE_SINGLE_BIN_EDIT == reworks_run_type
      #   staging_bins = repo.presort_staging_bins?(rmt_bins)
      #   return OpenStruct.new(success: false, messages: { pallets_selected: ["#{staging_bins.join(', ')} on presort staging run"] }, pallets_selected: rmt_bins) unless staging_bins.nil_or_empty?
      # end

      OpenStruct.new(success: true, instance: { pallet_numbers: rmt_bins })
    end

    def validate_production_runs(reworks_run_type, params) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      from_production_run_id = params[:from_production_run_id]
      to_production_run_id = params[:to_production_run_id]
      pallets_selected = params[:pallets_selected]
      allow_cultivar_group_mixing = params[:allow_cultivar_group_mixing] == 't' if AppConst::CR_PROD.can_mix_cultivar_groups?

      return OpenStruct.new(success: false, messages: { to_production_run_id: ["#{to_production_run_id} should be different"] }, to_production_run_id: to_production_run_id) unless from_production_run_id != to_production_run_id

      old_production_run = repo.production_run_exists?(from_production_run_id)
      return OpenStruct.new(success: false, messages: { from_production_run_id: ["#{from_production_run_id} doesn't exist"] }, from_production_run_id: from_production_run_id) if old_production_run.nil_or_empty?

      new_production_run = repo.production_run_exists?(from_production_run_id)
      return OpenStruct.new(success: false, messages: { to_production_run_id: ["#{to_production_run_id} doesn't exist"] }, to_production_run_id: to_production_run_id) if new_production_run.nil_or_empty?

      if AppConst::CR_PROD.can_mix_cultivar_groups? && allow_cultivar_group_mixing
        same_commodity = repo.same_commodity?(from_production_run_id, to_production_run_id)
        return OpenStruct.new(success: false, messages: { to_production_run_id: ["#{from_production_run_id} and #{to_production_run_id} belongs to different same_commodities"] }, to_production_run_id: to_production_run_id) unless same_commodity
      else
        same_cultivar_group = repo.same_cultivar_group?(from_production_run_id, to_production_run_id)
        return OpenStruct.new(success: false, messages: { to_production_run_id: ["#{from_production_run_id} and #{to_production_run_id} belongs to different cultivar groups"] }, to_production_run_id: to_production_run_id) unless same_cultivar_group
      end

      if AppConst::RUN_TYPE_BULK_PRODUCTION_RUN_UPDATE == reworks_run_type
        res = validate_pallet_numbers(reworks_run_type, params[:pallets_selected], from_production_run_id)
      elsif AppConst::RUN_TYPE_BULK_BIN_RUN_UPDATE == reworks_run_type
        res = validate_rmt_bins(reworks_run_type, params[:pallets_selected], from_production_run_id)
      end
      return OpenStruct.new(success: false,  messages: res.messages, pallets_selected: pallets_selected.split(',')) unless res.success

      attrs = { from_production_run_id: from_production_run_id, to_production_run_id: to_production_run_id, pallet_numbers: res.instance[:pallet_numbers] }
      OpenStruct.new(success: true, instance:  attrs)
    end

    def validate_carton_labels(reworks_run_type, cartons_string) # rubocop:disable Metrics/AbcSize
      carton_labels = cartons_string.split(/\n|,/).map(&:strip).reject(&:empty?)
      carton_labels.map! { |x| x.gsub(/['"]/, '') }

      invalid_carton_labels = carton_labels.reject { |x| x.match(/\A\d+\Z/) }
      return OpenStruct.new(success: false, messages: { pallets_selected: ["#{invalid_carton_labels.join(', ')} must be numeric"] }, pallets_selected: carton_labels) unless invalid_carton_labels.nil_or_empty?

      referenced_carton_labels = repo.carton_labels_on_pallet_sequence(carton_labels)
      return OpenStruct.new(success: false, messages: { pallets_selected: ["#{referenced_carton_labels.join(', ')} doesn't exist"] }, pallets_selected: carton_labels) unless referenced_carton_labels.nil_or_empty?

      scrapped_carton_labels = repo.scrapped_carton_labels(carton_labels)
      if AppConst::RUN_TYPE_UNSCRAP_CARTON == reworks_run_type
        unscrapped_carton_labels = (carton_labels - scrapped_carton_labels.map(&:to_s))
        return OpenStruct.new(success: false, messages: { pallets_selected: ["#{unscrapped_carton_labels.join(', ')} already unscrapped"] }, pallets_selected: carton_labels) unless unscrapped_carton_labels.nil_or_empty?
      else
        return OpenStruct.new(success: false, messages: { pallets_selected: ["#{scrapped_carton_labels.join(', ')} already scrapped"] }, pallets_selected: carton_labels) unless scrapped_carton_labels.nil_or_empty?
      end

      OpenStruct.new(success: true, instance: { pallet_numbers: carton_labels })
    end

    def validate_reworks_run_new_params(reworks_run_type, params)
      case reworks_run_type
      when AppConst::RUN_TYPE_SCRAP_PALLET,
           AppConst::RUN_TYPE_SCRAP_CARTON,
           AppConst::RUN_TYPE_SCRAP_BIN # WHY NOT ReworksRunScrapBinSchema ????
        ReworksRunScrapPalletsSchema.call(params)
      when AppConst::RUN_TYPE_TIP_BINS,
           AppConst::RUN_TYPE_TIP_MIXED_ORCHARDS
        ReworksRunTipBinsSchema.call(params)
      when AppConst::RUN_TYPE_BULK_PRODUCTION_RUN_UPDATE,
           AppConst::RUN_TYPE_BULK_BIN_RUN_UPDATE
        ReworksRunBulkProductionRunUpdateSchema.call(params)
      when AppConst::RUN_TYPE_BULK_WEIGH_BINS
        ReworksBulkWeighBinsSchema.call(params)
      when AppConst::RUN_TYPE_BULK_UPDATE_PALLET_DATES
        ReworksBulkUpdatePalletDatesSchema.call(params)
      else
        ReworksRunNewSchema.call(params)
      end
    end

    def validate_reworks_run_params(params)
      ReworksRunFlatSchema.call(params)
    end

    def validate_print_params(params)
      ReworksRunPrintBarcodeSchema.call(params)
    end

    def validate_update_gross_weight_params(params)
      ReworksRunUpdateGrossWeightSchema.call(params)
    end

    def validate_update_pallet_params(params)
      ReworksRunUpdatePalletSchema.call(params)
    end

    def validate_update_reworks_production_run_params(params)
      ProductionRunUpdateSchema.call(params)
    end

    def validate_update_reworks_farm_details_params(params)
      ProductionRunUpdateFarmDetailsSchema.call(params)
    end

    def validate_edit_carton_quantity_params(params)
      EditCartonQuantitySchema.call(params)
    end

    def validate_manually_weigh_rmt_bin_params(params)
      ManuallyWeighRmtBinSchema.call(params)
    end

    def validate_change_delivery_orchard_params(params)
      ChangeDeliveriesOrchardSchema.call(params)
    end

    def validate_clone_carton_params(params)
      ReworksRunCloneCartonSchema.call(params)
    end

    def validate_clone_sequence_params(params)
      ReworksRunCloneSequenceSchema.call(params)
    end

    def validate_production_run_params(params)
      ProductionRunChangeSchema.call(params)
    end

    def validate_run_orchard_change_params(params)
      ProductionRunOrchardChangeSchema.call(params)
    end

    def validate_reworks_change_run_orchard_params(params)
      ReworksRunChangeRunOrchardSchema.call(params)
    end

    def validate_reworks_change_run_cultivar_params(params)
      ReworksRunChangeRunCultivarSchema.call(params)
    end

    def validate_delivery_params(params)
      DeliveryChangeSchema.call(params)
    end

    def validate_edit_rmt_bin_params(params)
      EditRmtBinSchema.call(params)
    end

    def validate_pallet_reprint_carton_labels_params(params)
      ReprintPalletCartonLabelsSchema.call(params)
    end
  end
end
