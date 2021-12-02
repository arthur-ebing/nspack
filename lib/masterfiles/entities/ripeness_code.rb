# frozen_string_literal: true

module MasterfilesApp
  class RipenessCode < Dry::Struct
    attribute :id, Types::Integer
    attribute :ripeness_code, Types::String
    attribute :description, Types::String
    attribute :legacy_code, Types::String
  end

  class RipenessCodeFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :ripeness_code, Types::String
    attribute :description, Types::String
    attribute :legacy_code, Types::String
    attribute? :status, Types::String
  end
end
