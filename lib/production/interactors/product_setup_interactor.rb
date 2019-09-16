# frozen_string_literal: true

module ProductionApp
  class ProductSetupInteractor < BaseInteractor # rubocop:disable ClassLength
    def create_product_setup(params)  # rubocop:disable Metrics/AbcSize
      res = validate_product_setup_params(params)
      return validation_failed_response(res) unless res.messages.empty?
      return validation_failed_response(OpenStruct.new(messages: { size_reference_id: ['You did not choose a Size Reference or Actual Count'] })) if params[:fruit_size_reference_id].nil? && params[:fruit_actual_counts_for_pack_id].nil?

      attrs = res.to_h
      treatment_ids = attrs.delete(:treatment_ids)
      attrs = attrs.merge(treatment_ids: "{#{treatment_ids.join(',')}}") unless treatment_ids.nil?

      id = nil
      repo.transaction do
        id = repo.create_product_setup(attrs)
        log_status('product_setups', id, 'CREATED')
        log_transaction
      end
      instance = product_setup(id)
      success_response("Created product setup #{instance.product_setup_code}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { product_setup_code: ['This product setup already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_product_setup(id, params)  # rubocop:disable Metrics/AbcSize
      res = validate_product_setup_params(params)
      return validation_failed_response(res) unless res.messages.empty?
      return validation_failed_response(OpenStruct.new(messages: { size_reference_id: ['You did not choose a Size Reference or Actual Count'] })) if params[:fruit_size_reference_id].nil? && params[:fruit_actual_counts_for_pack_id].nil?

      attrs = res.to_h
      treatment_ids = attrs.delete(:treatment_ids)
      attrs = attrs.merge(treatment_ids: "{#{treatment_ids.join(',')}}") unless treatment_ids.nil?

      repo.transaction do
        repo.update_product_setup(id, attrs)
        log_transaction
      end
      instance = product_setup(id)
      success_response("Updated product setup #{instance.product_setup_code}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_product_setup(id)
      name = product_setup(id).product_setup_code
      repo.transaction do
        repo.delete_product_setup(id)
        log_status('product_setups', id, 'DELETED')
        log_transaction
      end
      success_response("Deleted product setup #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::ProductSetup.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def for_select_template_commodity_marketing_varieties(product_setup_template_id, commodity_id)
      repo.for_select_template_commodity_marketing_varieties(product_setup_template_id, commodity_id)
    end

    def for_select_template_commodity_size_counts(commodity_id)
      MasterfilesApp::FruitSizeRepo.new.for_select_std_fruit_size_counts(where: { commodity_id: commodity_id })
    end

    def for_select_basic_pack_actual_counts(basic_pack_code_id, std_fruit_size_count_id)
      MasterfilesApp::FruitSizeRepo.new.for_select_fruit_actual_counts_for_packs(where: { basic_pack_code_id: basic_pack_code_id,
                                                                                          std_fruit_size_count_id: std_fruit_size_count_id })
    end

    def for_select_actual_count_standard_pack_codes(standard_pack_code_ids)
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

    def for_select_treatment_type_treatments(treatment_type_id)
      MasterfilesApp::FruitRepo.new.for_select_treatments(where: { treatment_type_id: treatment_type_id })
    end

    def activate_product_setup(id)
      repo.transaction do
        repo.activate_product_setup(id)
        log_status('product_setups', id, 'ACTIVATED')
        log_transaction
      end
      instance = product_setup(id)
      success_response("Activated product setup #{instance.id}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def deactivate_product_setup(id)
      repo.transaction do
        repo.deactivate_product_setup(id)
        log_status('product_setups', id, 'DEACTIVATED')
        log_transaction
      end
      instance = product_setup(id)
      success_response("De-activated product setup  #{instance.id}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def clone_product_setup(id)
      repo.transaction do
        repo.clone_product_setup(id)
        log_status('product_setups', id, 'CLONED')
        log_transaction
      end
      instance = product_setup(id)
      success_response("Cloned product setup #{instance.id}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def repo
      @repo ||= ProductSetupRepo.new
    end

    def product_setup(id)
      repo.find_product_setup(id)
    end

    def validate_product_setup_params(params)
      ProductSetupSchema.call(params)
    end
  end
end
