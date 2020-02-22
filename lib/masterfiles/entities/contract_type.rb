# frozen_string_literal: true

module MasterfilesApp
  class ContractType < Dry::Struct
    attribute :id, Types::Integer
    attribute :contract_type_code, Types::String
    attribute :description, Types::String
  end
end
