# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module ProductionApp
  class TestGrowerGradingCartonPermission < Minitest::Test
    include Crossbeams::Responses
    include GrowerGradingFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        grower_grading_pool_id: 1,
        grower_grading_rule_item_id: 1,
        product_resource_allocation_id: 1,
        pm_bom_id: 1,
        std_fruit_size_count_id: 1,
        fruit_actual_counts_for_pack_id: 1,
        marketing_org_party_role_id: 1,
        packed_tm_group_id: 1,
        target_market_id: 1,
        inventory_code_id: 1,
        rmt_class_id: 1,
        grade_id: 1,
        marketing_variety_id: 1,
        fruit_size_reference_id: 1,
        changes_made: {},
        carton_quantity: 1,
        inspected_quantity: 1,
        not_inspected_quantity: 1,
        failed_quantity: 1,
        gross_weight: 1.0,
        nett_weight: 1.0,
        completed: false,
        updated_by: Faker::Lorem.unique.word,
        active: true
      }
      ProductionApp::GrowerGradingCarton.new(base_attrs.merge(attrs))
    end

    def test_create
      res = ProductionApp::TaskPermissionCheck::GrowerGradingCarton.call(:create)
      assert res.success, 'Should always be able to create a grower_grading_carton'
    end

    def test_edit
      ProductionApp::GrowerGradingRepo.any_instance.stubs(:find_grower_grading_carton).returns(entity)
      res = ProductionApp::TaskPermissionCheck::GrowerGradingCarton.call(:edit, 1)
      assert res.success, 'Should be able to edit a grower_grading_carton'
    end

    def test_delete
      ProductionApp::GrowerGradingRepo.any_instance.stubs(:find_grower_grading_carton).returns(entity)
      res = ProductionApp::TaskPermissionCheck::GrowerGradingCarton.call(:delete, 1)
      assert res.success, 'Should be able to delete a grower_grading_carton'
    end
  end
end
