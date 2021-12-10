# frozen_string_literal: true

module MasterfilesApp
  class RmtClassification < Dry::Struct
    attribute :id, Types::Integer
    attribute :rmt_classification_type_id, Types::Integer
    attribute :rmt_classification, Types::String
  end
end
