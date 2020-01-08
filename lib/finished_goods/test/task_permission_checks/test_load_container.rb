# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestLoadContainerPermission < Minitest::Test
    include Crossbeams::Responses
    include LoadContainerFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        load_id: 1,
        container_code: Faker::Lorem.unique.word,
        container_vents: 'ABC',
        container_seal_code: 'ABC',
        container_temperature_rhine: 1.0,
        container_temperature_rhine2: 1.0,
        internal_container_code: 'ABC',
        max_gross_weight: 1.0,
        tare_weight: 1.0,
        max_payload: 1.0,
        actual_payload: 1.0,
        verified_gross_weight: 1.0,
        verified_gross_weight_date: '2010-01-01 12:00',
        cargo_temperature_id: 1,
        stack_type_id: 1,
        active: true
      }
      FinishedGoodsApp::LoadContainer.new(base_attrs.merge(attrs))
    end

    def test_create
      res = FinishedGoodsApp::TaskPermissionCheck::LoadContainer.call(:create)
      assert res.success, 'Should always be able to create a load_container'
    end

    def test_edit
      FinishedGoodsApp::LoadContainerRepo.any_instance.stubs(:find_load_container).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::LoadContainer.call(:edit, 1)
      assert res.success, 'Should be able to edit a load_container'
    end

    def test_delete
      FinishedGoodsApp::LoadContainerRepo.any_instance.stubs(:find_load_container).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::LoadContainer.call(:delete, 1)
      assert res.success, 'Should be able to delete a load_container'
    end
  end
end
