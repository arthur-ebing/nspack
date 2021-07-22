# frozen_string_literal: true

module RawMaterialsApp
  class PresortStagingRun < Dry::Struct
    attribute :id, Types::Integer
    attribute :uncompleted_at, Types::DateTime
    attribute :completed, Types::Bool
    attribute :presort_unit_plant_resource_id, Types::Integer
    attribute :supplier_id, Types::Integer
    attribute :completed_at, Types::DateTime
    attribute :canceled, Types::Bool
    attribute :created_at, Types::DateTime
    attribute :staged_at, Types::DateTime
    attribute :canceled_at, Types::DateTime
    attribute :cultivar_id, Types::Integer
    attribute :rmt_class_id, Types::Integer
    attribute :rmt_size_id, Types::Integer
    attribute :season_id, Types::Integer
    attribute :editing, Types::Bool
    attribute :staged, Types::Bool
    attribute :legacy_data, Types::Hash
    attribute? :active, Types::Bool
  end

  class PresortStagingRunFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :uncompleted_at, Types::DateTime
    attribute :completed, Types::Bool
    attribute :presort_unit_plant_resource_id, Types::Integer
    attribute :supplier_id, Types::Integer
    attribute :created_at, Types::DateTime
    attribute :staged_at, Types::DateTime
    attribute :completed_at, Types::DateTime
    attribute :canceled, Types::Bool
    attribute :canceled_at, Types::DateTime
    attribute :cultivar_id, Types::Integer
    attribute :rmt_class_id, Types::Integer
    attribute :rmt_size_id, Types::Integer
    attribute :season_id, Types::Integer
    attribute :editing, Types::Bool
    attribute :staged, Types::Bool
    attribute :legacy_data, Types::Hash
    attribute? :active, Types::Bool

    attribute :status, Types::String
    attribute :plant_resource_code, Types::String
    attribute :cultivar_name, Types::String
    attribute :rmt_class_code, Types::String
    attribute :size_code, Types::String
    attribute :season_code, Types::String
    attribute :supplier, Types::String
    attribute :supplier_party_role_id, Types::Integer
  end
end
