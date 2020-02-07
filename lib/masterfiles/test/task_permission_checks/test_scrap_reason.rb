# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestScrapReasonPermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        scrap_reason: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true,
        applies_to_pallets: true,
        applies_to_bins: true
      }
      MasterfilesApp::ScrapReason.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::ScrapReason.call(:create)
      assert res.success, 'Should always be able to create a scrap_reason'
    end

    def test_edit
      MasterfilesApp::QualityRepo.any_instance.stubs(:find_scrap_reason).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::ScrapReason.call(:edit, 1)
      assert res.success, 'Should be able to edit a scrap_reason'
    end

    def test_delete
      MasterfilesApp::QualityRepo.any_instance.stubs(:find_scrap_reason).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::ScrapReason.call(:delete, 1)
      assert res.success, 'Should be able to delete a scrap_reason'
    end
  end
end
