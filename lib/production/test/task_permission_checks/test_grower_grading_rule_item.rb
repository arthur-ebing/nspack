# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module ProductionApp
  class TestGrowerGradingRuleItemPermission < Minitest::Test
    include Crossbeams::Responses
    include GrowerGradingFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        grower_grading_rule_id: 1,
        commodity_id: 1,
        grade_id: 1,
        std_fruit_size_count_id: 1,
        fruit_actual_counts_for_pack_id: 1,
        marketing_variety_id: 1,
        fruit_size_reference_id: 1,
        rmt_class_id: 1,
        rmt_size_id: 1,
        inspection_type_id: 1,
        legacy_data: {},
        changes: {},
        created_by: Faker::Lorem.unique.word,
        updated_by: 'ABC',
        active: true
      }
      ProductionApp::GrowerGradingRuleItem.new(base_attrs.merge(attrs))
    end

    def test_create
      res = ProductionApp::TaskPermissionCheck::GrowerGradingRuleItem.call(:create)
      assert res.success, 'Should always be able to create a grower_grading_rule_item'
    end

    def test_edit
      ProductionApp::GrowerGradingRepo.any_instance.stubs(:find_grower_grading_rule_item).returns(entity)
      res = ProductionApp::TaskPermissionCheck::GrowerGradingRuleItem.call(:edit, 1)
      assert res.success, 'Should be able to edit a grower_grading_rule_item'
    end

    def test_delete
      ProductionApp::GrowerGradingRepo.any_instance.stubs(:find_grower_grading_rule_item).returns(entity)
      res = ProductionApp::TaskPermissionCheck::GrowerGradingRuleItem.call(:delete, 1)
      assert res.success, 'Should be able to delete a grower_grading_rule_item'
    end
  end
end
