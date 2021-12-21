# frozen_string_literal: true

module MasterfilesApp
  class QcSampleType < Dry::Struct
    attribute :id, Types::Integer
    attribute :qc_sample_type_name, Types::String
    attribute :description, Types::String
    attribute :default_sample_size, Types::Integer
    attribute :required_for_first_orchard_delivery, Types::Bool
    attribute? :active, Types::Bool
  end
end
