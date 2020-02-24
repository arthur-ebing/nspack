# frozen_string_literal: true

module MasterfilesApp
  ContractWorkerSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:employment_type_id, :integer).filled(:int?)
    required(:contract_type_id, :integer).filled(:int?)
    required(:wage_level_id, :integer).filled(:int?)
    required(:shift_type_id, :integer).maybe(:int?)
    required(:first_name, Types::StrippedString).filled(:str?)
    required(:surname, Types::StrippedString).filled(:str?)
    required(:title, Types::StrippedString).maybe(:str?)
    required(:email, Types::StrippedString).maybe(:str?)
    required(:contact_number, Types::StrippedString).maybe(:str?)
    required(:personnel_number, Types::StrippedString).maybe(:str?)
    required(:start_date, %i[nil time]).maybe(:time?)
    required(:end_date, %i[nil time]).maybe(:time?)
  end
end
