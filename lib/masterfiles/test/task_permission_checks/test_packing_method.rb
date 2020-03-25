# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPackingMethodPermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        packing_method_code: Faker::Lorem.unique.word,
        description: 'ABC',
        actual_count_reduction_factor: 1.0,
        active: true
      }
      MasterfilesApp::PackingMethod.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::PackingMethod.call(:create)
      assert res.success, 'Should always be able to create a packing_method'
    end

    def test_edit
      MasterfilesApp::PackagingRepo.any_instance.stubs(:find_packing_method).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::PackingMethod.call(:edit, 1)
      assert res.success, 'Should be able to edit a packing_method'
    end

    def test_delete
      MasterfilesApp::PackagingRepo.any_instance.stubs(:find_packing_method).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::PackingMethod.call(:delete, 1)
      assert res.success, 'Should be able to delete a packing_method'
    end
  end
end
