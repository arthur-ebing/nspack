# frozen_string_literal: true

module QualityApp
  QcSampleSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:qc_sample_type_id).filled(:integer)
    required(:rmt_delivery_id).maybe(:integer)
    required(:coldroom_location_id).maybe(:integer)
    required(:production_run_id).maybe(:integer)
    required(:orchard_id).maybe(:integer)
    required(:presort_run_lot_number).maybe(Types::StrippedString)
    required(:ref_number).filled(Types::StrippedString)
    required(:short_description).maybe(Types::StrippedString)
    required(:sample_size).filled(:integer)
    optional(:editing).maybe(:bool)
    optional(:completed).maybe(:bool)
    optional(:completed_at).maybe(:time)
    required(:drawn_at).maybe(:time)
    optional(:rmt_bin_ids).maybe(:array).maybe { each(:integer) }
  end
end
