# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
module FinishedGoods
  module Dispatch
    module Load
      class AllocatePallets
        def self.call(id, back_url: nil, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:load, :allocate, id: id, form_values: form_values)
          rules   = ui_rule.compile
          order_number = FinishedGoodsApp::LoadRepo.new.find_load_flat(id)&.order_number

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: back_url,
                                  style: :back_button)
            end
            page.form do |form|
              form.action "/finished_goods/dispatch/loads/#{id}/allocate_pallets_form"
              form.remote!
              form.submit_captions 'Add Pallets'
              form.method :update
              form.caption "Load #{order_number} Details"
              form.row do |row|
                row.column do |col|
                  col.add_field :id
                  col.add_field :depot_id
                  col.add_field :voyage_code
                  col.add_field :pol_voyage_port_id
                  col.add_field :pod_voyage_port_id
                end
                row.column do |col|
                  col.add_field :pallet_list
                end
              end
            end
            page.section do |section|
              section.fit_height!
              section.add_grid('stock_pallets',
                               '/list/stock_pallets/grid_multi',
                               caption: 'Choose Pallets',
                               is_multiselect: true,
                               can_be_cleared: true,
                               multiselect_url: "/finished_goods/dispatch/loads/#{id}/allocate_pallets",
                               multiselect_key: 'allocate_pallets',
                               multiselect_params: { key: 'allocate_pallets',
                                                     id: id,
                                                     in_stock: true })
            end
          end

          layout
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
