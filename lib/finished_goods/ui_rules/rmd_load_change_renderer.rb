# frozen_string_literal: true

module UiRules
  class RmdLoadChangeRenderer < BaseChangeRenderer
    def change_container_use # rubocop:disable Metrics/AbcSize
      container = options[:use_container]

      key = container ? :show_element : :hide_element
      actions = %w[load_container_code_row
                   load_container_code_row
                   load_container_vents_row
                   load_container_seal_code_row
                   load_internal_container_code_row
                   load_container_temperature_rhine_row
                   load_container_temperature_rhine2_row
                   load_max_gross_weight_row
                   load_cargo_temperature_id_row
                   load_stack_type_id_row
                   load_verified_gross_weight_row
                   load_verified_gross_weight_date_row]

      if AppConst::VGM_REQUIRED
        actions <<  'load_tare_weight_row'
        actions <<  'load_max_payload_row'
        actions <<  'load_actual_payload_row'
      end

      container_actions = {}
      load_container_id = FinishedGoodsApp::LoadContainerRepo.new.find_load_container_by_load(options[:load_id])
      unless load_container_id.nil?
        error_key = container ? :hide_element : :show_element
        value = container ? '' : 'Container info will be lost'
        container_actions = { error_key => [{ dom_id: 'rmd-error' }],
                              replace_inner_html: [{ dom_id: 'rmd-error', value: value }] }
      end

      build_actions(container_actions.merge(key => actions.map { |a| { dom_id: a } },
                                            change_select_value: [{ dom_id: 'load_container',
                                                                    value: container }]))
    end
  end
end
