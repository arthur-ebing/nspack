# frozen_string_literal: true

module QualityApp
  class QcSample < Dry::Struct
    attribute :id, Types::Integer
    attribute :qc_sample_type_id, Types::Integer
    attribute :rmt_delivery_id, Types::Integer
    attribute :coldroom_location_id, Types::Integer
    attribute :production_run_id, Types::Integer
    attribute :orchard_id, Types::Integer
    attribute :presort_run_lot_number, Types::String
    attribute :ref_number, Types::String
    attribute :short_description, Types::String
    attribute :sample_size, Types::Integer
    attribute :editing, Types::Bool
    attribute :completed, Types::Bool
    attribute :completed_at, Types::DateTime
    attribute :rmt_bin_ids, Types::Array
    attribute :drawn_at, Types::DateTime
    attribute? :created_at, Types::DateTime
  end

  class QcSampleLabel < Dry::Struct
    attribute :sample_id, Types::Integer
    attribute :qc_sample_type_code, Types::String
    attribute :sample_date, Types::Date
    attribute :context, Types::String
    attribute :context_ref, Types::String
    attribute :ref_number, Types::String
    attribute :short_description, Types::String
    attribute :sample_size, Types::Integer
  end
end
