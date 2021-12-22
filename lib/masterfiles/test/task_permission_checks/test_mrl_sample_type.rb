# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestMrlSampleTypePermission < Minitest::Test
    include Crossbeams::Responses
    include QualityFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        sample_type_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
      MasterfilesApp::MrlSampleType.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::MrlSampleType.call(:create)
      assert res.success, 'Should always be able to create a mrl_sample_type'
    end

    def test_edit
      MasterfilesApp::QualityRepo.any_instance.stubs(:find_mrl_sample_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::MrlSampleType.call(:edit, 1)
      assert res.success, 'Should be able to edit a mrl_sample_type'
    end

    def test_delete
      MasterfilesApp::QualityRepo.any_instance.stubs(:find_mrl_sample_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::MrlSampleType.call(:delete, 1)
      assert res.success, 'Should be able to delete a mrl_sample_type'
    end
  end
end
