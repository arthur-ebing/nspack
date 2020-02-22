# frozen_string_literal: true

module MasterfilesApp
  class EmploymentType < Dry::Struct
    attribute :id, Types::Integer
    attribute :employment_type_code, Types::String
  end
end
