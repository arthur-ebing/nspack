# frozen_string_literal: true

module ProductionApp
  module PackingSpecificationFactory
    def create_packing_specification_item(opts = {})
      id = get_available_factory_record(:packing_specification_items, opts)
      return id unless id.nil?

      pm_bom_id = create_pm_bom
      pm_mark_id = create_pm_mark
      product_setup_id = create_product_setup
      pm_product_id = create_pm_product

      default = {
        description: Faker::Lorem.unique.word,
        pm_bom_id: pm_bom_id,
        pm_mark_id: pm_mark_id,
        product_setup_id: product_setup_id,
        tu_labour_product_id: pm_product_id,
        ru_labour_product_id: pm_product_id,
        ri_labour_product_id: pm_product_id,
        fruit_sticker_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        tu_sticker_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        ru_sticker_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:packing_specification_items].insert(default.merge(opts))
    end
  end
end
