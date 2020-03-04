# frozen_string_literal: true

module QualityApp
  OrchardTestCreateSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    required(:orchard_test_type_id, :integer).filled(:int?)
  end

  OrchardTestUpdateSchema = Dry::Validation.Params do
    configure { config.type_specs = true }

    optional(:id, :integer).filled(:int?)
    optional(:orchard_test_type_id, :integer).maybe(:int?)
    required(:orchard_set_result_id, :integer).maybe(:int?)
    required(:orchard_id, :integer).filled(:int?)
    required(:puc_id, :integer).filled(:int?)
    required(:description, Types::StrippedString).maybe(:str?)
    required(:status_description, Types::StrippedString).maybe(:str?)
    required(:passed, :bool).filled(:bool?)
    required(:classification_only, :bool).maybe(:bool?)
    required(:freeze_result, :bool).maybe(:bool?)
    required(:classifications, :string).maybe(:str?)
    required(:cultivar_id, :integer).maybe(:int?)
    optional(:applicable_from, %i[nil time]).maybe(:time?)
    optional(:applicable_to, %i[nil time]).maybe(:time?)
  end
end
