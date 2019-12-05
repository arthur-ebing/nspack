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
        log_reworks_runs_status_and_transaction(rw_res.instance[:reworks_run_id], nil, nil, nil)
      end
      rw_res
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_reworks_run_record(attrs, reworks_action, changes)
      res = validate_reworks_run_params(attrs)
      return validation_failed_response(res) unless res.messages.empty?

      rw_res = ProductionApp::CreateReworksRun.call(res, reworks_action, changes)
      success_response('Pallet change was successful', reworks_run_id: rw_res.instance[:reworks_run_id])
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
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
      success_response('Label printed successfully')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def print_reworks_carton_label(sequence_id, params)  # rubocop:disable Metrics/AbcSize
      res = validate_print_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      instance = reworks_run_carton_print_data(sequence_id)
      label_name = label_template_name(res[:label_template_id])
      repo.transaction do
        LabelPrintingApp::PrintLabel.call(label_name, instance, quantity: res[:no_of_prints], printer: res[:printer])
        log_transaction
      end
      success_response('Label printed successfully')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def clone_pallet_sequence(sequence_id, reworks_run_type_id)  # rubocop:disable Metrics/AbcSize
      before_attrs = sequence_changes(sequence_id)
      return failed_response('Sequence cannot be cloned', pallet_number: before_attrs[:pallet_number]) if AppConst::CARTON_EQUALS_PALLET

      instance = nil
      repo.transaction do
        new_id = repo.clone_pallet_sequence(sequence_id)
        reworks_run_attrs = reworks_run_attrs(new_id, reworks_run_type_id)
        instance = pallet_sequence(new_id)
        rw_res = create_reworks_run_record(reworks_run_attrs,
                                           AppConst::REWORKS_ACTION_CLONE,
                                           before: {}, after: instance)
        return validation_failed_response(unwrap_failed_response(rw_res)) unless rw_res.success

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
        make_changes: true
      }
    end

    def remove_pallet_sequence(sequence_id, reworks_run_type_id)  # rubocop:disable Metrics/AbcSize
      before_attrs = sequence_changes(sequence_id)
      return failed_response('Sequence cannot be removed', pallet_number: before_attrs[:pallet_number]) if AppConst::CARTON_EQUALS_PALLET || cannot_remove_sequence(before_attrs[:pallet_id])

      repo.transaction do
        reworks_run_attrs = reworks_run_attrs(sequence_id, reworks_run_type_id)
        repo.remove_pallet_sequence(sequence_id)
        rw_res = create_reworks_run_record(reworks_run_attrs,
                                           AppConst::REWORKS_ACTION_REMOVE,
                                           before: before_attrs.sort.to_h, after: sequence_changes(sequence_id).sort.to_h)
        return validation_failed_response(unwrap_failed_response(rw_res)) unless rw_res.success

        log_reworks_runs_status_and_transaction(rw_res.instance[:reworks_run_id], before_attrs[:pallet_id], sequence_id, AppConst::REWORKS_ACTION_REMOVE)
      end
      success_response('Pallet Sequence removed successfully', pallet_number: before_attrs.to_h[:pallet_number])
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def sequence_changes(sequence_id)
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

        log_reworks_runs_status_and_transaction(rw_res.instance[:reworks_run_id], old_instance[:pallet_id], sequence_id, AppConst::REWORKS_ACTION_EDIT_CARTON_QUANTITY)
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
        rw_res = create_reworks_run_record(reworks_run_attrs,
                                           AppConst::REWORKS_ACTION_SINGLE_EDIT,
                                           before: sequence_setup_attrs(sequence_id).sort.to_h, after: attrs.sort.to_h)
        return validation_failed_response(rw_res) unless rw_res.success

        pallet_id = pallet_sequence(sequence_id)[:pallet_id]
        log_reworks_runs_status_and_transaction(rw_res.instance[:reworks_run_id], pallet_id, sequence_id, AppConst::RW_PALLET_SINGLE_EDIT)
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

    def production_run_details_table(production_run_id)
      Crossbeams::Layout::Table.new([], ProductionApp::ReworksRepo.new.production_run_details(production_run_id), [], pivot: true).render
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
      MasterfilesApp::FruitSizeRepo.new.for_select_fruit_actual_counts_for_packs(where: { basic_pack_code_id: basic_pack_code_id,
                                                                                          std_fruit_size_count_id: std_fruit_size_count_id })
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

    def update_reworks_production_run(params)  # rubocop:disable Metrics/AbcSize
      res = validate_update_reworks_production_run_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      attrs = res.to_h
      sequence_id = attrs[:pallet_sequence_id]
      sequence = pallet_sequence(sequence_id)
      before_attrs = farm_details_attrs(sequence).merge(production_run_id: attrs[:old_production_run_id],
                                                        packhouse_resource_id: sequence[:packhouse_resource_id],
                                                        production_line_id: sequence[:production_line_id])
      production_run = production_run(attrs[:production_run_id])
      after_attrs = farm_details_attrs(production_run).merge(production_run_id: attrs[:production_run_id],
                                                             packhouse_resource_id: production_run[:packhouse_resource_id],
                                                             production_line_id: production_run[:production_line_id])
      repo.transaction do
        reworks_run_attrs = reworks_run_attrs(sequence_id, attrs[:reworks_run_type_id])
        repo.update_pallet_sequence(sequence_id, after_attrs)
        rw_res = create_reworks_run_record(reworks_run_attrs,
                                           AppConst::REWORKS_ACTION_CHANGE_PRODUCTION_RUN,
                                           before: before_attrs.sort.to_h, after: after_attrs.sort.to_h)
        return validation_failed_response(unwrap_failed_response(rw_res)) unless rw_res.success

        log_reworks_runs_status_and_transaction(rw_res.instance[:reworks_run_id], sequence[:pallet_id], sequence_id, AppConst::REWORKS_ACTION_CHANGE_PRODUCTION_RUN)
      end
      instance = pallet_sequence(sequence_id)
      success_response('Pallet Sequence production_run_id changed successfully', pallet_number: instance[:pallet_number])
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
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

      repo.transaction do
        reworks_run_attrs = reworks_run_attrs(sequence_id, reworks_run_type_id)
        repo.update_pallet_sequence(sequence_id, after_attrs)
        rw_res = create_reworks_run_record(reworks_run_attrs,
                                           AppConst::REWORKS_ACTION_CHANGE_FARM_DETAILS,
                                           before: before_attrs.sort.to_h, after: after_attrs.sort.to_h)
        return validation_failed_response(unwrap_failed_response(rw_res)) unless rw_res.success

        log_reworks_runs_status_and_transaction(rw_res.instance[:reworks_run_id], instance[:pallet_id], sequence_id, AppConst::REWORKS_ACTION_CHANGE_FARM_DETAILS)
      end
      success_response('Pallet Sequence farm details changed successfully', pallet_number: instance[:pallet_number])
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def farm_details_attrs(sequence)
      { farm_id: sequence[:farm_id],
        puc_id: sequence[:puc_id],
        orchard_id: sequence[:orchard_id],
        cultivar_group_id: sequence[:cultivar_group_id],
        cultivar_id: sequence[:cultivar_id],
        season_id: sequence[:season_id] }
    end

    def log_reworks_runs_status_and_transaction(id, pallet_id, sequence_id, status)
      log_status('pallets', pallet_id, status) unless pallet_id.nil_or_empty?
      log_status('pallet_sequences', sequence_id, status) unless sequence_id.nil_or_empty?
      log_status('reworks_runs', id, 'CREATED')
      log_transaction
    end

    def update_pallet_gross_weight(params)  # rubocop:disable Metrics/AbcSize
      res = validate_update_gross_weight_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      attrs = res.to_h
      instance = pallet(attrs[:pallet_number])
      pallet_number = instance[:pallet_number]
      repo.transaction do
        repo.update_pallet_gross_weight(instance[:id], attrs)
        reworks_run_attrs = { user: @user.user_name, reworks_run_type_id: attrs[:reworks_run_type_id], pallets_selected: Array(pallet_number),
                              pallets_affected: nil, pallet_sequence_id: nil, make_changes: true }
        rw_res = create_reworks_run_record(reworks_run_attrs,
                                           AppConst::REWORKS_ACTION_SET_GROSS_WEIGHT,
                                           before: { gross_weight: instance[:gross_weight] }, after: { gross_weight: attrs[:gross_weight] })
        return validation_failed_response(unwrap_failed_response(rw_res)) unless rw_res.success

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
      before_attrs = { fruit_sticker_pm_product_id: instance[:fruit_sticker_pm_product_id], fruit_sticker_pm_product_2_id: instance[:fruit_sticker_pm_product_2_id] }
      repo.transaction do
        repo.update_pallet(instance[:id], attrs)
        reworks_run_attrs = { user: @user.user_name, reworks_run_type_id: reworks_run_type_id, pallets_selected: Array(pallet_number),
                              pallets_affected: nil, pallet_sequence_id: nil, make_changes: true }
        rw_res = create_reworks_run_record(reworks_run_attrs,
                                           AppConst::REWORKS_ACTION_UPDATE_PALLET_DETAILS,
                                           before: before_attrs, after: attrs)
        return validation_failed_response(unwrap_failed_response(rw_res)) unless rw_res.success

        log_reworks_runs_status_and_transaction(rw_res.instance[:reworks_run_id], instance[:id], nil, AppConst::REWORKS_ACTION_UPDATE_PALLET_DETAILS)
      end
      success_response('Pallet details updated successfully', pallet_number: pallet_number)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
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

    def validate_update_gross_weight_params(params)
      ReworksRunUpdateGrossWeightSchema.call(params)
    end

    def validate_update_pallet_params(params)
      ReworksRunUpdatePalletSchema.call(params)
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

    def pallet(pallet_number)
      repo.where_hash(:pallets, pallet_number: pallet_number)
    end

    def pallet_sequence(id)
      repo.where_hash(:pallet_sequences, id: id)
    end

    def production_run(id)
      repo.where_hash(:production_runs, id: id)
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

    def label_template_name(label_template_id)
      MasterfilesApp::LabelTemplateRepo.new.find_label_template(label_template_id)&.label_template_name
    end

    def cannot_remove_sequence(pallet_id)
      repo.unscrapped_sequences_count(pallet_id).> 1
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
  end
end
