# frozen_string_literal: true

module QualityApp
  class MrlResult < Dry::Struct
    attribute :id, Types::Integer
    attribute :post_harvest_parent_mrl_result_id, Types::Integer
    attribute :cultivar_id, Types::Integer
    attribute :puc_id, Types::Integer
    attribute :season_id, Types::Integer
    attribute :rmt_delivery_id, Types::Integer
    attribute :farm_id, Types::Integer
    attribute :laboratory_id, Types::Integer
    attribute :mrl_sample_type_id, Types::Integer
    attribute :orchard_id, Types::Integer
    attribute :production_run_id, Types::Integer
    attribute :waybill_number, Types::String
    attribute :reference_number, Types::String
    attribute :sample_number, Types::String
    attribute :ph_level, Types::Integer
    attribute :num_active_ingredients, Types::Integer
    attribute :max_num_chemicals_passed, Types::Bool
    attribute :mrl_sample_passed, Types::Bool
    attribute :pre_harvest_result, Types::Bool
    attribute :post_harvest_result, Types::Bool
    attribute :fruit_received_at, Types::DateTime
    attribute :sample_submitted_at, Types::DateTime
    attribute :result_received_at, Types::DateTime
    attribute? :active, Types::Bool
  end

  class MrlResultFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :post_harvest_parent_mrl_result_id, Types::Integer
    attribute :cultivar_id, Types::Integer
    attribute :puc_id, Types::Integer
    attribute :season_id, Types::Integer
    attribute :rmt_delivery_id, Types::Integer
    attribute :farm_id, Types::Integer
    attribute :laboratory_id, Types::Integer
    attribute :mrl_sample_type_id, Types::Integer
    attribute :orchard_id, Types::Integer
    attribute :production_run_id, Types::Integer
    attribute :waybill_number, Types::String
    attribute :reference_number, Types::String
    attribute :sample_number, Types::String
    attribute :ph_level, Types::Integer
    attribute :num_active_ingredients, Types::Integer
    attribute :max_num_chemicals_passed, Types::Bool
    attribute :mrl_sample_passed, Types::Bool
    attribute :pre_harvest_result, Types::Bool
    attribute :post_harvest_result, Types::Bool
    attribute :fruit_received_at, Types::DateTime
    attribute :sample_submitted_at, Types::DateTime
    attribute :result_received_at, Types::DateTime
    attribute? :active, Types::Bool
    attribute :cultivar_name, Types::String
    attribute :puc_code, Types::String
    attribute :season_code, Types::String
    attribute :farm_code, Types::String
    attribute :orchard_code, Types::String
    attribute :production_run_code, Types::String
    attribute :lab_code, Types::String
    attribute :sample_type_code, Types::String
  end
end
