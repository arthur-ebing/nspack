# frozen_string_literal: true

module MasterfilesApp
  class RmtClassificationType < Dry::Struct
    attribute :id, Types::Integer
    attribute :rmt_classification_type_code, Types::String
    attribute :description, Types::String
    attribute :required_for_delivery, Types::Bool
    attribute :physical_attribute, Types::Bool
  end
end
