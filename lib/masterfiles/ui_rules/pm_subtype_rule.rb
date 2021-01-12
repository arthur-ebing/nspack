# frozen_string_literal: true

module UiRules
  class PmSubtypeRule < Base
    def generate_rules
      @repo = MasterfilesApp::BomRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode

      form_name 'pm_subtype'
    end

    def set_show_fields
      pm_type_id_label = @repo.find_hash(:pm_types, @form_object.pm_type_id)[:pm_type_code]
      fields[:pm_type_id] = { renderer: :label, with_value: pm_type_id_label, caption: 'PM Type' }
      fields[:subtype_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:pm_products] = { renderer: :list, items: pm_products }
      fields[:short_code] = { renderer: :label }
    end

    def common_fields
      {
        pm_type_id: { renderer: :select,
                      options: @repo.for_select_pm_types,
                      disabled_options: @repo.for_select_inactive_pm_types,
                      caption: 'pm_type',
                      required: true },
        subtype_code: { required: true,
                        force_uppercase: true },
        description: {},
        short_code: { required: true,
                      force_uppercase: true }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_pm_subtype(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(pm_type_id: nil,
                                    subtype_code: nil,
                                    description: nil,
                                    short_code: nil)
    end

    def pm_products
      @repo.find_pm_subtype_products(@options[:id])
    end
  end
end
