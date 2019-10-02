# frozen_string_literal: true

module MasterfilesApp
  class Season < Dry::Struct
    attribute :id, Types::Integer
    attribute :season_group_id, Types::Integer
    attribute :commodity_id, Types::Integer
    attribute :season_code, Types::String
    attribute :description, Types::String
    attribute :season_year, Types::Integer
    attribute :start_date, Types::Date
    attribute :end_date, Types::Date
    attribute? :active, Types::Bool
    attribute :season_group_code, Types::String
    attribute :commodity_code, Types::String
  end
end
