# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPucPermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        puc_code: 'ABC',
        gap_code: 'ABC',
        active: true,
        gap_code_valid_from: '2010-01-01 12:00',
        gap_code_valid_until: '2010-01-01 12:00'
      }
      MasterfilesApp::Puc.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::Puc.call(:create)
      assert res.success, 'Should always be able to create a puc'
    end

    def test_edit
      MasterfilesApp::FarmRepo.any_instance.stubs(:find_puc).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Puc.call(:edit, 1)
      assert res.success, 'Should be able to edit a puc'
    end

    def test_delete
      MasterfilesApp::FarmRepo.any_instance.stubs(:find_puc).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Puc.call(:delete, 1)
      assert res.success, 'Should be able to delete a puc'
    end
  end
end
