# frozen_string_literal: true

module UiRules
  class RmdProductionChangeRenderer < BaseChangeRenderer
    def change_print_pallet_label
      print_pallet_label = options[:print_pallet_label]
      actions = {}
      actions[:set_checked] = [{ dom_id: 'verify_pallet_sequence_print_pallet_label', checked: print_pallet_label }]
      # show_element hide_element if print_pallet_label
      row_ids = %w[verify_pallet_sequence_qty_to_print_row
                   verify_pallet_sequence_printer_row
                   verify_pallet_sequence_pallet_label_name_row]

      actions[print_pallet_label ? :show_element : :hide_element] = row_ids.map { |a| { dom_id: a } }

      build_actions(actions)
    end
  end
end
