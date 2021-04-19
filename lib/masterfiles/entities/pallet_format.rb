# frozen_string_literal: true

module MasterfilesApp
  class PalletFormat < Dry::Struct
    attribute :id, Types::Integer
    attribute :description, Types::String
    attribute :pallet_base_id, Types::Integer
    attribute :pallet_stack_type_id, Types::Integer
    attribute :pallet_base_code, Types::String
    attribute :stack_type_code, Types::String
    attribute? :active, Types::Bool
    attribute? :bin, Types::Bool
  end
end
