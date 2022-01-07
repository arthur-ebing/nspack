# frozen_string_literal: true

module RawMaterialsApp
  class PresortStagingRun < Dry::Struct
    attribute :id, Types::Integer
    attribute :setup_uncompleted_at, Types::DateTime
    attribute :setup_completed, Types::Bool
    attribute :presort_unit_plant_resource_id, Types::Integer
    attribute :supplier_id, Types::Integer
    attribute :setup_completed_at, Types::DateTime
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
    attribute? :running, Types::Bool
    attribute :colour_percentage_id, Types::Integer
    attribute :actual_cold_treatment_id, Types::Integer
    attribute :actual_ripeness_treatment_id, Types::Integer
    attribute :rmt_code_id, Types::Integer
  end

  class PresortStagingRunFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :setup_uncompleted_at, Types::DateTime
    attribute :setup_completed, Types::Bool
    attribute :presort_unit_plant_resource_id, Types::Integer
    attribute :supplier_id, Types::Integer
    attribute :created_at, Types::DateTime
    attribute :staged_at, Types::DateTime
    attribute :setup_completed_at, Types::DateTime
    attribute :canceled, Types::Bool
    attribute :canceled_at, Types::DateTime
    attribute :cultivar_id, Types::Integer
    attribute :rmt_class_id, Types::Integer
    attribute :rmt_size_id, Types::Integer
    attribute :season_id, Types::Integer
    attribute :editing, Types::Bool
    attribute :staged, Types::Bool
    attribute :legacy_data, Types::Hash
    attribute? :running, Types::Bool
    attribute :status, Types::String
    attribute :plant_resource_code, Types::String
    attribute :cultivar_name, Types::String
    attribute :rmt_class_code, Types::String
    attribute :size_code, Types::String
    attribute :season_code, Types::String
    attribute :supplier, Types::String
    attribute :supplier_party_role_id, Types::Integer
    attribute :colour_percentage_id, Types::Integer
    attribute :actual_cold_treatment_id, Types::Integer
    attribute :actual_ripeness_treatment_id, Types::Integer
    attribute :rmt_code_id, Types::Integer
    attribute :rmt_code, Types::String
    attribute :colour_percentage, Types::String
    attribute :actual_cold_treatment_code, Types::String
    attribute :actual_ripeness_treatment_code, Types::String
  end
end
