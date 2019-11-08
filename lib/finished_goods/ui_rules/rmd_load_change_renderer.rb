# frozen_string_literal: true

module UiRules
  class RmdLoadChangeRenderer < BaseChangeRenderer
    def change_container_use # rubocop:disable Metrics/AbcSize
      container = options[:use_container]

      actions = {}
      actions[:change_select_value] = [{ dom_id: 'truck_arrival_container', value: container }]

      # hide show if container
      row_ids = %w[container_info_section
                   truck_arrival_container_code_row
                   truck_arrival_container_vents_row
                   truck_arrival_container_seal_code_row
                   truck_arrival_internal_container_code_row
                   truck_arrival_container_temperature_rhine_row
                   truck_arrival_container_temperature_rhine2_row
                   truck_arrival_max_gross_weight_row
                   truck_arrival_cargo_temperature_id_row
                   truck_arrival_stack_type_id_row
                   truck_arrival_verified_gross_weight_row
                   truck_arrival_verified_gross_weight_date_row]
      if AppConst::VGM_REQUIRED
        row_ids <<  'truck_arrival_tare_weight_row'
        row_ids <<  'truck_arrival_max_payload_row'
        row_ids <<  'truck_arrival_actual_payload_row'
      end
      actions[container ? :show_element : :hide_element] = row_ids.map { |a| { dom_id: a } }

      # test delete flash warning
      container_id = FinishedGoodsApp::LoadContainerRepo.new.find_load_container_by_load(options[:load_id])
      unless container_id.nil?
        if container
          actions[:hide_element] = [{ dom_id: 'rmd-error' }]
          actions[:replace_inner_html] = [{ dom_id: 'rmd-error', value: '' }]
        else
          actions[:show_element] = [{ dom_id: 'rmd-error' }]
          actions[:replace_inner_html] = [{ dom_id: 'rmd-error', value: 'Container info will be lost' }]
        end
      end

      # set_required
      req_ids = %w[truck_arrival_container_code
                   truck_arrival_container_temperature_rhine
                   truck_arrival_max_gross_weight
                   truck_arrival_cargo_temperature_id
                   truck_arrival_stack_type_id
                   truck_arrival_verified_gross_weight
                   truck_arrival_verified_gross_weight_date]
      if AppConst::VGM_REQUIRED
        req_ids <<  'truck_arrival_tare_weight'
        req_ids <<  'truck_arrival_max_payload'
        req_ids <<  'truck_arrival_actual_payload'
      end
      actions[:set_required] = req_ids.map { |a| { dom_id: a, required: container } }
      build_actions(actions)
    end
  end
end
