# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module ProductionApp
  class TestGrowerGradingPoolPermission < Minitest::Test
    include Crossbeams::Responses
    include GrowerGradingFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        grower_grading_rule_id: 1,
        pool_name: Faker::Lorem.unique.word,
        description: 'ABC',
        production_run_id: 1,
        season_id: 1,
        cultivar_group_id: 1,
        cultivar_id: 1,
        commodity_id: 1,
        farm_id: 1,
        inspection_type_id: 1,
        bin_quantity: 1,
        gross_weight: 1.0,
        nett_weight: 1.0,
        pro_rata_factor: 1.0,
        legacy_data: {},
        completed: false,
        rule_applied: false,
        created_by: 'ABC',
        updated_by: 'ABC',
        rule_applied_by: 'ABC',
        rule_applied_at: '2010-01-01 12:00',
        active: true
      }
      ProductionApp::GrowerGradingPool.new(base_attrs.merge(attrs))
    end

    def test_create
      res = ProductionApp::TaskPermissionCheck::GrowerGradingPool.call(:create)
      assert res.success, 'Should always be able to create a grower_grading_pool'
    end

    def test_edit
      ProductionApp::GrowerGradingRepo.any_instance.stubs(:find_grower_grading_pool).returns(entity)
      res = ProductionApp::TaskPermissionCheck::GrowerGradingPool.call(:edit, 1)
      assert res.success, 'Should be able to edit a grower_grading_pool'
    end

    def test_delete
      ProductionApp::GrowerGradingRepo.any_instance.stubs(:find_grower_grading_pool).returns(entity)
      res = ProductionApp::TaskPermissionCheck::GrowerGradingPool.call(:delete, 1)
      assert res.success, 'Should be able to delete a grower_grading_pool'
    end
  end
end
