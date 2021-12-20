# frozen_string_literal: true

module MasterfilesApp
  class QcMeasurementType < Dry::Struct
    attribute :id, Types::Integer
    attribute :qc_measurement_type_name, Types::String
    attribute :description, Types::String
    attribute? :active, Types::Bool
  end
end
