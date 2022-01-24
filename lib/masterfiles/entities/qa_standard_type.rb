# frozen_string_literal: true

module MasterfilesApp
  class QaStandardType < Dry::Struct
    attribute :id, Types::Integer
    attribute :qa_standard_type_code, Types::String
    attribute :description, Types::String
    attribute? :active, Types::Bool
  end
end
