# frozen_string_literal: true

module MasterfilesApp
  class RmtVariant < Dry::Struct
    attribute :id, Types::Integer
    attribute :cultivar_id, Types::Integer
    attribute :rmt_variant_code, Types::String
    attribute :description, Types::String
  end

  class RmtVariantFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :cultivar_id, Types::Integer
    attribute :rmt_variant_code, Types::String
    attribute :description, Types::String
    attribute :cultivar_name, Types::String
  end
end
