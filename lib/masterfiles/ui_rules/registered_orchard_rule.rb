# frozen_string_literal: true

module UiRules
  class RegisteredOrchardRule < Base
    def generate_rules
      @repo = MasterfilesApp::FarmRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'registered_orchard'
    end

    def set_show_fields
      fields[:orchard_code] = { renderer: :label }
      fields[:cultivar_code] = { renderer: :label }
      fields[:puc_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:marketing_orchard] = { renderer: :label, as_boolean: true }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        orchard_code: { required: true },
        cultivar_code: { required: true },
        puc_code: { required: true },
        description: {},
        marketing_orchard: { renderer: :checkbox }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_registered_orchard(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(orchard_code: nil,
                                    cultivar_code: nil,
                                    puc_code: nil,
                                    description: nil,
                                    marketing_orchard: true)
    end
  end
end
