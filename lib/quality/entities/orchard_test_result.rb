# frozen_string_literal: true

module QualityApp
  class OrchardTestResult < Dry::Struct
    attribute :id, Types::Integer
    attribute :orchard_test_type_id, Types::Integer
    attribute :puc_id, Types::Integer
    attribute :orchard_id, Types::Integer
    attribute :cultivar_id, Types::Integer
    attribute :description, Types::String
    attribute :status_description, Types::String
    attribute :passed, Types::Bool
    attribute :classification_only, Types::Bool
    attribute :freeze_result, Types::Bool
    attribute :api_result, Types::Hash
    attribute :classifications, Types::String
    attribute :applicable_from, Types::DateTime
    attribute :applicable_to, Types::DateTime
    attribute? :active, Types::Bool
  end

  class OrchardTestResultFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :orchard_test_type_id, Types::Integer
    attribute :orchard_test_type_code, Types::String
    attribute :puc_id, Types::Integer
    attribute :puc_code, Types::String
    attribute :orchard_id, Types::Integer
    attribute :orchard_code, Types::String
    attribute :cultivar_id, Types::Integer
    attribute :cultivar_code, Types::String
    attribute :description, Types::String
    attribute :status_description, Types::String
    attribute :passed, Types::Bool
    attribute :classification_only, Types::Bool
    attribute :freeze_result, Types::Bool
    attribute :api_result, Types::Hash
    attribute :classifications, Types::String
    attribute :applicable_from, Types::DateTime
    attribute :applicable_to, Types::DateTime
    attribute? :active, Types::Bool
  end
end
