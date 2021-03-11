# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestMasterfileTransformationPermission < Minitest::Test
    include Crossbeams::Responses
    include GeneralFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        masterfile_table: 'pucs',
        masterfile_column: 'puc_code',
        masterfile_code: 'ABC',
        transformation: 'ABC',
        external_system: 'ABC',
        external_code: 'ABC',
        masterfile_id: 1,
        created_at: '2012-03-01',
        updated_at: '2012-03-01'
      }
      MasterfilesApp::MasterfileTransformation.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::MasterfileTransformation.call(:create)
      assert res.success, 'Should always be able to create a masterfile_transformation'
    end

    def test_edit
      MasterfilesApp::GeneralRepo.any_instance.stubs(:find_masterfile_transformation).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::MasterfileTransformation.call(:edit, 1)
      assert res.success, 'Should be able to edit a masterfile_transformation'
    end

    def test_delete
      MasterfilesApp::GeneralRepo.any_instance.stubs(:find_masterfile_transformation).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::MasterfileTransformation.call(:delete, 1)
      assert res.success, 'Should be able to delete a masterfile_transformation'
    end
  end
end
