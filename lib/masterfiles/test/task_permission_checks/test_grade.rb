# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestGradePermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        grade_code: Faker::Lorem.unique.word,
        description: 'ABC',
        rmt_grade: false,
        active: true
      }
      MasterfilesApp::Grade.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::Grade.call(:create)
      assert res.success, 'Should always be able to create a grade'
    end

    def test_edit
      MasterfilesApp::FruitRepo.any_instance.stubs(:find_grade).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Grade.call(:edit, 1)
      assert res.success, 'Should be able to edit a grade'
    end

    def test_delete
      MasterfilesApp::FruitRepo.any_instance.stubs(:find_grade).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::Grade.call(:delete, 1)
      assert res.success, 'Should be able to delete a grade'
    end
  end
end
