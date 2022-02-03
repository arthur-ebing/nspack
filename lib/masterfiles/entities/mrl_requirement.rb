# frozen_string_literal: true

module MasterfilesApp
  class MrlRequirement < Dry::Struct
    attribute :id, Types::Integer
    attribute :season_id, Types::Integer
    attribute :qa_standard_id, Types::Integer
    attribute :packed_tm_group_id, Types::Integer
    attribute :target_market_id, Types::Integer
    attribute :target_customer_id, Types::Integer
    attribute :cultivar_group_id, Types::Integer
    attribute :cultivar_id, Types::Integer
    attribute :max_num_chemicals_allowed, Types::Integer
    attribute :require_orchard_level_results, Types::Bool
    attribute :no_results_equal_failure, Types::Bool
    attribute? :active, Types::Bool
  end
end
