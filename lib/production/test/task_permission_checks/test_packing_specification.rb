# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module ProductionApp
  class TestPackingSpecificationPermission < Minitest::Test
    include Crossbeams::Responses
    # include PackingSpecificationFactory

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        product_setup_template_id: 1,
        product_setup_template: 'ABC',
        packing_specification_code: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true
      }
      ProductionApp::PackingSpecification.new(base_attrs.merge(attrs))
    end

    def test_create
      res = ProductionApp::TaskPermissionCheck::PackingSpecification.call(:create)
      assert res.success, 'Should always be able to create a packing_specification'
    end

    def test_edit
      ProductionApp::PackingSpecificationRepo.any_instance.stubs(:find_packing_specification).returns(entity)
      res = ProductionApp::TaskPermissionCheck::PackingSpecification.call(:edit, 1)
      assert res.success, 'Should be able to edit a packing_specification'
    end

    def test_delete
      ProductionApp::PackingSpecificationRepo.any_instance.stubs(:find_packing_specification).returns(entity)
      res = ProductionApp::TaskPermissionCheck::PackingSpecification.call(:delete, 1)
      assert res.success, 'Should be able to delete a packing_specification'
    end
  end
end
