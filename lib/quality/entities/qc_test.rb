# frozen_string_literal: true

module QualityApp
  class QcTest < Dry::Struct
    attribute :id, Types::Integer
    attribute :qc_measurement_type_id, Types::Integer
    attribute :qc_sample_id, Types::Integer
    attribute :qc_test_type_id, Types::Integer
    attribute :instrument_plant_resource_id, Types::Integer
    attribute :sample_size, Types::Integer
    attribute :editing, Types::Bool
    attribute :completed, Types::Bool
    attribute :completed_at, Types::DateTime
  end
end
