# frozen_string_literal: true

module MasterfilesApp
  QcSampleTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:qc_sample_type_name).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    required(:default_sample_size).maybe(:integer)
  end
end
