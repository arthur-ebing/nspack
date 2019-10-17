# frozen_string_literal: true

module MasterfilesApp
  class PalletBase < Dry::Struct
    attribute :id, Types::Integer
    attribute :pallet_base_code, Types::String
    attribute :description, Types::String
    attribute :length, Types::Integer
    attribute :width, Types::Integer
    attribute :edi_in_pallet_base, Types::String
    attribute :edi_out_pallet_base, Types::String
    attribute :cartons_per_layer, Types::Integer
    attribute :material_mass, Types::Decimal
    attribute? :active, Types::Bool
  end
end
