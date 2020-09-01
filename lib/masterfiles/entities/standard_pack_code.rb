# frozen_string_literal: true

module MasterfilesApp
  class StandardPackCode < Dry::Struct
    attribute :id, Types::Integer
    attribute :standard_pack_code, Types::String
    attribute :material_mass, Types::Decimal
    attribute :plant_resource_button_indicator, Types::String
    attribute :description, Types::String
    attribute :std_pack_label_code, Types::String
    attribute :basic_pack_code_id, Types::Integer
    attribute :use_size_ref_for_edi, Types::Bool
    attribute :bin, Types::Bool
    attribute :rmt_container_type_id, Types::Integer
    attribute :rmt_container_material_type_id, Types::Integer
    attribute :palletizer_incentive_rate, Types::Decimal
    attribute? :active, Types::Bool
  end

  class StandardPackCodeFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :standard_pack_code, Types::String
    attribute :material_mass, Types::Decimal
    attribute :plant_resource_button_indicator, Types::String
    attribute :description, Types::String
    attribute :std_pack_label_code, Types::String
    attribute :basic_pack_code_id, Types::Integer
    attribute :basic_pack_code, Types::String
    attribute :use_size_ref_for_edi, Types::Bool
    attribute :palletizer_incentive_rate, Types::Decimal
    attribute :bin, Types::Bool
    attribute :rmt_container_type_id, Types::Integer
    attribute :container_type, Types::String
    attribute :rmt_container_material_type_id, Types::Integer
    attribute :material_type, Types::String
    attribute? :active, Types::Bool
  end
end
