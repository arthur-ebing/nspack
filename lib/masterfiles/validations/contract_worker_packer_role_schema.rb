# frozen_string_literal: true

module MasterfilesApp
  ContractWorkerPackerRoleSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:packer_role).filled(Types::StrippedString)
    required(:default_role).maybe(:bool)
    required(:part_of_group_incentive_target).maybe(:bool)
  end
end
