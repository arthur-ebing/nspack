# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestFruitIndustryLevyPermission < Minitest::Test
    include Crossbeams::Responses
    include PartyFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        levy_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
      MasterfilesApp::FruitIndustryLevy.new(base_attrs.merge(attrs))
    end

    def test_create
      res = MasterfilesApp::TaskPermissionCheck::FruitIndustryLevy.call(:create)
      assert res.success, 'Should always be able to create a fruit_industry_levy'
    end

    def test_edit
      MasterfilesApp::PartyRepo.any_instance.stubs(:find_fruit_industry_levy).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::FruitIndustryLevy.call(:edit, 1)
      assert res.success, 'Should be able to edit a fruit_industry_levy'
    end

    def test_delete
      MasterfilesApp::PartyRepo.any_instance.stubs(:find_fruit_industry_levy).returns(entity)
      res = MasterfilesApp::TaskPermissionCheck::FruitIndustryLevy.call(:delete, 1)
      assert res.success, 'Should be able to delete a fruit_industry_levy'
    end
  end
end
