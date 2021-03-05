# frozen_string_literal: true

module ProductionApp
  class PackingSpecificationItem < Dry::Struct
    attribute :id, Types::Integer
    attribute :packing_specification_id, Types::Integer
    attribute :packing_specification, Types::String
    attribute :description, Types::String
    attribute :pm_bom_id, Types::Integer
    attribute :pm_bom, Types::String
    attribute :pm_mark_id, Types::Integer
    attribute :mark_id, Types::Integer
    attribute :std_fruit_size_count_id, Types::Integer
    attribute :basic_pack_id, Types::Integer
    attribute :pm_mark, Types::String
    attribute :product_setup_id, Types::Integer
    attribute :product_setup_template_id, Types::Integer
    attribute :product_setup, Types::String
    attribute :tu_labour_product_id, Types::Integer
    attribute :tu_labour_product, Types::String
    attribute :ru_labour_product_id, Types::Integer
    attribute :ru_labour_product, Types::String
    attribute :ri_labour_product_id, Types::Integer
    attribute :ri_labour_product, Types::String
    attribute :fruit_sticker_ids, Types::Array
    attribute :fruit_stickers, Types::Array
    attribute :fruit_sticker_1, Types::String
    attribute :fruit_sticker_2, Types::String
    attribute :tu_sticker_ids, Types::Array
    attribute :tu_stickers, Types::Array
    attribute :tu_sticker_1, Types::String
    attribute :tu_sticker_2, Types::String
    attribute :ru_sticker_ids, Types::Array
    attribute :ru_stickers, Types::Array
    attribute :ru_sticker_1, Types::String
    attribute :ru_sticker_2, Types::String
    attribute? :status, Types::Bool
    attribute? :active, Types::Bool
    attribute :packing_specification_item_code, Types::String
  end
end
