# frozen_string_literal: true

module MasterfilesApp
  class MasterfileVariant < Dry::Struct
    attribute :id, Types::Integer
    attribute :masterfile_table, Types::String
    attribute :code, Types::String
    attribute :masterfile_id, Types::Integer
  end
end
