# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module ProductionApp
  class TestProductSetupTemplatePermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        template_name: Faker::Lorem.unique.word,
        description: 'ABC',
        cultivar_group_id: 1,
        cultivar_id: 1,
        packhouse_resource_id: 1,
        production_line_id: 1,
        season_group_id: 1,
        season_id: 1,
        active: true,
        cultivar_group_code: 'ABC',
        cultivar_name: 'ABC',
        packhouse_resource_code: 'ABC',
        production_line_code: 'ABC',
        season_group_code: 'ABC',
        season_code: 'ABC'
      }
      ProductionApp::ProductSetupTemplate.new(base_attrs.merge(attrs))
    end

    def test_create
      res = ProductionApp::TaskPermissionCheck::ProductSetupTemplate.call(:create)
      assert res.success, 'Should always be able to create a product_setup_template'
    end

    def test_edit
      ProductionApp::ProductSetupRepo.any_instance.stubs(:find_product_setup_template).returns(entity)
      res = ProductionApp::TaskPermissionCheck::ProductSetupTemplate.call(:edit, 1)
      assert res.success, 'Should be able to edit a product_setup_template'
    end

    def test_delete
      ProductionApp::ProductSetupRepo.any_instance.stubs(:find_product_setup_template).returns(entity)
      res = ProductionApp::TaskPermissionCheck::ProductSetupTemplate.call(:delete, 1)
      assert res.success, 'Should be able to delete a product_setup_template'
    end
  end
end
