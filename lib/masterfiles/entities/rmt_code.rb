# frozen_string_literal: true

module MasterfilesApp
  class RmtCode < Dry::Struct
    attribute :id, Types::Integer
    attribute :rmt_variant_id, Types::Integer
    attribute :rmt_handling_regime_id, Types::Integer
    attribute :rmt_code, Types::String
    attribute :description, Types::String
    attribute :legacy_code, Types::String
  end
end
