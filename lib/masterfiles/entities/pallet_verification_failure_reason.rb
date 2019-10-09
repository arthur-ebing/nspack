# frozen_string_literal: true

module MasterfilesApp
  class PalletVerificationFailureReason < Dry::Struct
    attribute :id, Types::Integer
    attribute :reason, Types::String
    attribute? :active, Types::Bool
  end
end
