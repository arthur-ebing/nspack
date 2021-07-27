# frozen_string_literal: true

module RawMaterialsApp
  class PresortStagingRunChild < Dry::Struct
    attribute :id, Types::Integer
    attribute :presort_staging_run_id, Types::Integer
    attribute :staged_at, Types::DateTime
    attribute :canceled, Types::Bool
    attribute :farm_id, Types::Integer
    attribute :editing, Types::Bool
    attribute :staged, Types::Bool
    attribute? :active, Types::Bool
  end

  class PresortStagingRunChildFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :presort_staging_run_id, Types::Integer
    attribute :staged_at, Types::DateTime
    attribute :canceled, Types::Bool
    attribute :farm_id, Types::Integer
    attribute :editing, Types::Bool
    attribute :staged, Types::Bool
    attribute :farm_code, Types::String
    attribute :status, Types::String
    attribute? :active, Types::Bool
  end
end
