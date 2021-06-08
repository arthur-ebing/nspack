# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
module FinishedGoods
  module Dispatch
    module Load
      class Allocate
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:load, :allocate, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            palbin = ui_rule.form_object.rmt_load ? 'Bin' : 'Pallet'
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: "/finished_goods/dispatch/loads/#{id}",
                                  style: :back_button)
            end
            page.form do |form|
              form.action "/finished_goods/dispatch/loads/#{id}/allocate"
              form.submit_captions "Allocate pasted #{palbin}s"
              form.method :update
              form.row do |row|
                row.column do |col|
                  col.add_field :id
                  col.add_field :depot_id
                  col.add_field :voyage_code
                  col.add_field :pol_port_id
                  col.add_field :pod_port_id
                end
                row.column do |col|
                  col.add_field :pallet_list
                end
              end
            end

            page.add_notice "Use the checkboxes and save selection button to select #{palbin}s from the grid below. - Or add #{palbin}s by listing #{palbin} numbers in the box above and pressing Allocate pasted #{palbin}s."
            page.section do |section|
              section.add_grid('stock_pallets_for_loads',
                               '/list/stock_pallets_for_loads/grid_multi',
                               caption: "Choose #{palbin}s",
                               is_multiselect: true,
                               can_be_cleared: true,
                               multiselect_url: "/finished_goods/dispatch/loads/#{id}/allocate_multiselect",
                               multiselect_key: ui_rule.form_object.rmt_load ? 'allocate_palbins' : 'allocate_pallets',
                               height: 40,
                               multiselect_params: {
                                 load_id: id,
                                 packed_tm_group_id: ui_rule.form_object.packed_tm_group_id,
                                 marketing_org_party_role_id: ui_rule.form_object.marketing_org_party_role_id,
                                 target_customer_party_role_id: ui_rule.form_object.target_customer_party_role_id
                               })
            end
          end

          layout
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
