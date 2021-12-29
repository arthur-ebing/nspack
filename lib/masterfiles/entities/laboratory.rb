# frozen_string_literal: true

module MasterfilesApp
  class Laboratory < Dry::Struct
    attribute :id, Types::Integer
    attribute :lab_code, Types::String
    attribute :lab_name, Types::String
    attribute :description, Types::String
    attribute? :active, Types::Bool
  end
end
