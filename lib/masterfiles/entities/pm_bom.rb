# frozen_string_literal: true

module MasterfilesApp
  class PmBom < Dry::Struct
    attribute :id, Types::Integer
    attribute :bom_code, Types::String
    attribute :erp_bom_code, Types::String
    attribute :description, Types::String
    attribute? :active, Types::Bool
    attribute :system_code, Types::String
  end
end
