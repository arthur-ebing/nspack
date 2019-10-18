# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestVoyagePermission < Minitest::Test
    include Crossbeams::Responses
    include VoyageFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        vessel_id: 1,
        voyage_type_id: 1,
        voyage_number: Faker::Lorem.unique.word,
        voyage_code: 'ABC',
        year: 1,
        completed: false,
        completed_at: '2010-01-01 12:00',
        active: true
      }
      FinishedGoodsApp::Voyage.new(base_attrs.merge(attrs))
    end

    def test_create
      res = FinishedGoodsApp::TaskPermissionCheck::Voyage.call(:create)
      assert res.success, 'Should always be able to create a voyage'
    end

    def test_edit
      FinishedGoodsApp::VoyageRepo.any_instance.stubs(:find_voyage).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::Voyage.call(:edit, 1)
      assert res.success, 'Should be able to edit a voyage'
    end

    def test_delete
      FinishedGoodsApp::VoyageRepo.any_instance.stubs(:find_voyage).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::Voyage.call(:delete, 1)
      assert res.success, 'Should be able to delete a voyage'
    end

    def test_complete
      FinishedGoodsApp::VoyageRepo.any_instance.stubs(:find_voyage).returns(entity)
      res = FinishedGoodsApp::TaskPermissionCheck::Voyage.call(:complete, 1)
      assert res.success, 'Should be able to complete a voyage'

      FinishedGoodsApp::VoyageRepo.any_instance.stubs(:find_voyage).returns(entity(completed: true))
      res = FinishedGoodsApp::TaskPermissionCheck::Voyage.call(:complete, 1)
      refute res.success, 'Should not be able to complete an already completed voyage'
    end
  end
end
