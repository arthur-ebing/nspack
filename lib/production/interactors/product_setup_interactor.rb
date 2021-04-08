# frozen_string_literal: true

module ProductionApp
  class ProductSetupInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_product_setup(params)  # rubocop:disable Metrics/AbcSize
      res = validate_product_setup_params(params)
      return validation_failed_response(res) if res.failure?

      id = repo.look_for_existing_product_setup_id(res)
      if id
        instance = product_setup(id)
        return success_response("Found existing product setup #{instance.product_setup_code}", instance)
      end

      repo.transaction do
        id = repo.create_product_setup(res)
        log_status(:product_setups, id, 'CREATED')
        log_transaction
      end
      instance = product_setup(id)
      success_response("Created product setup #{instance.product_setup_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { product_setup_code: ['This product setup already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_product_setup(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_product_setup_params(params)
      return validation_failed_response(res) if res.failure?

      existing_id = repo.look_for_existing_product_setup_id(res)
      if existing_id
        instance = product_setup(existing_id)
        return success_response("Found existing product setup #{instance.product_setup_code}", instance)
      end

      repo.transaction do
        repo.update_product_setup(id, res)
        log_status(:product_setups, id, 'UPDATED') if repo.product_setup_in_production?(id)
        log_transaction
      end
      instance = product_setup(id)
      success_response("Updated product setup #{instance.product_setup_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_product_setup(id)
      name = product_setup(id).product_setup_code
      return failed_response("You cannot delete product setup #{name}. It is on an active production run") if repo.product_setup_in_production?(id)

      repo.transaction do
        repo.delete_product_setup(id)
        log_status(:product_setups, id, 'DELETED')
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

    def for_select_template_commodity_marketing_varieties(product_setup_template_id, commodity_id, cultivar_id)
      repo.for_select_template_commodity_marketing_varieties(product_setup_template_id, commodity_id, cultivar_id)
    end

    def for_select_template_commodity_size_counts(commodity_id)
      MasterfilesApp::FruitSizeRepo.new.for_select_std_fruit_size_counts(
        where: { commodity_id: commodity_id }
      )
    end

    def for_select_basic_pack_actual_counts(basic_pack_code_id, std_fruit_size_count_id)
      MasterfilesApp::FruitSizeRepo.new.for_select_fruit_actual_counts_for_packs(
        where: { basic_pack_code_id: basic_pack_code_id, std_fruit_size_count_id: std_fruit_size_count_id }
      )
    end

    def for_select_actual_count_standard_pack_codes(standard_pack_code_ids)
      MasterfilesApp::FruitSizeRepo.new.for_select_standard_packs(where: { id: standard_pack_code_ids })
    end

    def for_select_actual_count_size_references(size_reference_ids)
      MasterfilesApp::FruitSizeRepo.new.for_select_fruit_size_references(
        where: { id: size_reference_ids }
      ) || MasterfilesApp::FruitSizeRepo.new.for_select_fruit_size_references
    end

    def for_select_customer_varieties(packed_tm_group_id, marketing_variety_id)
      MasterfilesApp::MarketingRepo.new.for_select_customer_varieties(
        where: { packed_tm_group_id: packed_tm_group_id, marketing_variety_id: marketing_variety_id }
      )
    end

    def for_select_target_customer_party_roles(target_market_id)
      target_market_target_customer_ids = MasterfilesApp::TargetMarketRepo.new.target_market_target_customer_ids(target_market_id)
      MasterfilesApp::PartyRepo.new.for_select_party_roles(AppConst::ROLE_TARGET_CUSTOMER,
                                                           where: { id: target_market_target_customer_ids })
    end

    def for_select_pallet_formats(pallet_base_id, pallet_stack_type_id)
      MasterfilesApp::PackagingRepo.new.for_select_pallet_formats(
        where: { pallet_base_id: pallet_base_id, pallet_stack_type_id: pallet_stack_type_id }
      )
    end

    def for_select_cartons_per_pallets(pallet_format_id, basic_pack_code_id)
      MasterfilesApp::PackagingRepo.new.for_select_cartons_per_pallet(
        where: { pallet_format_id: pallet_format_id, basic_pack_id: basic_pack_code_id }
      )
    end

    def pm_bom_products_table(pm_bom_id, pm_mark_id = nil)
      pm_bom_products = MasterfilesApp::BomRepo.new.pm_bom_products(pm_bom_id)
      add_pm_bom_products_packaging_marks(pm_bom_products, pm_mark_id) unless pm_mark_id.nil_or_empty?

      Crossbeams::Layout::Table.new([], pm_bom_products, [],
                                    alignment: { quantity: :right, composition_level: :right },
                                    cell_transformers: { quantity: :decimal }).render
    end

    def add_pm_bom_products_packaging_marks(pm_bom_products, pm_mark_id) # rubocop:disable Metrics/AbcSize
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

    def activate_product_setup(id)
      repo.transaction do
        repo.activate_product_setup(id)
        log_status(:product_setups, id, 'ACTIVATED')
        log_transaction
      end
      instance = product_setup(id)
      success_response("Activated product setup #{instance.id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def deactivate_product_setup(id)
      repo.transaction do
        repo.deactivate_product_setup(id)
        log_status(:product_setups, id, 'DEACTIVATED')
        log_transaction
      end
      instance = product_setup(id)
      success_response("De-activated product setup  #{instance.id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def clone_product_setup(id)
      repo.transaction do
        repo.clone_product_setup(id)
        log_status(:product_setups, id, 'CLONED')
        log_transaction
      end
      instance = product_setup(id)
      success_response("Cloned product setup #{instance.id}", instance)
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

    def gtin_code(params)
      repo.find_gtin_code_for_update(params)
    end

    def validate_product_setup_params(params)
      res = ProductSetupContract.new.call(params)
      return res if res.failure?

      if AppConst::CR_MF.basic_pack_equals_standard_pack?
        standard_pack_id = repo.get_value(:basic_packs_standard_packs, :standard_pack_id, basic_pack_id: params[:basic_pack_code_id])
        params[:standard_pack_code_id] = standard_pack_id
      end
      params[:gtin_code] = gtin_code(params) if AppConst::CR_PROD.use_gtins?
      ProductSetupContract.new.call(params)
    end
  end
end
