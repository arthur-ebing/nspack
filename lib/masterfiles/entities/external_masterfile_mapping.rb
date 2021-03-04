# frozen_string_literal: true

module MasterfilesApp
  class ExternalMasterfileMapping < Dry::Struct
    attribute :id, Types::Integer
    attribute :mapping, Types::String
    attribute :masterfile_table, Types::String
    attribute :masterfile_column, Types::String
    attribute :external_code, Types::String
    attribute :external_system, Types::String
    attribute :masterfile_code, Types::String
    attribute :masterfile_id, Types::Integer
    attribute :created_at, Types::DateTime
    attribute :updated_at, Types::DateTime
  end
end
