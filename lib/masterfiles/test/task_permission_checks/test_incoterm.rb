# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestIncotermPermission < Minitest::Test
    include Crossbeams::Responses
    include FinanceFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        incoterm: Faker::Lorem.unique.word,
        active: true
      }
      MasterfilesApp::Incoterm.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::Incoterm.call(:create)
      assert res.success, 'Should always be able to create a incoterm'
    end

    def test_edit
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_incoterm).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Incoterm.call(:edit, 1)
      assert res.success, 'Should be able to edit a incoterm'
    end

    def test_delete
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_incoterm).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Incoterm.call(:delete, 1)
      assert res.success, 'Should be able to delete a incoterm'
    end
  end
end
