# frozen_string_literal: true

module MasterfilesApp
  class Cultivar < Dry::Struct
    attribute :id, Types::Integer
    attribute :cultivar_group_id, Types::Integer
    attribute :cultivar_group_code, Types::String
    attribute :commodity_code, Types::String
    attribute :cultivar_name, Types::String
    attribute :cultivar_code, Types::String
    attribute :description, Types::String
    attribute :marketing_varieties, Types::Array
    attribute? :active, Types::Bool
    attribute :std_rmt_bin_nett_weight, Types::Decimal
  end
end
