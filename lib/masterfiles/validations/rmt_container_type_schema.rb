# frozen_string_literal: true

module MasterfilesApp
  RmtContainerTypeSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    optional(:active).filled(:bool)
    required(:container_type_code).filled(Types::StrippedString)
    required(:description).maybe(Types::StrippedString)
    optional(:rmt_inner_container_type_id).maybe(:integer)
    required(:tare_weight).maybe(:decimal)
  end
end
