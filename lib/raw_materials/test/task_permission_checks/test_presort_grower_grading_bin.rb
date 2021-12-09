# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module RawMaterialsApp
  class TestPresortGrowerGradingBinPermission < Minitest::Test
    include Crossbeams::Responses
    include PresortGrowerGradingFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        presort_grower_grading_pool_id: 1,
        farm_id: 1,
        rmt_class_id: 1,
        rmt_size_id: 1,
        maf_rmt_code: Faker::Lorem.unique.word,
        maf_article: 'ABC',
        maf_class: 'ABC',
        maf_colour: 'ABC',
        maf_count: 'ABC',
        maf_article_count: 'ABC',
        maf_weight: 1.0,
        maf_tipped_quantity: 1,
        maf_total_lot_weight: 1.0,
        created_by: 'ABC',
        updated_by: 'ABC',
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      RawMaterialsApp::PresortGrowerGradingBin.new(base_attrs.merge(attrs))
    end

    def test_create
      res = RawMaterialsApp::TaskPermissionCheck::PresortGrowerGradingBin.call(:create)
      assert res.success, 'Should always be able to create a presort_grower_grading_bin'
    end

    def test_edit
      RawMaterialsApp::PresortGrowerGradingRepo.any_instance.stubs(:find_presort_grower_grading_bin).returns(entity)
      res = RawMaterialsApp::TaskPermissionCheck::PresortGrowerGradingBin.call(:edit, 1)
      assert res.success, 'Should be able to edit a presort_grower_grading_bin'
    end

    def test_delete
      RawMaterialsApp::PresortGrowerGradingRepo.any_instance.stubs(:find_presort_grower_grading_bin).returns(entity)
      res = RawMaterialsApp::TaskPermissionCheck::PresortGrowerGradingBin.call(:delete, 1)
      assert res.success, 'Should be able to delete a presort_grower_grading_bin'
    end
  end
end
