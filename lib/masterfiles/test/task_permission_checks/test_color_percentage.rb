# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestColorPercentagePermission < Minitest::Test
    include Crossbeams::Responses
    include CommodityFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        commodity_id: 1,
        color_percentage: 1,
        description: Faker::Lorem.unique.word,
        active: true
      }
      MasterfilesApp::ColorPercentage.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::ColorPercentage.call(:create)
      assert res.success, 'Should always be able to create a color_percentage'
    end

    def test_edit
      MasterfilesApp::CommodityRepo.any_instance.stubs(:find_color_percentage).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::ColorPercentage.call(:edit, 1)
      assert res.success, 'Should be able to edit a color_percentage'
    end

    def test_delete
      MasterfilesApp::CommodityRepo.any_instance.stubs(:find_color_percentage).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::ColorPercentage.call(:delete, 1)
      assert res.success, 'Should be able to delete a color_percentage'
    end
  end
end
