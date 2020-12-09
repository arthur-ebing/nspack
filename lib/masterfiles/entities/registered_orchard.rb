# frozen_string_literal: true

module MasterfilesApp
  class RegisteredOrchard < Dry::Struct
    attribute :id, Types::Integer
    attribute :orchard_code, Types::String
    attribute :cultivar_code, Types::String
    attribute :puc_code, Types::String
    attribute :description, Types::String
    attribute :marketing_orchard, Types::Bool
    attribute? :active, Types::Bool
  end
end
