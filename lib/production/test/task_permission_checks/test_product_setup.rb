# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module ProductionApp
  class TestProductSetupPermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        product_setup_template_id: 1,
        marketing_variety_id: 1,
        customer_variety_variety_id: 1,
        std_fruit_size_count_id: 1,
        basic_pack_code_id: 1,
        standard_pack_code_id: 1,
        fruit_actual_counts_for_pack_id: 1,
        fruit_size_reference_id: 1,
        marketing_org_party_role_id: 1,
        packed_tm_group_id: 1,
        mark_id: 1,
        inventory_code_id: 1,
        pallet_format_id: 1,
        cartons_per_pallet_id: 1,
        pm_bom_id: 1,
        extended_columns: {},
        client_size_reference: Faker::Lorem.unique.word,
        client_product_code: 'ABC',
        treatment_ids: [1, 2, 3],
        marketing_order_number: 'ABC',
        sell_by_code: 'ABC',
        pallet_label_name: 'ABC',
        active: true,
        product_setup_code: 'ABC',
        in_production: true,
        commodity_id: 1,
        grade_id: 1,
        product_chars: 1,
        pallet_base_id: 1,
        pallet_stack_type_id: 1,
        pm_type_id: 1,
        pm_subtype_id: 1,
        description: 'ABC',
        erp_bom_code: 'ABC'
      }
      ProductionApp::ProductSetup.new(base_attrs.merge(attrs))
    end

    def test_create
      res = ProductionApp::TaskPermissionCheck::ProductSetup.call(:create)
      assert res.success, 'Should always be able to create a product_setups'
    end

    def test_edit
      ProductionApp::ProductSetupRepo.any_instance.stubs(:find_product_setup).returns(entity)
      res = ProductionApp::TaskPermissionCheck::ProductSetup.call(:edit, 1)
      assert res.success, 'Should be able to edit a product_setups'
    end

    def test_delete
      ProductionApp::ProductSetupRepo.any_instance.stubs(:find_product_setup).returns(entity)
      res = ProductionApp::TaskPermissionCheck::ProductSetup.call(:delete, 1)
      assert res.success, 'Should be able to delete a product_setups'
    end
  end
end
