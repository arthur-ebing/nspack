# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module QualityApp
  class TestMrlResultPermission < Minitest::Test
    include Crossbeams::Responses
    include MrlResultFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        post_harvest_parent_mrl_result_id: 1,
        cultivar_id: 1,
        puc_id: 1,
        season_id: 1,
        rmt_delivery_id: 1,
        farm_id: 1,
        laboratory_id: 1,
        mrl_sample_type_id: 1,
        orchard_id: 1,
        production_run_id: 1,
        waybill_number: Faker::Lorem.unique.word,
        reference_number: 'ABC',
        sample_number: 'ABC',
        ph_level: 1,
        num_active_ingredients: 1,
        max_num_chemicals_passed: false,
        mrl_sample_passed: false,
        pre_harvest_result: false,
        post_harvest_result: false,
        fruit_received_at: '2010-01-01 12:00',
        sample_submitted_at: '2010-01-01 12:00',
        result_received_at: '2010-01-01 12:00',
        active: true
      }
      QualityApp::MrlResult.new(base_attrs.merge(attrs))
    end

    def test_create
      res = QualityApp::TaskPermissionCheck::MrlResult.call(:create)
      assert res.success, 'Should always be able to create a mrl_result'
    end

    def test_edit
      QualityApp::MrlResultRepo.any_instance.stubs(:find_mrl_result).returns(entity)
      res = QualityApp::TaskPermissionCheck::MrlResult.call(:edit, 1)
      assert res.success, 'Should be able to edit a mrl_result'
    end

    def test_delete
      QualityApp::MrlResultRepo.any_instance.stubs(:find_mrl_result).returns(entity)
      res = QualityApp::TaskPermissionCheck::MrlResult.call(:delete, 1)
      assert res.success, 'Should be able to delete a mrl_result'
    end
  end
end
