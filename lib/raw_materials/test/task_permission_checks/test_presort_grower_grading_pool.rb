# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module RawMaterialsApp
  class TestPresortGrowerGradingPoolPermission < Minitest::Test
    include Crossbeams::Responses
    include PresortGrowerGradingFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        maf_lot_number: Faker::Lorem.unique.word,
        description: 'ABC',
        rmt_code_ids: nil,
        season_id: 1,
        commodity_id: 1,
        farm_id: 1,
        rmt_bin_count: 1,
        rmt_bin_weight: 1.0,
        pro_rata_factor: 1.0,
        completed: false,
        created_by: 'ABC',
        updated_by: 'ABC',
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      RawMaterialsApp::PresortGrowerGradingPool.new(base_attrs.merge(attrs))
    end

    def test_create
      res = RawMaterialsApp::TaskPermissionCheck::PresortGrowerGradingPool.call(:create)
      assert res.success, 'Should always be able to create a presort_grower_grading_pool'
    end

    def test_edit
      RawMaterialsApp::PresortGrowerGradingRepo.any_instance.stubs(:find_presort_grower_grading_pool).returns(entity)
      res = RawMaterialsApp::TaskPermissionCheck::PresortGrowerGradingPool.call(:edit, 1)
      assert res.success, 'Should be able to edit a presort_grower_grading_pool'
    end

    def test_delete
      RawMaterialsApp::PresortGrowerGradingRepo.any_instance.stubs(:find_presort_grower_grading_pool).returns(entity)
      res = RawMaterialsApp::TaskPermissionCheck::PresortGrowerGradingPool.call(:delete, 1)
      assert res.success, 'Should be able to delete a presort_grower_grading_pool'
    end
  end
end
