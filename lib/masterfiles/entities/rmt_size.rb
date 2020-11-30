# frozen_string_literal: true

module MasterfilesApp
  class RmtSize < Dry::Struct
    attribute :id, Types::Integer
    attribute :size_code, Types::String
    attribute :description, Types::String
  end
end
