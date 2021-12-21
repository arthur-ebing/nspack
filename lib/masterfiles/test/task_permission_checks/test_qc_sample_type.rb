# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestQcSampleTypePermission < Minitest::Test
    include Crossbeams::Responses
    include QcFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        qc_sample_type_name: Faker::Lorem.unique.word,
        description: 'ABC',
        default_sample_size: 1,
        required_for_first_orchard_delivery: false,
        active: true
      }
      MasterfilesApp::QcSampleType.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::QcSampleType.call(:create)
      assert res.success, 'Should always be able to create a qc_sample_type'
    end

    def test_edit
      MasterfilesApp::QcRepo.any_instance.stubs(:find_qc_sample_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::QcSampleType.call(:edit, 1)
      assert res.success, 'Should be able to edit a qc_sample_type'
    end

    def test_delete
      MasterfilesApp::QcRepo.any_instance.stubs(:find_qc_sample_type).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::QcSampleType.call(:delete, 1)
      assert res.success, 'Should be able to delete a qc_sample_type'
    end
  end
end
