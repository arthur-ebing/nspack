# frozen_string_literal: true

module MasterfilesApp
  class ContractWorker < Dry::Struct
    attribute :id, Types::Integer
    attribute :employment_type_id, Types::Integer
    attribute :contract_type_id, Types::Integer
    attribute :wage_level_id, Types::Integer
    attribute :shift_type_id, Types::Integer
    attribute :shift_type_code, Types::String
    attribute :employment_type_code, Types::String
    attribute :contract_type_code, Types::String
    attribute :contract_worker_name, Types::String
    attribute :wage_level, Types::Decimal
    attribute :first_name, Types::String
    attribute :surname, Types::String
    attribute :title, Types::String
    attribute :email, Types::String
    attribute :contact_number, Types::String
    attribute :personnel_number, Types::String
    attribute :start_date, Types::DateTime
    attribute :end_date, Types::DateTime
    attribute :active, Types::Bool
  end
end
