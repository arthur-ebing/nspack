# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestFruitSizeReferencePermission < Minitest::Test
    include Crossbeams::Responses
    include FruitFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        size_reference: Faker::Lorem.unique.word,
        edi_out_code: 'ABC'
      }
      MasterfilesApp::FruitSizeReference.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::FruitSizeReference.call(:create)
      assert res.success, 'Should always be able to create a fruit_size_reference'
    end

    def test_edit
      MasterfilesApp::FruitSizeRepo.any_instance.stubs(:find_fruit_size_reference).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::FruitSizeReference.call(:edit, 1)
      assert res.success, 'Should be able to edit a fruit_size_reference'
    end

    def test_delete
      MasterfilesApp::FruitSizeRepo.any_instance.stubs(:find_fruit_size_reference).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::FruitSizeReference.call(:delete, 1)
      assert res.success, 'Should be able to delete a fruit_size_reference'
    end
  end
end
