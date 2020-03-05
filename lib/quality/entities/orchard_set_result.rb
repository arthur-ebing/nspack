# frozen_string_literal: true

module QualityApp
  class OrchardSetResult < Dry::Struct
    attribute :id, Types::Integer
    attribute :orchard_test_type_id, Types::Integer
    attribute :puc_id, Types::Integer
    attribute :description, Types::String
    attribute :passed, Types::Bool
    attribute :classification_only, Types::Bool
    attribute :freeze_result, Types::Bool
    attribute :classifications, Types::String
    attribute :cultivar_ids, Types::Array
    attribute :applicable_from, Types::DateTime
    attribute :applicable_to, Types::DateTime
    attribute? :active, Types::Bool
  end
end
