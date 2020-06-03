# frozen_string_literal: true

module RawMaterialsApp
  class BinLoadProduct < Dry::Struct
    attribute :id, Types::Integer
    attribute :bin_load_id, Types::Integer
    attribute :qty_bins, Types::Integer
    attribute :cultivar_id, Types::Integer
    attribute :cultivar_group_id, Types::Integer
    attribute :rmt_container_material_type_id, Types::Integer
    attribute :rmt_material_owner_party_role_id, Types::Integer
    attribute :farm_id, Types::Integer
    attribute :puc_id, Types::Integer
    attribute :orchard_id, Types::Integer
    attribute :rmt_class_id, Types::Integer
    attribute? :active, Types::Bool
  end

  class BinLoadProductFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :bin_load_id, Types::Integer
    attribute :qty_bins, Types::Integer
    attribute :cultivar_id, Types::Integer
    attribute :cultivar_group_id, Types::Integer
    attribute :rmt_container_material_type_id, Types::Integer
    attribute :rmt_material_owner_party_role_id, Types::Integer
    attribute :farm_id, Types::Integer
    attribute :puc_id, Types::Integer
    attribute :orchard_id, Types::Integer
    attribute :rmt_class_id, Types::Integer
    attribute :cultivar_group_code, Types::String
    attribute :cultivar_name, Types::String
    attribute :farm_code, Types::String
    attribute :puc_code, Types::String
    attribute :orchard_code, Types::String
    attribute :rmt_class_code, Types::String
    attribute :container_material_type_code, Types::String
    attribute :container_material_owner, Types::String
    attribute :product_code, Types::String
    attribute :completed, Types::Bool
    attribute :shipped, Types::Bool
    attribute? :status, Types::String
    attribute? :active, Types::Bool
  end
end
