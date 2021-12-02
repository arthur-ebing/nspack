# frozen_string_literal: true

module MasterfilesApp
  class RmtHandlingRegime < Dry::Struct
    attribute :id, Types::Integer
    attribute :regime_code, Types::String
    attribute :description, Types::String
    attribute :for_packing, Types::Bool
  end

  class RmtHandlingRegimeFlat < Dry::Struct
    attribute :id, Types::Integer
    attribute :regime_code, Types::String
    attribute :description, Types::String
    attribute :for_packing, Types::Bool
    attribute? :status, Types::String
  end
end
