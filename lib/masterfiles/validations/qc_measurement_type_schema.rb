# frozen_string_literal: true

module MasterfilesApp
  QcMeasurementTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:qc_measurement_type_name).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
  end
end
