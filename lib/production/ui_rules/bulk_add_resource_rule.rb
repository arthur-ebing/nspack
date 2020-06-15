# frozen_string_literal: true

module UiRules
  class BulkAddResourceRule < Base
    def generate_rules
      @repo = ProductionApp::ResourceRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields clm_fields if @mode == :clm
      common_values_for_fields ptm_fields if @mode == :ptm

      form_name 'resource'
    end

    def clm_fields
      {
        no_clms: { renderer: :integer, required: true },
        no_clms_per_printer: { renderer: :integer, required: true },
        no_buttons: { renderer: :integer, required: true },
        plant_resource_prefix: { required: true },
        starting_no: { renderer: :integer, required: true }
      }
    end

    def ptm_fields
      {
        no_robots: { renderer: :integer, required: true },
        plant_resource_prefix: { required: true },
        starting_no: { renderer: :integer, required: true },
        bays_per_robot: { renderer: :integer, required: true }
      }
    end

    def make_form_object
      if @mode == :ptm
        @form_object = OpenStruct.new(no_robots: 2,
                                      plant_resource_prefix: 'PTZ ROBOT',
                                      starting_no: starting_no(:ptm),
                                      bays_per_robot: 2)
      end

      return unless @mode == :clm

      @form_object = OpenStruct.new(no_clms: 2,
                                    no_buttons: 6,
                                    no_clms_per_printer: 1,
                                    plant_resource_prefix: 'CLM',
                                    starting_no: starting_no(:clm))
    end

    def starting_no(module_type)
      type_code = module_type == :ptm ? Crossbeams::Config::ResourceDefinitions::PALLETIZING_ROBOT : Crossbeams::Config::ResourceDefinitions::CLM_ROBOT
      code = @repo.max_sys_resource_code_for_plant_type(type_code)
      return 1 if code.nil?

      code.split('-').last.to_i + 1
    end
  end
end
