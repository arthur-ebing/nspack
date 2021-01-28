# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestBasicPackCodePermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        basic_pack_code: Faker::Lorem.unique.word,
        description: 'ABC',
        length_mm: 1,
        width_mm: 1,
        height_mm: 1,
        footprint_code: 'ABC'
      }
      MasterfilesApp::BasicPackCode.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::BasicPackCode.call(:create)
      assert res.success, 'Should always be able to create a basic_pack_code'
    end

    def test_edit
      MasterfilesApp::FruitSizeRepo.any_instance.stubs(:find_basic_pack_code).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::BasicPackCode.call(:edit, 1)
      assert res.success, 'Should be able to edit a basic_pack_code'
    end

    def test_delete
      MasterfilesApp::FruitSizeRepo.any_instance.stubs(:find_basic_pack_code).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::BasicPackCode.call(:delete, 1)
      assert res.success, 'Should be able to delete a basic_pack_code'
    end
  end
end
