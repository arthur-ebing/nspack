# frozen_string_literal: true

module MasterfilesApp
  class QcTestType < Dry::Struct
    attribute :id, Types::Integer
    attribute :qc_test_type_name, Types::String
    attribute :description, Types::String
    attribute? :active, Types::Bool
  end
end
