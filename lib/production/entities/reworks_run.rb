# frozen_string_literal: true

module ProductionApp
  class ReworksRun < Dry::Struct
    attribute :id, Types::Integer
    attribute :user, Types::String
    attribute :reworks_run_type_id, Types::Integer
    attribute :remarks, Types::String
    attribute :scrap_reason_id, Types::Integer
    attribute :pallets_selected, Types::Array
    attribute :pallets_affected, Types::Array
    attribute :changes_made, Types::Hash
    attribute :pallets_scrapped, Types::Array
    attribute :pallets_unscrapped, Types::Array
  end

  class ReworksRunFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :user, Types::String
    attribute :reworks_run_type_id, Types::Integer
    attribute :reworks_run_type, Types::String
    attribute :remarks, Types::String
    attribute :scrap_reason_id, Types::Integer
    attribute :scrap_reason, Types::String
    attribute :reworks_action, Types::String
    attribute :pallets_selected, Types::Array
    attribute :pallets_affected, Types::Array
    attribute :pallet_id, Types::Integer
    attribute :pallet_number, Types::String
    attribute :pallet_sequence_number, Types::String
    attribute :before_state, Types::Hash
    attribute :after_state, Types::Hash
    attribute :before_descriptions_state, Types::Hash
    attribute :after_descriptions_state, Types::Hash
    attribute :changes_made, Types::Hash
    attribute :changes_made_array, Types::Hash
    attribute :created_at, Types::DateTime
    attribute :allow_cultivar_mixing, Types::Bool
    attribute :has_children, Types::Bool
    attribute :allow_cultivar_group_mixing, Types::Bool
  end
end
