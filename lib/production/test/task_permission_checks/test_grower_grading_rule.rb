# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module ProductionApp
  class TestGrowerGradingRulePermission < Minitest::Test
    include Crossbeams::Responses
    include GrowerGradingFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        rule_name: Faker::Lorem.unique.word,
        description: 'ABC',
        file_name: 'ABC',
        packhouse_resource_id: 1,
        line_resource_id: 1,
        season_id: 1,
        cultivar_group_id: 1,
        cultivar_id: 1,
        rebin_rule: false,
        created_by: 'ABC',
        updated_by: 'ABC',
        active: true
      }
      ProductionApp::GrowerGradingRule.new(base_attrs.merge(attrs))
    end

    def test_create
      res = ProductionApp::TaskPermissionCheck::GrowerGradingRule.call(:create)
      assert res.success, 'Should always be able to create a grower_grading_rule'
    end

    def test_edit
      ProductionApp::GrowerGradingRepo.any_instance.stubs(:find_grower_grading_rule).returns(entity)
      res = ProductionApp::TaskPermissionCheck::GrowerGradingRule.call(:edit, 1)
      assert res.success, 'Should be able to edit a grower_grading_rule'
    end

    def test_delete
      ProductionApp::GrowerGradingRepo.any_instance.stubs(:find_grower_grading_rule).returns(entity)
      res = ProductionApp::TaskPermissionCheck::GrowerGradingRule.call(:delete, 1)
      assert res.success, 'Should be able to delete a grower_grading_rule'
    end
  end
end
