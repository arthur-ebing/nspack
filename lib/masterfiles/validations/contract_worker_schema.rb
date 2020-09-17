# frozen_string_literal: true

module MasterfilesApp
  ContractWorkerSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:employment_type_id).filled(:integer)
    required(:contract_type_id).filled(:integer)
    required(:wage_level_id).filled(:integer)
    required(:shift_type_id).maybe(:integer)
    required(:first_name).filled(Types::StrippedString)
    required(:surname).filled(Types::StrippedString)
    required(:title).maybe(Types::StrippedString)
    required(:email).maybe(Types::StrippedString)
    required(:contact_number).maybe(Types::StrippedString)
    required(:personnel_number).maybe(Types::StrippedString)
    required(:start_date).maybe(:time)
    required(:end_date).maybe(:time)
  end

  ContractWorkerLinkSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:contract_worker_id).filled(:integer)
  end
end
