# frozen_string_literal: true

module ProductionApp
  class ReworksRunInteractor < BaseInteractor # rubocop:disable ClassLength
    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::ReworksRun.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def validate_change_delivery_orchard_screen_params(params) # rubocop:disable Metrics/AbcSize
      res = validate_only_cultivar_change(params)
      unless res.messages.empty?
        error_res = validation_failed_response(res)
        error_res.message = "#{error_res.message}: you must allow_cultivar_mixing when changing only the cultivar"
        return error_res
      end

      res = validate_change_delivery_orchard_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      res = validate_changes_made?(params)
      return failed_response('No Changes were made') unless res

      if params[:allow_cultivar_mixing] == 'f'
        res = validate_from_cultivar_param(params)
        return validation_failed_response(res) unless res.messages.empty?
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

    def apply_change_deliveries_orchard_changes(allow_cultivar_mixing, to_orchard, to_cultivar, delivery_ids, reworks_run_type_id) # rubocop:disable Metrics/AbcSize
      reworks_run_attrs = { allow_cultivar_mixing: allow_cultivar_mixing == 't', user: @user.user_name, pallets_affected: delivery_ids.split(','), pallets_selected: delivery_ids.split(','), reworks_run_type_id: reworks_run_type_id }
      res = validate_reworks_run_params(reworks_run_attrs)
      return validation_failed_response(res) unless res.messages.empty?

      reworks_run_attrs[:changes_made] = calc_changes_made(to_orchard.to_i, to_cultivar.to_i, delivery_ids)
      return failed_response(reworks_run_attrs[:changes_made]) if reworks_run_attrs[:changes_made].is_a?(String)

      return failed_response('Cannot proceed. Some bins in some of the deliveries are in production_runs that do not allow orchard mixing') unless check_bins_production_runs_allow_mixing?(delivery_ids)

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
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message('apply_change_deliveries_orchard_changes'))
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
      orchard = MasterfilesApp::FarmRepo.new.find_farm_orchard_by_orchard_id(to_orchard)
      cultivar = MasterfilesApp::CultivarRepo.new.find_cultivar(to_cultivar)&.cultivar_name

      changes = []
      repo.find_from_deliveries_cultivar(delivery_ids).group_by { |h| h[:cultivar_name] }.each do |_k, v|
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
        log_status('rmt_bins', bin[:id], 'DELIVERY_ORCHARD_CHANGE')
      end

      repo.find_deliveries(delivery_ids).each do |del|
        log_status('rmt_deliveries', del[:id], 'DELIVERY_ORCHARD_CHANGE')
      end
    end

    def resolve_pallet_numbers_from_multiselect(reworks_run_type_id, multiselect_list)
      return failed_response('Pallet selection cannot be empty') if multiselect_list.nil_or_empty?

      reworks_run_type = reworks_run_type(reworks_run_type_id)
      pallet_numbers = selected_pallet_numbers(reworks_run_type, multiselect_list)
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
                 when AppConst::RUN_TYPE_BULK_BIN_RUN_UPDATE
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

    def bulk_production_run_update(reworks_run_type_id, multiselect_list, attrs)  # rubocop:disable Metrics/AbcSize
      return failed_response('Pallet sequence selection cannot be empty') if multiselect_list.nil_or_empty?

      reworks_run_type = reworks_run_type(reworks_run_type_id)
      res = resolve_input_from_multiselect(reworks_run_type, reworks_run_type_id, multiselect_list)
      return validation_failed_response(res) unless res.success

      attrs[:pallets_selected] = res.instance[:pallets_selected].split("\n")
      id = nil
      repo.transaction do
        res = resolve_update_selected_input(reworks_run_type, attrs)
        id = repo.create_reworks_run(user: attrs[:user],
                                     reworks_run_type_id: attrs[:reworks_run_type_id],
                                     pallets_selected: "{ #{attrs[:pallets_selected].join(',')} }",
                                     pallets_affected: "{ #{attrs[:pallets_selected].join(',')} }",
                                     changes_made: res[:changes_made])
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

    def resolve_update_selected_input(reworks_run_type, attrs)  # rubocop:disable Metrics/AbcSize
      change_descriptions = {}
      case reworks_run_type
      when AppConst::RUN_TYPE_BULK_PRODUCTION_RUN_UPDATE
        message = "#{AppConst::REWORKS_ACTION_BULK_PALLET_RUN_UPDATE} was successful"
        children = pallet_number_sequences(attrs[:pallets_selected])
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
        res = FinishedGoodsApp::MoveStockService.new(AppConst::BIN_STOCK_TYPE, bin_number, location_id, AppConst::REWORKS_MOVE_BIN_BUSINESS_PROCESS, nil).call
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

    def create_reworks_run(reworks_run_type_id, params)  # rubocop:disable Metrics/AbcSize
      reworks_run_type = reworks_run_type(reworks_run_type_id)
      res = validate_pallets_selected_input(reworks_run_type, params)
      return validation_failed_response(res) unless res.success

      params[:pallets_selected] = res.instance[:pallet_numbers]
      res = validate_reworks_run_new_params(reworks_run_type, params)
      return validation_failed_response(res) unless res.messages.empty?

      make_changes = make_changes?(reworks_run_type)
      attrs = res.to_h.merge(user: @user.user_name, make_changes: make_changes, pallets_affected: nil, pallet_sequence_id: nil, affected_sequences: nil)
      return success_response('ok', attrs.merge(display_page: display_page(reworks_run_type))) if make_changes

      return manually_tip_bins(attrs) if AppConst::RUN_TYPE_TIP_BINS == reworks_run_type

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
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message('create_reworks_run'))
      failed_response(e.message)
    end

    def validate_pallets_selected_input(reworks_run_type, params)
      case reworks_run_type
      when AppConst::RUN_TYPE_TIP_BINS,
           AppConst::RUN_TYPE_WEIGH_RMT_BINS,
           AppConst::RUN_TYPE_SCRAP_BIN,
          AppConst::RUN_TYPE_UNSCRAP_BIN
        validate_rmt_bins(reworks_run_type, params[:pallets_selected])
      when AppConst::RUN_TYPE_BULK_PRODUCTION_RUN_UPDATE,
          AppConst::RUN_TYPE_BULK_BIN_RUN_UPDATE
        validate_production_runs(reworks_run_type, params)
      else
        validate_pallet_numbers(reworks_run_type, params[:pallets_selected])
      end
    end

    def display_page(reworks_run_type)
      case reworks_run_type
      when AppConst::RUN_TYPE_WEIGH_RMT_BINS
        'edit_rmt_bin_gross_weight'
      when AppConst::RUN_TYPE_SINGLE_PALLET_EDIT,
         AppConst::RUN_TYPE_BATCH_PALLET_EDIT
        'edit_pallet'
      when AppConst::RUN_TYPE_BULK_PRODUCTION_RUN_UPDATE,
          AppConst::RUN_TYPE_BULK_BIN_RUN_UPDATE
        'edit_bulk_production_run'
      end
    end

    def create_reworks_run_record(attrs, reworks_action, changes) # rubocop:disable Metrics/AbcSize
      res = validate_reworks_run_params(attrs)
      return validation_failed_response(res) unless res.messages.empty?

      return create_scrap_bin_reworks_run(res) if repo.find_reworks_run_type(attrs[:reworks_run_type_id])[:run_type] == AppConst::RUN_TYPE_SCRAP_BIN
      return create_unscrap_bin_reworks_run(res) if repo.find_reworks_run_type(attrs[:reworks_run_type_id])[:run_type] == AppConst::RUN_TYPE_UNSCRAP_BIN

      rw_res = ProductionApp::CreateReworksRun.call(res, reworks_action, changes)
      return failed_response(unwrap_failed_response(rw_res), attrs) unless rw_res.success

      success_response('Pallet change was successful', reworks_run_id: rw_res.instance[:reworks_run_id])
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_scrap_bin_reworks_run(params) # rubocop:disable Metrics/AbcSize
      repo.scrapped_bin_bulk_update(params)
      id = repo.create_reworks_run(user: params[:user],
                                   reworks_run_type_id: params[:reworks_run_type_id],
                                   scrap_reason_id: params[:scrap_reason_id],
                                   remarks: params[:remarks],
                                   pallets_selected: "{ #{params[:pallets_selected].join(',')} }",
                                   pallets_affected: "{ #{params[:pallets_selected].join(',')} }",
                                   changes_made: nil,
                                   bins_scrapped: "{ #{params[:pallets_selected].join(',')} }",
                                   pallets_unscrapped: nil)
      params[:pallets_selected].each do |bin| # LOG MULTIPLE!!!!!!!!!!!!!!
        log_status(:rmt_bins, bin, 'SCRAPPED')
      end
      success_response('Bins Scrapped successfully', reworks_run_id: id)
    end

    def create_unscrap_bin_reworks_run(params) # rubocop:disable Metrics/AbcSize
      repo.unscrapped_bin_bulk_update(params)
      id = repo.create_reworks_run(user: params[:user],
                                   reworks_run_type_id: params[:reworks_run_type_id],
                                   pallets_selected: "{ #{params[:pallets_selected].join(',')} }",
                                   pallets_affected: "{ #{params[:pallets_selected].join(',')} }",
                                   changes_made: nil,
                                   bins_unscrapped: "{ #{params[:pallets_selected].join(',')} }",
                                   pallets_unscrapped: nil)
      params[:pallets_selected].each do |bin|
        log_status(:rmt_bins, bin, AppConst::BIN_EXIT_REF_UNSCRAPPED)
      end
      success_response('Bins Unscrapped successfully', reworks_run_id: id)
    end

    def print_reworks_pallet_label(pallet_number, params)  # rubocop:disable Metrics/AbcSize
      res = validate_print_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      instance = reworks_run_pallet_print_data(pallet_number)
      label_name = label_template_name(res[:label_template_id])
      repo.transaction do
        LabelPrintingApp::PrintLabel.call(label_name, instance, quantity: res[:no_of_prints], printer: res[:printer])
        log_transaction
      end
      success_response('Pallet Label printed successfully', pallet_number: pallet_number)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def print_reworks_carton_label(sequence_id, params)  # rubocop:disable Metrics/AbcSize
      res = validate_print_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      instance = reworks_run_carton_print_data(sequence_id)
      label_name = label_template_name(res[:label_template_id])
      repo.transaction do
        LabelPrintingApp::PrintLabel.call(label_name, instance, quantity: res[:no_of_prints], printer: res[:printer], supporting_data: { packed_date: instance[:packed_date] })
        log_transaction
      end
      success_response('Carton Label printed successfully')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def clone_pallet_sequence(sequence_id, reworks_run_type_id)  # rubocop:disable Metrics/AbcSize
      old_sequence_instance = pallet_sequence(sequence_id)
      return failed_response('Sequence cannot be cloned', pallet_number: old_sequence_instance[:pallet_number]) if AppConst::CARTON_EQUALS_PALLET

      instance = nil
      repo.transaction do
        new_id = repo.clone_pallet_sequence(sequence_id)
        reworks_run_attrs = reworks_run_attrs(new_id, reworks_run_type_id)
        instance = pallet_sequence(new_id)
        rw_res = create_reworks_run_record(reworks_run_attrs,
                                           AppConst::REWORKS_ACTION_CLONE,
                                           before: {}, after: instance)
        return failed_response(unwrap_failed_response(rw_res)) unless rw_res.success

        log_reworks_runs_status_and_transaction(rw_res.instance[:reworks_run_id], instance[:pallet_id], sequence_id, AppConst::REWORKS_ACTION_CLONE)
      end
      success_response('Pallet Sequence cloned successfully', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
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

    def remove_pallet_sequence(sequence_id, reworks_run_type_id)  # rubocop:disable Metrics/AbcSize
      before_attrs = remove_sequence_changes(sequence_id)
      return failed_response('Sequence cannot be removed', pallet_number: before_attrs[:pallet_number]) if AppConst::CARTON_EQUALS_PALLET || cannot_remove_sequence(before_attrs[:pallet_id])

      repo.transaction do
        reworks_run_attrs = reworks_run_attrs(sequence_id, reworks_run_type_id)
        repo.remove_pallet_sequence(sequence_id)
        rw_res = create_reworks_run_record(reworks_run_attrs,
                                           AppConst::REWORKS_ACTION_REMOVE,
                                           before: before_attrs.sort.to_h, after: remove_sequence_changes(sequence_id).sort.to_h)
        return failed_response(unwrap_failed_response(rw_res)) unless rw_res.success

        log_reworks_runs_status_and_transaction(rw_res.instance[:reworks_run_id], before_attrs[:pallet_id], sequence_id, AppConst::REWORKS_ACTION_REMOVE)
      end
      success_response('Pallet Sequence removed successfully', pallet_number: before_attrs.to_h[:pallet_number])
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def remove_sequence_changes(sequence_id)
      instance = pallet_sequence(sequence_id)
      { removed_from_pallet: instance[:removed_from_pallet],
        removed_from_pallet_at: instance[:removed_from_pallet_at],
        removed_from_pallet_id: instance[:removed_from_pallet_id],
        pallet_id: instance[:pallet_id],
        carton_quantity: instance[:carton_quantity],
        exit_ref: instance[:exit_ref],
        pallet_number: instance[:pallet_number] }
    end

    def edit_carton_quantities(sequence_id, reworks_run_type_id, params)  # rubocop:disable Metrics/AbcSize
      res = validate_edit_carton_quantity_params(params)
      return validation_failed_response(res) unless res.messages.empty?

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

    def update_reworks_run_pallet_sequence(params)  # rubocop:disable Metrics/AbcSize,  Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      if AppConst::CLIENT_CODE == 'kr'
        if params[:fruit_actual_counts_for_pack_id].to_i.nonzero?.nil? && params[:basic_pack_code_id].to_i.nonzero?.nil? && params[:standard_pack_code_id].to_i.nonzero?.nil?
          standard_pack_code_id = standard_pack_code_id(params[:fruit_actual_counts_for_pack_id], params[:basic_pack_code_id])
          return failed_response(standard_pack_code_id) if standard_pack_code_id.is_a? String

          params = params.merge(standard_pack_code_id: standard_pack_code_id)
        end
      end

      res = validate_reworks_run_pallet_sequence_params(params)
      return validation_failed_response(res) unless res.messages.empty?
      return failed_response('You did not choose a Size Reference or Actual Count') if params[:fruit_size_reference_id].to_i.nonzero?.nil? && params[:fruit_actual_counts_for_pack_id].to_i.nonzero?.nil?

      rejected_fields = %i[id product_setup_template_id pallet_label_name]
      attrs = res.to_h.reject { |k, _| rejected_fields.include?(k) }

      success_response('Ok', attrs)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def standard_pack_code_id(fruit_actual_counts_for_pack_id, basic_pack_code_id)
      if fruit_actual_counts_for_pack_id.to_i.nonzero?.nil?
        standard_pack_code_id = repo.basic_pack_standard_pack_code_id(basic_pack_code_id) unless basic_pack_code_id.to_i.nonzero?.nil?
        return 'Cannot find Standard Pack' if standard_pack_code_id.nil?
      else
        standard_pack_code_id = MasterfilesApp::FruitSizeRepo.new.find_fruit_actual_counts_for_pack(fruit_actual_counts_for_pack_id).standard_pack_code_ids
        return 'There is a 1 to many relationship between the Actual Count and Standard Pack' unless standard_pack_code_id.size.==1
      end
      standard_pack_code_id
    end

    def update_pallet_sequence_record(sequence_id, reworks_run_type_id, res, batch_pallet_numbers = nil)  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      batch_update = batch_pallet_numbers.nil_or_empty? ? false : true
      before_attrs = sequence_setup_attrs(sequence_id).sort.to_h

      attrs = res.to_h
      changed_attrs = attrs.reject { |k, v|  before_attrs.key?(k) && before_attrs[k] == v }
      changed_treatment_ids = changed_attrs.delete(:treatment_ids)
      changed_attrs = changed_attrs.merge(treatment_ids: "{#{changed_treatment_ids.join(',')}}") unless changed_treatment_ids.nil?
      return failed_response('Changed attributes cannot be empty') if changed_attrs.nil_or_empty?

      treatment_ids = attrs.delete(:treatment_ids)
      attrs = attrs.merge(treatment_ids: "{#{treatment_ids.join(',')}}") unless treatment_ids.nil?

      before_descriptions_state = sequence_setup_data(sequence_id)
      sequences = batch_update ? affected_pallet_sequences(pallet_number_sequences(batch_pallet_numbers), changed_attrs) : sequence_id
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
            sequence = pallet_sequence(id)
            log_reworks_runs_status_and_transaction(rw_res.instance[:reworks_run_id], sequence[:pallet_id], id, AppConst::REWORKS_ACTION_BATCH_EDIT)
          end
        else
          msg = 'Pallet Sequence updated successfully'
          pallet_id = pallet_sequence(sequence_id)[:pallet_id]
          log_reworks_runs_status_and_transaction(rw_res.instance[:reworks_run_id], pallet_id, sequence_id, AppConst::RW_PALLET_SINGLE_EDIT)
        end
      end
      instance = { pallet_number: pallet_sequence_pallet_number(sequence_id).first,
                   batch_update: batch_update }
      success_response("#{msg}.", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
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

    def update_reworks_production_run(params)  # rubocop:disable Metrics/AbcSize
      res = validate_update_reworks_production_run_params(params)
      return validation_failed_response(res) unless res.messages.empty?

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
        rw_res = create_reworks_run_record(reworks_run_attrs,
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
      { farm_id: instance[:farm_id],
        puc_id: instance[:puc_id],
        orchard_id: instance[:orchard_id],
        cultivar_group_id: instance[:cultivar_group_id],
        cultivar_id: instance[:cultivar_id],
        season_id: instance[:season_id] }
    end

    def production_run_description_changes(production_run_id, instance_data)
      { production_run_id: production_run_id,
        packhouse: instance_data[:packhouse],
        line: instance_data[:line] }.merge(farm_detail_description_changes(instance_data))
    end

    def farm_detail_description_changes(instance_data)
      { farm: instance_data[:farm],
        puc: instance_data[:puc],
        orchard: instance_data[:orchard],
        cultivar_group: instance_data[:cultivar_group],
        cultivar: instance_data[:cultivar],
        season: instance_data[:season] }
    end

    def update_reworks_farm_details(params)  # rubocop:disable Metrics/AbcSize
      res = validate_update_reworks_farm_details_params(params)
      return validation_failed_response(res) unless res.messages.empty?

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

    def update_pallet_gross_weight(params)  # rubocop:disable Metrics/AbcSize
      res = validate_update_gross_weight_params(params)
      return validation_failed_response(res) unless res.messages.empty?

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

    def update_pallet_details(params)  # rubocop:disable Metrics/AbcSize
      res = validate_update_pallet_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      attrs = res.to_h
      reworks_run_type_id = attrs.delete(:reworks_run_type_id)
      pallet_number = attrs.delete(:pallet_number)
      instance = pallet(pallet_number)

      before_attrs = { fruit_sticker_pm_product_id: instance[:fruit_sticker_pm_product_id],
                       fruit_sticker_pm_product_2_id: instance[:fruit_sticker_pm_product_2_id] }
      before_descriptions_state = { fruit_sticker: fruit_sticker(instance[:fruit_sticker_pm_product_id]),
                                    fruit_sticker_2: fruit_sticker(instance[:fruit_sticker_pm_product_2_id]) }
      after_descriptions_state = { fruit_sticker: fruit_sticker(attrs[:fruit_sticker_pm_product_id]),
                                   fruit_sticker_2: fruit_sticker(attrs[:fruit_sticker_pm_product_2_id]) }
      change_descriptions = { before: before_descriptions_state.sort.to_h, after: after_descriptions_state.sort.to_h }
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

    def manually_tip_bins(attrs)  # rubocop:disable Metrics/AbcSize
      attrs = attrs.to_h

      rw_res = nil
      repo.transaction do
        rw_res = ProductionApp::ManuallyTipBins.call(attrs)
        reworks_run_attrs = { user: @user.user_name, reworks_run_type_id: attrs[:reworks_run_type_id], pallets_selected: attrs[:pallets_selected],
                              pallets_affected: nil, pallet_sequence_id: nil, affected_sequences: nil, make_changes: false }
        rw_res = create_reworks_run_record(reworks_run_attrs,
                                           nil,
                                           before: manually_tip_bin_before_state(attrs[:pallets_selected].first).sort.to_h, after: manually_tip_bin_after_state(attrs[:pallets_selected].first, attrs[:production_run_id]).sort.to_h)
        return failed_response(unwrap_failed_response(rw_res)) unless rw_res.success

        log_status(:reworks_runs, rw_res.instance[:reworks_run_id], AppConst::RMT_BIN_TIPPED_MANUALLY)
      end
      success_response('Rmt Bin tipped successfully', pallet_number: attrs[:pallets_selected])
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def manually_tip_bin_before_state(rmt_bin_id)
      defaults = { bin_tipped_date_time: nil,
                   production_run_tipped_id: nil,
                   exit_ref_date_time: nil,
                   bin_tipped: false,
                   exit_ref: nil,
                   tipped_manually: false }
      defaults = defaults.merge!(tipped_asset_number: nil, bin_asset_number: rmt_bin_id) if AppConst::USE_PERMANENT_RMT_BIN_BARCODES
      defaults
    end

    def manually_tip_bin_after_state(rmt_bin_id, production_run_id)
      defaults = { bin_tipped_date_time: Time.now,
                   production_run_tipped_id: production_run_id,
                   exit_ref_date_time: Time.now,
                   bin_tipped: true,
                   exit_ref: 'TIPPED',
                   tipped_manually: true }
      defaults = defaults.merge!(tipped_asset_number: rmt_bin_id, bin_asset_number: nil) if AppConst::USE_PERMANENT_RMT_BIN_BARCODES
      defaults
    end

    def manually_weigh_rmt_bin(params)  # rubocop:disable Metrics/AbcSize
      res = validate_manually_weigh_rmt_bin_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      attrs = res.to_h
      rmt_bin_id = find_rmt_bin(attrs[:bin_number])
      before_state = manually_weigh_rmt_bin_state(rmt_bin_id)

      rw_res = nil
      repo.transaction do
        rw_res = MesscadaApp::UpdateBinWeights.call(attrs, true)
        return failed_response(unwrap_failed_response(rw_res), attrs) unless rw_res.success

        repo.update_rmt_bin(rmt_bin_id, weighed_manually: true)
        reworks_run_attrs = { user: @user.user_name, reworks_run_type_id: attrs[:reworks_run_type_id], pallets_selected: Array(attrs[:bin_number]),
                              pallets_affected: nil, pallet_sequence_id: nil, affected_sequences: nil, make_changes: false }
        rw_res = create_reworks_run_record(reworks_run_attrs,
                                           nil,
                                           before: before_state, after: manually_weigh_rmt_bin_state(rmt_bin_id))
        return failed_response(unwrap_failed_response(rw_res)) unless rw_res.success

        log_reworks_rmt_bin_status_and_transaction(rw_res.instance[:reworks_run_id], rmt_bin_id, AppConst::RMT_BIN_WEIGHED_MANUALLY)
      end
      success_response('Rmt Bin weighed successfully', pallet_number: attrs[:bin_number])
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def manually_weigh_rmt_bin_state(rmt_bin_id)
      instance = rmt_bin(rmt_bin_id)
      { gross_weight: instance[:gross_weight],
        nett_weight: instance[:nett_weight],
        weighed_manually: instance[:weighed_manually] }
    end

    def production_run_details_table(production_run_id)
      Crossbeams::Layout::Table.new([], repo.production_run_details(production_run_id), [], pivot: true).render
    end

    def farm_pucs(farm_id)
      MasterfilesApp::FarmRepo.new.selected_farm_pucs(farm_id)
    end

    def puc_orchards(farm_id, puc_id)
      MasterfilesApp::FarmRepo.new.selected_farm_orchard_codes(farm_id, puc_id)
    end

    def orchard_cultivars(cultivar_group_id, orchard_id)
      orchard = MasterfilesApp::FarmRepo.new.find_orchard(orchard_id)
      orchard.cultivar_ids.nil_or_empty? ? MasterfilesApp::CultivarRepo.new.for_select_cultivars(where: { cultivar_group_id: cultivar_group_id }) : MasterfilesApp::CultivarRepo.new.for_select_cultivars(where: { id: orchard.cultivar_ids.to_a })
    end

    def for_select_basic_pack_actual_counts(basic_pack_code_id, std_fruit_size_count_id)
      MasterfilesApp::FruitSizeRepo.new.for_select_fruit_actual_counts_for_packs(where: { basic_pack_code_id: basic_pack_code_id, std_fruit_size_count_id: std_fruit_size_count_id })
    end

    def for_select_actual_count_standard_pack_codes(standard_pack_code_ids)
      return [] if standard_pack_code_ids.empty?

      MasterfilesApp::FruitSizeRepo.new.for_select_standard_pack_codes(where: [[:id, standard_pack_code_ids.map { |r| r }]])
    end

    def for_select_actual_count_size_references(size_reference_ids)
      MasterfilesApp::FruitSizeRepo.new.for_select_fruit_size_references(where: [[:id, size_reference_ids.map { |r| r }]]) || MasterfilesApp::FruitSizeRepo.new.for_select_fruit_size_references
    end

    def for_select_customer_variety_varieties(packed_tm_group_id, marketing_variety_id)
      MasterfilesApp::MarketingRepo.new.for_select_customer_variety_marketing_varieties(packed_tm_group_id, marketing_variety_id)
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
      MasterfilesApp::BomsRepo.new.for_select_pm_subtypes(where: { pm_type_id: pm_type_id })
    end

    def for_select_pm_subtype_pm_boms(pm_subtype_id)
      MasterfilesApp::BomsRepo.new.for_select_pm_subtype_pm_boms(pm_subtype_id)
    end

    def pm_bom_products_table(pm_bom_id)
      Crossbeams::Layout::Table.new([], MasterfilesApp::BomsRepo.new.pm_bom_products(pm_bom_id), [],
                                    alignment: { quantity: :right },
                                    cell_transformers: { quantity: :decimal }).render
    end

    def second_fruit_stickers(fruit_sticker_pm_product_id)
      repo.for_selected_second_pm_products(AppConst::PM_TYPE_FRUIT_STICKER, fruit_sticker_pm_product_id)
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

    private

    def repo
      @repo ||= ReworksRepo.new
    end

    def reworks_run(id)
      repo.find_reworks_run(id)
    end

    def reworks_run_type(id)
      repo.get(:reworks_run_types, id, :run_type)
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

    def pallet_sequence_pallet_number(sequence_id)
      repo.selected_pallet_numbers(sequence_id)
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

    def find_rmt_bin(bin_number)
      # return repo.rmt_bin_from_asset_number(bin_number) if AppConst::USE_PERMANENT_RMT_BIN_BARCODES

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

    def vw_flat_sequence_data(sequence_id)
      repo.reworks_run_pallet_seq_data(sequence_id)
    end

    def label_template_name(label_template_id)
      MasterfilesApp::LabelTemplateRepo.new.find_label_template(label_template_id)&.label_template_name
    end

    def cannot_remove_sequence(pallet_id)
      repo.unscrapped_sequences_count(pallet_id).<= 1
    end

    def standard_pack(standard_pack_code_id)
      return nil if standard_pack_code_id.nil_or_empty?

      repo.get(:standard_pack_codes, standard_pack_code_id, :standard_pack_code)
    end

    def fruit_sticker(fruit_sticker_id)
      return nil if fruit_sticker_id.nil_or_empty?

      repo.get(:pm_products, fruit_sticker_id, :product_code)
    end

    def oldest_sequence_id(pallet_number)
      @repo.oldest_sequence_id(pallet_number)
    end

    def pallet_standard_pack_code(pallet_number)
      @repo.where_hash(:pallet_sequences, id: oldest_sequence_id(pallet_number))[:standard_pack_code_id]
    end

    def make_changes?(reworks_run_type)
      case reworks_run_type
      when AppConst::RUN_TYPE_SCRAP_PALLET,
           AppConst::RUN_TYPE_SCRAP_BIN,
           AppConst::RUN_TYPE_UNSCRAP_PALLET,
          AppConst::RUN_TYPE_UNSCRAP_BIN,
           AppConst::RUN_TYPE_REPACK,
           AppConst::RUN_TYPE_TIP_BINS,
           AppConst::RUN_TYPE_RECALC_NETT_WEIGHT
        false
      else
        true
      end
    end

    def validate_pallet_numbers(reworks_run_type, pallet_numbers, production_run_id = nil)  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      pallet_numbers = pallet_numbers.split(/\n|,/).map(&:strip).reject(&:empty?)
      pallet_numbers = pallet_numbers.map { |x| x.gsub(/['"]/, '') }

      invalid_pallet_numbers = pallet_numbers.reject { |x| x.match(/\A\d+\Z/) }
      return OpenStruct.new(success: false, messages: { pallets_selected: ["#{invalid_pallet_numbers.join(', ')} must be numeric"] }, pallets_selected: pallet_numbers) unless invalid_pallet_numbers.nil_or_empty?

      existing_pallet_numbers = repo.pallet_numbers_exists?(pallet_numbers)
      missing_pallet_numbers = (pallet_numbers - existing_pallet_numbers)
      return OpenStruct.new(success: false, messages: { pallets_selected: ["#{missing_pallet_numbers.join(', ')} doesn't exist"] }, pallets_selected: pallet_numbers) unless missing_pallet_numbers.nil_or_empty?

      scrapped_pallets = repo.scrapped_pallets?(pallet_numbers)

      if AppConst::RUN_TYPE_UNSCRAP_PALLET == reworks_run_type
        unscrapped_pallets = (pallet_numbers - scrapped_pallets)
        return OpenStruct.new(success: false, messages: { pallets_selected: ["#{unscrapped_pallets.join(', ')} cannot be unscrapped"] }, pallets_selected: pallet_numbers) unless unscrapped_pallets.nil_or_empty?
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

      # unless AppConst::USE_PERMANENT_RMT_BIN_BARCODES
      invalid_rmt_bins = rmt_bins.reject { |x| x.match(/\A\d+\Z/) }
      return OpenStruct.new(success: false, messages: { pallets_selected: ["#{invalid_rmt_bins.join(', ')} must be numeric"] }, pallets_selected: rmt_bins) unless invalid_rmt_bins.nil_or_empty?

      # end

      existing_rmt_bins = repo.rmt_bins_exists?(rmt_bins)
      missing_rmt_bins = (rmt_bins - existing_rmt_bins.map(&:to_s))
      return OpenStruct.new(success: false, messages: { pallets_selected: ["#{missing_rmt_bins.join(', ')} doesn't exist"] }, pallets_selected: rmt_bins) unless missing_rmt_bins.nil_or_empty?

      if AppConst::RUN_TYPE_TIP_BINS == reworks_run_type
        tipped_bins = repo.tipped_bins?(rmt_bins)
        return OpenStruct.new(success: false, messages: { pallets_selected: ["#{tipped_bins.join(', ')} already tipped"] }, pallets_selected: rmt_bins) unless tipped_bins.nil_or_empty?
      end

      res = validate_scrapped_rmt_bins(reworks_run_type, rmt_bins)
      return OpenStruct.new(success: false,  messages: res.messages, pallets_selected: rmt_bins) unless res.success

      if AppConst::RUN_TYPE_UNSCRAP_BIN == reworks_run_type
        scrapped_bins = repo.scrapped_bins?(rmt_bins)
        unscrapped_bins = (rmt_bins - scrapped_bins.map(&:to_s))
        return OpenStruct.new(success: false, messages: { pallets_selected: ["#{unscrapped_bins.join(', ')} not scrapped"] }, pallets_selected: rmt_bins) unless unscrapped_bins.nil_or_empty?
      end

      if AppConst::RUN_TYPE_BULK_BIN_RUN_UPDATE == reworks_run_type
        production_run_bins = repo.production_run_bins?(rmt_bins, production_run_id)
        extra_bins = (rmt_bins - production_run_bins)
        return OpenStruct.new(success: false, messages: { pallets_selected: ["#{extra_bins.join(', ')} are not from production run #{production_run_id}"] }, pallets_selected: rmt_bins) unless extra_bins.nil_or_empty?
      end

      OpenStruct.new(success: true, instance: { pallet_numbers: rmt_bins })
    end

    def validate_scrapped_rmt_bins(reworks_run_type, rmt_bins)
      case reworks_run_type
      when AppConst::RUN_TYPE_SCRAP_BIN,
          AppConst::RUN_TYPE_BULK_BIN_RUN_UPDATE,
          AppConst::RUN_TYPE_TIP_BINS,
          AppConst::RUN_TYPE_WEIGH_RMT_BINS

        scrapped_bins = repo.scrapped_bins?(rmt_bins)
        return OpenStruct.new(success: false, messages: { pallets_selected: ["#{scrapped_bins.join(', ')} already scrapped"] }, pallets_selected: rmt_bins) unless scrapped_bins.nil_or_empty?

      end

      OpenStruct.new(success: true, instance: { pallets_selected: rmt_bins })
    end

    def validate_production_runs(reworks_run_type, params)  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      from_production_run_id = params[:from_production_run_id]
      to_production_run_id = params[:to_production_run_id]
      pallets_selected = params[:pallets_selected]

      return OpenStruct.new(success: false, messages: { to_production_run_id: ["#{to_production_run_id} should be different"] }, to_production_run_id: to_production_run_id) unless from_production_run_id != to_production_run_id

      old_production_run = repo.production_run_exists?(from_production_run_id)
      return OpenStruct.new(success: false, messages: { from_production_run_id: ["#{from_production_run_id} doesn't exist"] }, from_production_run_id: from_production_run_id) if old_production_run.nil_or_empty?

      new_production_run = repo.production_run_exists?(from_production_run_id)
      return OpenStruct.new(success: false, messages: { to_production_run_id: ["#{to_production_run_id} doesn't exist"] }, to_production_run_id: to_production_run_id) if new_production_run.nil_or_empty?

      same_cultivar_group = repo.same_cultivar_group?(from_production_run_id, to_production_run_id)
      return OpenStruct.new(success: false, messages: { to_production_run_id: ["#{from_production_run_id} and #{to_production_run_id} belongs to different cultivar groups"] }, to_production_run_id: to_production_run_id) unless same_cultivar_group

      if AppConst::RUN_TYPE_BULK_PRODUCTION_RUN_UPDATE == reworks_run_type
        res = validate_pallet_numbers(reworks_run_type, params[:pallets_selected], from_production_run_id)
      elsif AppConst::RUN_TYPE_BULK_BIN_RUN_UPDATE == reworks_run_type
        res = validate_rmt_bins(reworks_run_type, params[:pallets_selected], from_production_run_id)
      end
      return OpenStruct.new(success: false,  messages: res.messages, pallets_selected: pallets_selected.split(',')) unless res.success

      attrs = { from_production_run_id: from_production_run_id, to_production_run_id: to_production_run_id, pallet_numbers: res.instance[:pallet_numbers] }
      OpenStruct.new(success: true, instance:  attrs)
    end

    def validate_reworks_run_new_params(reworks_run_type, params)
      case reworks_run_type
      when AppConst::RUN_TYPE_SCRAP_PALLET,
           AppConst::RUN_TYPE_SCRAP_BIN # WHY NOT ReworksRunScrapBinSchema ????
        ReworksRunScrapPalletsSchema.call(params)
      when AppConst::RUN_TYPE_TIP_BINS
        ReworksRunTipBinsSchema.call(params)
      when AppConst::RUN_TYPE_BULK_PRODUCTION_RUN_UPDATE,
          AppConst::RUN_TYPE_BULK_BIN_RUN_UPDATE
        ReworksRunBulkProductionRunUpdateSchema.call(params)
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

    def validate_reworks_run_pallet_sequence_params(params)
      SequenceSetupDataSchema.call(params)
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
  end
end
