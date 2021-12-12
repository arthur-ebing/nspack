# frozen_string_literal: true

module MasterfilesApp
  class FruitDefect < Dry::Struct
    attribute :id, Types::Integer
    attribute :rmt_class_id, Types::Integer
    attribute :fruit_defect_type_id, Types::Integer
    attribute :fruit_defect_code, Types::String
    attribute :short_description, Types::String
    attribute :description, Types::String
    attribute :internal, Types::Bool
  end
end
