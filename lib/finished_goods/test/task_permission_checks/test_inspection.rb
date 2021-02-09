# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestInspectionPermission < Minitest::Test
    include Crossbeams::Responses
    include InspectionFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        inspection_type_id: 1,
        inspection_type_code: 'ABC',
        pallet_id: 1,
        pallet_number: '123',
        carton_id: 1,
        inspector_id: 1,
        inspector: 'ABC',
        inspected: true,
        inspection_failure_reason_ids: [1, 2, 3],
        failure_reasons: %w[A B C],
        passed: false,
        remarks: Faker::Lorem.unique.word,
        active: true
      }
      FinishedGoodsApp::Inspection.new(base_attrs.merge(attrs))
    end

    def test_create
      res = FinishedGoodsApp::TaskPermissionCheck::Inspection.call(:create)
      assert res.success, 'Should always be able to create a inspection'
    end

    def test_edit
      FinishedGoodsApp::InspectionRepo.any_instance.stubs(:find_inspection).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::Inspection.call(:edit, 1)
      assert res.success, 'Should be able to edit a inspection'
    end

    def test_delete
      FinishedGoodsApp::InspectionRepo.any_instance.stubs(:find_inspection).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::Inspection.call(:delete, 1)
      assert res.success, 'Should be able to delete a inspection'
    end
  end
end
