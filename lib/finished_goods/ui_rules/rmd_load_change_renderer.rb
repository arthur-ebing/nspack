# frozen_string_literal: true

module UiRules
  class RmdLoadChangeRenderer < BaseChangeRenderer
    def change_container_use # rubocop:disable Metrics/AbcSize
      container = options[:use_container]

      actions = {}
      actions[:change_select_value] = [{ dom_id: 'load_container', value: container }]

      # hide show if container
      row_ids = %w[container_info_section
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
        row_ids <<  'load_tare_weight_row'
        row_ids <<  'load_max_payload_row'
        row_ids <<  'load_actual_payload_row'
      end
      actions[container ? :show_element : :hide_element] = row_ids.map { |a| { dom_id: a } }

      # test delete flash warning
      load_container_id = FinishedGoodsApp::LoadContainerRepo.new.find_load_container_by_load(options[:load_id])
      unless load_container_id.nil?
        if container
          actions[:hide_element] = [{ dom_id: 'rmd-error' }]
          actions[:replace_inner_html] = [{ dom_id: 'rmd-error', value: '' }]
        else
          actions[:show_element] = [{ dom_id: 'rmd-error' }]
          actions[:replace_inner_html] = [{ dom_id: 'rmd-error', value: 'Container info will be lost' }]
        end
      end

      # set_required
      req_ids = %w[load_container_code
                   load_container_temperature_rhine
                   load_max_gross_weight
                   load_cargo_temperature_id
                   load_stack_type_id
                   load_verified_gross_weight
                   load_verified_gross_weight_date]
      if AppConst::VGM_REQUIRED
        req_ids <<  'load_tare_weight'
        req_ids <<  'load_max_payload'
        req_ids <<  'load_actual_payload'
      end
      actions[:set_required] = req_ids.map { |a| { dom_id: a, required: container } }
      build_actions(actions)
    end
  end
end
