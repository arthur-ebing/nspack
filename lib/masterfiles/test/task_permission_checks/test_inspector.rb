# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestInspectorPermission < Minitest::Test
    include Crossbeams::Responses
    include InspectorFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        inspector_party_role_id: 1,
        tablet_ip_address: Faker::Lorem.unique.word,
        tablet_port_number: 1,
        active: true
      }
      MasterfilesApp::Inspector.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::Inspector.call(:create)
      assert res.success, 'Should always be able to create a inspector'
    end

    def test_edit
      MasterfilesApp::InspectorRepo.any_instance.stubs(:find_inspector).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Inspector.call(:edit, 1)
      assert res.success, 'Should be able to edit a inspector'

      # MasterfilesApp::InspectorRepo.any_instance.stubs(:find_inspector).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::Inspector.call(:edit, 1)
      # refute res.success, 'Should not be able to edit a completed inspector'
    end

    def test_delete
      MasterfilesApp::InspectorRepo.any_instance.stubs(:find_inspector).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Inspector.call(:delete, 1)
      assert res.success, 'Should be able to delete a inspector'

      # MasterfilesApp::InspectorRepo.any_instance.stubs(:find_inspector).returns(entity(completed: true))
      # res = MasterfilesApp::TaskPermissionCheck::Inspector.call(:delete, 1)
      # refute res.success, 'Should not be able to delete a completed inspector'
    end

    # def test_complete
    #   MasterfilesApp::InspectorRepo.any_instance.stubs(:find_inspector).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::Inspector.call(:complete, 1)
    #   assert res.success, 'Should be able to complete a inspector'

    #   MasterfilesApp::InspectorRepo.any_instance.stubs(:find_inspector).returns(entity(completed: true))
    #   res = MasterfilesApp::TaskPermissionCheck::Inspector.call(:complete, 1)
    #   refute res.success, 'Should not be able to complete an already completed inspector'
    # end

    # def test_approve
    #   MasterfilesApp::InspectorRepo.any_instance.stubs(:find_inspector).returns(entity(completed: true, approved: false))
    #   res = MasterfilesApp::TaskPermissionCheck::Inspector.call(:approve, 1)
    #   assert res.success, 'Should be able to approve a completed inspector'

    #   MasterfilesApp::InspectorRepo.any_instance.stubs(:find_inspector).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::Inspector.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve a non-completed inspector'

    #   MasterfilesApp::InspectorRepo.any_instance.stubs(:find_inspector).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::Inspector.call(:approve, 1)
    #   refute res.success, 'Should not be able to approve an already approved inspector'
    # end

    # def test_reopen
    #   MasterfilesApp::InspectorRepo.any_instance.stubs(:find_inspector).returns(entity)
    #   res = MasterfilesApp::TaskPermissionCheck::Inspector.call(:reopen, 1)
    #   refute res.success, 'Should not be able to reopen a inspector that has not been approved'

    #   MasterfilesApp::InspectorRepo.any_instance.stubs(:find_inspector).returns(entity(completed: true, approved: true))
    #   res = MasterfilesApp::TaskPermissionCheck::Inspector.call(:reopen, 1)
    #   assert res.success, 'Should be able to reopen an approved inspector'
    # end
  end
end
