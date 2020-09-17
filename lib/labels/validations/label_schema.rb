# frozen_string_literal: true

module LabelApp
  LabelSchema = Dry::Schema.Params do
    optional(:id).filled(:integer)
    required(:label_name).filled(Types::StrippedString)
    optional(:label_dimension).filled(:string)
    optional(:px_per_mm).filled(:string)
    optional(:multi_label).maybe(:bool)
    optional(:variable_set).filled(Types::StrippedString)
  end
end
