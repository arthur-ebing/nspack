# frozen_string_literal: true

module MasterfilesApp
  class QaStandard < Dry::Struct
    attribute :id, Types::Integer
    attribute :qa_standard_name, Types::String
    attribute :description, Types::String
    attribute :season_id, Types::Integer
    attribute :qa_standard_type_id, Types::Integer
    attribute :target_market_ids, Types::Array
    attribute :packed_tm_group_ids, Types::Array
    attribute :internal_standard, Types::Bool
    attribute :applies_to_all_markets, Types::Bool
    attribute? :active, Types::Bool
  end
end
