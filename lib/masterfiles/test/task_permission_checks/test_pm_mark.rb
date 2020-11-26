# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPmMarkPermission < Minitest::Test
    include Crossbeams::Responses
    include PackagingFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        mark_id: 1,
        packaging_marks: %w[A B C],
        description: Faker::Lorem.unique.word,
        active: true
      }
      MasterfilesApp::PmMark.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::PmMark.call(:create)
      assert res.success, 'Should always be able to create a pm_mark'
    end

    def test_edit
      MasterfilesApp::BomsRepo.any_instance.stubs(:find_pm_mark).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::PmMark.call(:edit, 1)
      assert res.success, 'Should be able to edit a pm_mark'
    end

    def test_delete
      MasterfilesApp::BomsRepo.any_instance.stubs(:find_pm_mark).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::PmMark.call(:delete, 1)
      assert res.success, 'Should be able to delete a pm_mark'
    end
  end
end
