# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestChemicalPermission < Minitest::Test
    include Crossbeams::Responses
    include ChemicalFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        chemical_name: Faker::Lorem.unique.word,
        description: 'ABC',
        eu_max_level: 1.0,
        arfd_max_level: 1.0,
        orchard_chemical: false,
        drench_chemical: false,
        packline_chemical: false,
        active: true
      }
      MasterfilesApp::Chemical.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::Chemical.call(:create)
      assert res.success, 'Should always be able to create a chemical'
    end

    def test_edit
      MasterfilesApp::ChemicalRepo.any_instance.stubs(:find_chemical).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Chemical.call(:edit, 1)
      assert res.success, 'Should be able to edit a chemical'

      # MasterfilesApp::ChemicalRepo.any_instance.stubs(:find_chemical).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::Chemical.call(:edit, 1)
      # refute res.success, 'Should not be able to edit a completed chemical'
    end

    def test_delete
      MasterfilesApp::ChemicalRepo.any_instance.stubs(:find_chemical).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Chemical.call(:delete, 1)
      assert res.success, 'Should be able to delete a chemical'

      # MasterfilesApp::ChemicalRepo.any_instance.stubs(:find_chemical).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::Chemical.call(:delete, 1)
      # refute res.success, 'Should not be able to delete a completed chemical'
    end

    # def test_complete
    #   MasterfilesApp::ChemicalRepo.any_instance.stubs(:find_chemical).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::Chemical.call(:complete, 1)
    #   assert res.success, 'Should be able to complete a chemical'

    #   MasterfilesApp::ChemicalRepo.any_instance.stubs(:find_chemical).returns(entity(completed: true))
    #   res = MasterfilesApp::TaskPermissionCheck::Chemical.call(:complete, 1)
    #   refute res.success, 'Should not be able to complete an already completed chemical'
    # end

    # def test_approve
    #   MasterfilesApp::ChemicalRepo.any_instance.stubs(:find_chemical).returns(entity(completed: true, approved: false))
    #   res = MasterfilesApp::TaskPermissionCheck::Chemical.call(:approve, 1)
    #   assert res.success, 'Should be able to approve a completed chemical'

    #   MasterfilesApp::ChemicalRepo.any_instance.stubs(:find_chemical).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::Chemical.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve a non-completed chemical'

    #   MasterfilesApp::ChemicalRepo.any_instance.stubs(:find_chemical).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::Chemical.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve an already approved chemical'
    # end

    # def test_reopen
    #   MasterfilesApp::ChemicalRepo.any_instance.stubs(:find_chemical).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::Chemical.call(:reopen, 1)
    #   refute res.success, 'Should not be able to reopen a chemical that has not been approved'

    #   MasterfilesApp::ChemicalRepo.any_instance.stubs(:find_chemical).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::Chemical.call(:reopen, 1)
    #   assert res.success, 'Should be able to reopen an approved chemical'
    # end
  end
end
