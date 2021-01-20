# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module ProductionApp
  class TestPackingSpecificationItemPermission < Minitest::Test
    include Crossbeams::Responses

    def entity(attrs = {})
      base_attrs = {
        id: 1,
        packing_specification_id: 1,
        packing_specification: 'ABC',
        description: Faker::Lorem.unique.word,
        pm_bom_id: 1,
        pm_bom: 'ABC',
        pm_mark_id: 1,
        pm_mark: 'ABC',
        product_setup_id: 1,
        product_setup: 'ABC',
        tu_labour_product_id: 1,
        tu_labour_product: 'ABC',
        ru_labour_product_id: 1,
        ru_labour_product: 'ABC',
        ri_labour_product_id: 1,
        ri_labour_product: 'ABC',
        fruit_sticker_ids: [1, 2, 3],
        fruit_stickers: %w[A B C],
        fruit_sticker_1: 'ABC',
        fruit_sticker_2: 'ABC',
        tu_sticker_ids: [1, 2, 3],
        tu_stickers: %w[A B C],
        tu_sticker_1: 'ABC',
        tu_sticker_2: 'ABC',
        ru_sticker_ids: [1, 2, 3],
        ru_stickers: %w[A B C],
        ru_sticker_1: 'ABC',
        ru_sticker_2: 'ABC',
        active: true
      }
      ProductionApp::PackingSpecificationItem.new(base_attrs.merge(attrs))
    end

    def test_create
      res = ProductionApp::TaskPermissionCheck::PackingSpecificationItem.call(:create)
      assert res.success, 'Should always be able to create a packing_specification_item'
    end

    def test_edit
      ProductionApp::PackingSpecificationRepo.any_instance.stubs(:find_packing_specification_item).returns(entity)
      res = ProductionApp::TaskPermissionCheck::PackingSpecificationItem.call(:edit, 1)
      assert res.success, 'Should be able to edit a packing_specification_item'
    end

    def test_delete
      ProductionApp::PackingSpecificationRepo.any_instance.stubs(:find_packing_specification_item).returns(entity)
      res = ProductionApp::TaskPermissionCheck::PackingSpecificationItem.call(:delete, 1)
      assert res.success, 'Should be able to delete a packing_specification_item'
    end
  end
end
