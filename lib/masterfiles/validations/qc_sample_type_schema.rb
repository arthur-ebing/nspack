# frozen_string_literal: true

module MasterfilesApp
  QcSampleTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:qc_sample_type_name).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    required(:default_sample_size).maybe(:integer)
    required(:required_for_first_orchard_delivery).maybe(:bool)
  end
end
