# frozen_string_literal: true

module MasterfilesApp
  class InnerPmMark < Dry::Struct
    attribute :id, Types::Integer
    attribute :inner_pm_mark_code, Types::String
    attribute :description, Types::String
    attribute :tu_mark, Types::Bool
    attribute :ri_mark, Types::Bool
    attribute :ru_mark, Types::Bool
  end
end
