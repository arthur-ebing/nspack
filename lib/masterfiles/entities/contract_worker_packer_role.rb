# frozen_string_literal: true

module MasterfilesApp
  class ContractWorkerPackerRole < Dry::Struct
    attribute :id, Types::Integer
    attribute :packer_role, Types::String
    attribute :default_role, Types::Bool
    attribute :part_of_group_incentive_target, Types::Bool
    attribute? :active, Types::Bool
  end
end
