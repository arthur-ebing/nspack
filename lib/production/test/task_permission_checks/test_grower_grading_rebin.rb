# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module ProductionApp
  class TestGrowerGradingRebinPermission < Minitest::Test
    include Crossbeams::Responses
    include GrowerGradingFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        grower_grading_pool_id: 1,
        grower_grading_rule_item_id: 1,
        rmt_class_id: 1,
        rmt_size_id: 1,
        changes_made: {},
        rebins_quantity: 1,
        gross_weight: 1.0,
        nett_weight: 1.0,
        pallet_rebin: false,
        completed: false,
        updated_by: Faker::Lorem.unique.word,
        active: true
      }
      ProductionApp::GrowerGradingRebin.new(base_attrs.merge(attrs))
    end

    def test_create
      res = ProductionApp::TaskPermissionCheck::GrowerGradingRebin.call(:create)
      assert res.success, 'Should always be able to create a grower_grading_rebin'
    end

    def test_edit
      ProductionApp::GrowerGradingRepo.any_instance.stubs(:find_grower_grading_rebin).returns(entity)
      res = ProductionApp::TaskPermissionCheck::GrowerGradingRebin.call(:edit, 1)
      assert res.success, 'Should be able to edit a grower_grading_rebin'
    end

    def test_delete
      ProductionApp::GrowerGradingRepo.any_instance.stubs(:find_grower_grading_rebin).returns(entity)
      res = ProductionApp::TaskPermissionCheck::GrowerGradingRebin.call(:delete, 1)
      assert res.success, 'Should be able to delete a grower_grading_rebin'
    end
  end
end
