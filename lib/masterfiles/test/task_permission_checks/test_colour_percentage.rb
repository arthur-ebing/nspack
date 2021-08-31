# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestColourPercentagePermission < Minitest::Test
    include Crossbeams::Responses
    include CommodityFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        commodity_id: 1,
        colour_percentage: 1,
        description: Faker::Lorem.unique.word,
        active: true
      }
      MasterfilesApp::ColourPercentage.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::ColourPercentage.call(:create)
      assert res.success, 'Should always be able to create a colour_percentage'
    end

    def test_edit
      MasterfilesApp::CommodityRepo.any_instance.stubs(:find_colour_percentage).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::ColourPercentage.call(:edit, 1)
      assert res.success, 'Should be able to edit a colour_percentage'
    end

    def test_delete
      MasterfilesApp::CommodityRepo.any_instance.stubs(:find_colour_percentage).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::ColourPercentage.call(:delete, 1)
      assert res.success, 'Should be able to delete a colour_percentage'
    end
  end
end
