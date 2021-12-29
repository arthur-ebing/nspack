# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestLaboratoryPermission < Minitest::Test
    include Crossbeams::Responses
    include QualityFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        lab_code: Faker::Lorem.unique.word,
        lab_name: 'ABC',
        description: 'ABC',
        active: true
      }
      MasterfilesApp::Laboratory.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::Laboratory.call(:create)
      assert res.success, 'Should always be able to create a laboratory'
    end

    def test_edit
      MasterfilesApp::QualityRepo.any_instance.stubs(:find_laboratory).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Laboratory.call(:edit, 1)
      assert res.success, 'Should be able to edit a laboratory'
    end

    def test_delete
      MasterfilesApp::QualityRepo.any_instance.stubs(:find_laboratory).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Laboratory.call(:delete, 1)
      assert res.success, 'Should be able to delete a laboratory'
    end
  end
end
