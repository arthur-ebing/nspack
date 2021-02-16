# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestRegistrationPermission < Minitest::Test
    include Crossbeams::Responses
    include PartyFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        party_role_id: 1,
        party_id: 1,
        registration_type: Faker::Lorem.unique.word,
        registration_code: 'ABC',
        role_name: 'ABC',
        party_name: 'ABC'
      }
      MasterfilesApp::Registration.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::Registration.call(:create)
      assert res.success, 'Should always be able to create a registration'
    end

    def test_edit
      MasterfilesApp::PartyRepo.any_instance.stubs(:find_registration).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Registration.call(:edit, 1)
      assert res.success, 'Should be able to edit a registration'
    end

    def test_delete
      MasterfilesApp::PartyRepo.any_instance.stubs(:find_registration).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Registration.call(:delete, 1)
      assert res.success, 'Should be able to delete a registration'
    end
  end
end
