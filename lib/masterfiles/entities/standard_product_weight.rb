# frozen_string_literal: true

module MasterfilesApp
  class StandardProductWeight < Dry::Struct
    attribute :id, Types::Integer
    attribute :commodity_id, Types::Integer
    attribute :standard_pack_id, Types::Integer
    attribute :gross_weight, Types::Decimal
    attribute :nett_weight, Types::Decimal
    attribute? :active, Types::Bool
    attribute :standard_carton_nett_weight, Types::Decimal
    attribute :ratio_to_standard_carton, Types::Decimal
    attribute :is_standard_carton, Types::Bool
  end

  class StandardProductWeightFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :commodity_id, Types::Integer
    attribute :commodity_code, Types::String
    attribute :standard_pack_id, Types::Integer
    attribute :standard_pack_code, Types::String
    attribute :gross_weight, Types::Decimal
    attribute :nett_weight, Types::Decimal
    attribute? :active, Types::Bool
    attribute :standard_carton_nett_weight, Types::Decimal
    attribute :ratio_to_standard_carton, Types::Decimal
    attribute :is_standard_carton, Types::Bool
  end
end
