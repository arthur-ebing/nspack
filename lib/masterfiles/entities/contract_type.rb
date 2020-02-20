# frozen_string_literal: true

module MasterfilesApp
  class ContractType < Dry::Struct
    attribute :id, Types::Integer
    attribute :code, Types::String
    attribute :description, Types::String
  end
end
