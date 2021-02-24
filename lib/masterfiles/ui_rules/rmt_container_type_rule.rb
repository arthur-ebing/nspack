# frozen_string_literal: true

module UiRules
  class RmtContainerTypeRule < Base
    def generate_rules
      @repo = MasterfilesApp::RmtContainerTypeRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode

      form_name 'rmt_container_type'
    end

    def set_show_fields
      fields[:rmt_inner_container_type] = { renderer: :label,
                                            caption: 'Inner Container Type Code',
                                            hide_on_load: @form_object.rmt_inner_container_type.nil? }
      fields[:container_type_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:tare_weight] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        rmt_inner_container_type_id: { renderer: :select, caption: 'Inner Container Type Code',
                                       options: @repo.for_select_rmt_container_types(
                                         exclude: { id: @form_object.id }
                                       ),
                                       disabled_options: @repo.for_select_inactive_rmt_container_types,
                                       prompt: true },
        container_type_code: { required: true },
        tare_weight: {},
        description: {}
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_rmt_container_type(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(id: nil,
                                    container_type_code: nil,
                                    description: nil)
    end
  end
end
