# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module QualityApp
  class TestOrchardTestResultPermission < Minitest::Test
    include Crossbeams::Responses
    include OrchardTestFactory
    include MasterfilesApp::TargetMarketFactory
    include MasterfilesApp::CultivarFactory
    include MasterfilesApp::CommodityFactory
    include MasterfilesApp::FarmsFactory
    include MasterfilesApp::PartyFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        orchard_test_type_id: 1,
        orchard_set_result_id: 1,
        puc_id: 1,
        orchard_id: 1,
        cultivar_id: 1,
        description: Faker::Lorem.unique.word,
        status_description: 'ABC',
        passed: false,
        classification_only: false,
        freeze_result: false,
        api_result: {},
        classifications: 'ABC',
        applicable_from: '2010-01-01 12:00',
        applicable_to: '2010-01-01 12:00',
        active: true
      }
      QualityApp::OrchardTestResult.new(base_attrs.merge(attrs))
    end

    def test_create
      res = QualityApp::TaskPermissionCheck::OrchardTestResult.call(:create)
      assert res.success, 'Should always be able to create a orchard_test_result'
    end

    def test_edit
      QualityApp::OrchardTestRepo.any_instance.stubs(:find_orchard_test_result).returns(entity)
      res = QualityApp::TaskPermissionCheck::OrchardTestResult.call(:edit, 1)
      assert res.success, 'Should be able to edit a orchard_test_result'
    end

    def test_delete
      QualityApp::OrchardTestRepo.any_instance.stubs(:find_orchard_test_result).returns(entity)
      res = QualityApp::TaskPermissionCheck::OrchardTestResult.call(:delete, 1)
      assert res.success, 'Should be able to delete a orchard_test_result'
    end
  end
end
