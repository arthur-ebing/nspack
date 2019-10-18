# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestLoadVoyagePermission < Minitest::Test
    include Crossbeams::Responses
    include LoadVoyageFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        load_id: 1,
        voyage_id: 1,
        shipping_line_party_role_id: 1,
        shipper_party_role_id: 1,
        booking_reference: Faker::Lorem.unique.word,
        memo_pad: 'ABC',
        active: true
      }
      FinishedGoodsApp::LoadVoyage.new(base_attrs.merge(attrs))
    end

    def test_create
      res = FinishedGoodsApp::TaskPermissionCheck::LoadVoyage.call(:create)
      assert res.success, 'Should always be able to create a load_voyage'
    end

    def test_edit
      FinishedGoodsApp::LoadVoyageRepo.any_instance.stubs(:find_load_voyage).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::LoadVoyage.call(:edit, 1)
      assert res.success, 'Should be able to edit a load_voyage'
    end

    def test_delete
      FinishedGoodsApp::LoadVoyageRepo.any_instance.stubs(:find_load_voyage).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::LoadVoyage.call(:delete, 1)
      assert res.success, 'Should be able to delete a load_voyage'
    end
  end
end
