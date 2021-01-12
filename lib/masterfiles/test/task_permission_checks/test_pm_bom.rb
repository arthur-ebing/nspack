# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPmBomPermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        bom_code: Faker::Lorem.unique.word,
        erp_bom_code: 'ABC',
        description: 'ABC',
        active: true,
        system_code: 'ABC',
        gross_weight: 1.0,
        nett_weight: 1.0
      }
      MasterfilesApp::PmBom.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::PmBom.call(:create)
      assert res.success, 'Should always be able to create a pm_bom'
    end

    def test_edit
      MasterfilesApp::BomRepo.any_instance.stubs(:find_pm_bom).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::PmBom.call(:edit, 1)
      assert res.success, 'Should be able to edit a pm_bom'
    end

    def test_delete
      MasterfilesApp::BomRepo.any_instance.stubs(:find_pm_bom).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::PmBom.call(:delete, 1)
      assert res.success, 'Should be able to delete a pm_bom'
    end
  end
end
