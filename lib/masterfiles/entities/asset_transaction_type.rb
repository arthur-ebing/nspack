# frozen_string_literal: true

module MasterfilesApp
  class AssetTransactionType < Dry::Struct
    attribute :id, Types::Integer
    attribute :transaction_type_code, Types::String
    attribute :description, Types::String
    attribute :status, Types::String
  end
end
