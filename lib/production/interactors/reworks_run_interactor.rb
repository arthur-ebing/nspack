# frozen_string_literal: true

module ProductionApp
  class ReworksRunInteractor < BaseInteractor # rubocop:disable ClassLength
    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::ReworksRun.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def resolve_pallet_numbers_from_multiselect(reworks_run_type_id, multiselect_list)
      return failed_response('Pallet Selection cannot be empty') if multiselect_list.nil_or_empty?

      reworks_run_type = reworks_run_type(reworks_run_type_id)
      pallet_numbers = selected_pallet_numbers(reworks_run_type, multiselect_list)
      instance = { reworks_run_type_id: reworks_run_type_id,
                   pallets_selected: pallet_numbers.join("\n") }
      success_response('', instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_reworks_run(reworks_run_type_id, params)  # rubocop:disable Metrics/AbcSize
      reworks_run_type = reworks_run_type(reworks_run_type_id)
      res = validate_pallet_numbers(reworks_run_type, params[:pallets_selected])
      return validation_failed_response(res) unless res.success

      params[:pallets_selected] = res.instance[:pallet_numbers]
      res = validate_reworks_run_new_params(reworks_run_type, params)
      return validation_failed_response(res) unless res.messages.empty?

      make_changes = make_changes?(reworks_run_type)
      attrs = res.to_h.merge(user: @user.user_name, make_changes: make_changes, pallets_affected: nil, pallet_sequence_id: nil)
      return success_response('ok', attrs) if make_changes

      rw_res = nil
      repo.transaction do
        rw_res = create_reworks_run_record(attrs, nil, nil)
        log_status('reworks_runs', rw_res.instance[:reworks_run_id], 'CREATED')
        log_transaction
      end
      rw_res
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_reworks_run_record(attrs, reworks_action, changes)
      res = validate_reworks_run_params(attrs)
      return validation_failed_response(res) unless res.messages.empty?

      rw_res = ProductionApp::CreateReworksRun.call(res, reworks_action, changes)
      success_response('ok', reworks_run_id: rw_res.instance[:reworks_run_id])
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def print_reworks_pallet_label(pallet_number, params)  # rubocop:disable Metrics/AbcSize
      res = validate_print_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      instance = reworks_run_pallet_print_data(pallet_number)
      repo.transaction do
        LabelPrintingApp::PrintLabel.call(res.instance[:label_template], instance, quantity: res.instance[:quantity], printer: res.instance[:printer])
        log_transaction
      end
      success_response('Label printed successfully')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def print_reworks_carton_label(sequence_id, params)  # rubocop:disable Metrics/AbcSize
      res = validate_print_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      instance = reworks_run_carton_print_data(sequence_id)
      repo.transaction do
        LabelPrintingApp::PrintLabel.call(res.instance[:label_template], instance, quantity: res.instance[:quantity], printer: res.instance[:printer])
        log_transaction
      end
      success_response('Label printed successfully')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def clone_pallet_sequence(sequence_id, reworks_run_type_id)  # rubocop:disable Metrics/AbcSize
      instance = nil
      repo.transaction do
        new_id = repo.clone_pallet_sequence(sequence_id)
        reworks_run_attrs = reworks_run_attrs(new_id, reworks_run_type_id)
        instance = pallet_sequence(new_id)
        rw_res = create_reworks_run_record(reworks_run_attrs, AppConst::REWORKS_ACTION_CLONE, before: {}, after: instance)
        return validation_failed_response(unwrap_failed_response(rw_res)) unless rw_res.success

        log_status('reworks_runs', rw_res.instance[:reworks_run_id], 'CREATED')
        log_transaction
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
        make_changes: true
      }
    end

    def remove_pallet_sequence(sequence_id, reworks_run_type_id)  # rubocop:disable Metrics/AbcSize
      before_attrs = changes_attrs(sequence_id)
      repo.transaction do
        reworks_run_attrs = reworks_run_attrs(sequence_id, reworks_run_type_id)
        repo.remove_pallet_sequence(sequence_id)
        rw_res = create_reworks_run_record(reworks_run_attrs,
                                           AppConst::REWORKS_ACTION_REMOVE,
                                           before: before_attrs.sort.to_h, after: changes_attrs(sequence_id).sort.to_h)
        return validation_failed_response(unwrap_failed_response(rw_res)) unless rw_res.success

        log_status('reworks_runs', rw_res.instance[:reworks_run_id], 'CREATED')
        log_transaction
      end
      success_response('Pallet Sequence removed successfully', pallet_number: before_attrs.to_h[:pallet_number])
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def changes_attrs(sequence_id)
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
      old_instance = pallet_sequence(sequence_id)
      repo.transaction do
        repo.edit_carton_quantities(sequence_id, params[:column_value])
        reworks_run_attrs = reworks_run_attrs(sequence_id, reworks_run_type_id)
        rw_res = create_reworks_run_record(reworks_run_attrs,
                                           AppConst::REWORKS_ACTION_EDIT_CARTON_QUANTITY,
                                           before: { carton_quantity: old_instance[:carton_quantity] }, after: { carton_quantity: params[:column_value] })
        return validation_failed_response(rw_res) unless rw_res.success

        log_status('reworks_runs', rw_res.instance[:reworks_run_id], 'CREATED')
        log_transaction
      end
      instance = repo.reworks_run_pallet_seq_data(sequence_id)
      success_response('Pallet Sequence carton quantity updated successfully', instance)
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

    def update_pallet_sequence_record(sequence_id, reworks_run_type_id, res)  # rubocop:disable Metrics/AbcSize
      attrs = res.to_h
      treatment_ids = attrs.delete(:treatment_ids)
      attrs = attrs.merge(treatment_ids: "{#{treatment_ids.join(',')}}") unless treatment_ids.nil?

      repo.transaction do
        reworks_run_attrs = reworks_run_attrs(sequence_id, reworks_run_type_id)
        reworks_run_attrs[:pallets_affected] = affected_pallet_numbers(sequence_id, attrs)
        rw_res = create_reworks_run_record(reworks_run_attrs, AppConst::REWORKS_ACTION_SINGLE_EDIT, before: sequence_setup_attrs(sequence_id).sort.to_h, after: attrs.sort.to_h)
        return validation_failed_response(rw_res) unless rw_res.success

        pallet_id = pallet_sequence(sequence_id)[:pallet_id]
        log_status('pallets', pallet_id, AppConst::RW_PALLET_SINGLE_EDIT)
        log_status('pallet_sequences', sequence_id, AppConst::RW_PALLET_SINGLE_EDIT)
        log_transaction
      end
      success_response('Pallet Sequence updated successfully', pallet_number: pallet_sequence_pallet_number(sequence_id).first)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def reject_pallet_sequence_changes(sequence_id)
      success_response('Changes to Pallet sequence has be discarded', pallet_number: pallet_sequence_pallet_number(sequence_id).first)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def resolve_selected_pallet_numbers(pallets_selected)
      return pallets_selected if pallets_selected.nil_or_empty?

      pallet_numbers = pallets_selected.join(',').split(/\n|,/).map(&:strip).reject(&:empty?)
      pallet_numbers = pallet_numbers.map { |x| x.gsub(/['"]/, '') }
      pallet_numbers.join("\n")
    end

    private

    def repo
      @repo ||= ReworksRepo.new
    end

    def reworks_run(id)
      repo.find_reworks_run(id)
    end

    def reworks_run_type(id)
      repo.find_reworks_run_type(id)
    end

    def selected_pallet_numbers(reworks_run_type, sequence_ids)
      if AppConst::RUN_TYPE_UNSCRAP_PALLET == reworks_run_type
        repo.selected_scrapped_pallet_numbers(sequence_ids)
      else
        repo.selected_pallet_numbers(sequence_ids)
      end
    end

    def validate_pallet_numbers(reworks_run_type, pallet_numbers)  # rubocop:disable Metrics/AbcSize
      pallet_numbers = pallet_numbers.split(/\n|,/).map(&:strip).reject(&:empty?)
      pallet_numbers = pallet_numbers.map { |x| x.gsub(/['"]/, '') }

      invalid_pallet_numbers = pallet_numbers.reject { |x| x.match(/\A\d+\Z/) }
      return OpenStruct.new(success: false, messages: { pallets_selected: ["#{invalid_pallet_numbers.join(', ')} must be numeric"] }) unless invalid_pallet_numbers.nil_or_empty?

      existing_pallet_numbers = repo.pallet_numbers_exists?(pallet_numbers)
      missing_pallet_numbers = (pallet_numbers - existing_pallet_numbers)
      return OpenStruct.new(success: false, messages: { pallets_selected: ["#{missing_pallet_numbers.join(', ')} doesn't exist"] }) unless missing_pallet_numbers.nil_or_empty?

      scrapped_pallets = repo.scrapped_pallets?(pallet_numbers)

      if AppConst::RUN_TYPE_UNSCRAP_PALLET == reworks_run_type
        unscrapped_pallets = (pallet_numbers - scrapped_pallets)
        return OpenStruct.new(success: false, messages: { pallets_selected: ["#{unscrapped_pallets.join(', ')} cannot be unscrapped"] }) unless unscrapped_pallets.nil_or_empty?
      else
        return OpenStruct.new(success: false, messages: { pallets_selected: ["#{scrapped_pallets.join(', ')} already scrapped"] }) unless scrapped_pallets.nil_or_empty?
      end

      OpenStruct.new(success: true, instance: { pallet_numbers: pallet_numbers })
    end

    def validate_reworks_run_new_params(reworks_run_type, params)
      case reworks_run_type
      when AppConst::RUN_TYPE_SCRAP_PALLET then
        ReworksRunScrapPalletsSchema.call(params)
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

    def make_changes?(reworks_run_type)
      case reworks_run_type
      when AppConst::RUN_TYPE_SCRAP_PALLET, AppConst::RUN_TYPE_UNSCRAP_PALLET, AppConst::RUN_TYPE_REPACK then
        false
      else
        true
      end
    end

    def pallet_sequence_pallet_number(sequence_id)
      repo.selected_pallet_numbers(sequence_id)
    end

    def affected_pallet_numbers(sequence_id, attrs)
      repo.affected_pallet_numbers(sequence_id, attrs)
    end

    def pallet_sequence(id)
      repo.where_hash(:pallet_sequences, id: id)
    end

    def sequence_setup_attrs(id)
      repo.sequence_setup_attrs(id)
    end

    def reworks_run_pallet_print_data(sequence_id)
      repo.reworks_run_pallet_data(sequence_id)
    end

    def reworks_run_carton_print_data(sequence_id)
      repo.reworks_run_pallet_seq_data(sequence_id)
    end

    def validate_reworks_run_pallet_sequence_params(params)
      ProductSetupSchema.call(params)
    end
  end
end
