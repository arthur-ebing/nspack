# frozen_string_literal: true

module MasterfilesApp
  class MasterfileVariant < Dry::Struct
    attribute :id, Types::Integer
    attribute :masterfile_table, Types::String
    attribute :variant_code, Types::String
    attribute :masterfile_id, Types::Integer
  end

  class MasterfileVariantFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :variant, Types::String
    attribute :masterfile_table, Types::String
    attribute :masterfile_column, Types::String
    attribute :variant_code, Types::String
    attribute :masterfile_code, Types::String
    attribute :masterfile_id, Types::Integer
    attribute :created_at, Types::DateTime
    attribute :updated_at, Types::DateTime
  end
end
