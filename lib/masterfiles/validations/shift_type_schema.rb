# frozen_string_literal: true

module MasterfilesApp
  ShiftTypeSchema = Dry::Validation.Params do
    configure do
      config.type_specs = true

      def self.messages
        super.merge(en: { errors: { base: 'Start hour must be before End hour.' } })
      end
    end

    optional(:id, :integer).filled(:int?)
    required(:ph_plant_resource_id, :integer).filled(:int?)
    required(:line_plant_resource_id, :integer).maybe(:int?)
    required(:employment_type_id, :integer).filled(:int?)
    required(:start_hour, :integer).filled(:int?, gt?: 0)
    required(:end_hour, :integer).filled(:int?, gt?: 0)
    required(:day_night_or_custom, :string).filled(:str?)

    validate(base: %i[start_hour end_hour]) do |starthr, endhr|
      starthr < endhr
    end
  end
end
