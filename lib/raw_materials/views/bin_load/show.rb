# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
module RawMaterials
  module Dispatch
    module BinLoad
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:bin_load, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: '/list/bin_loads',
                                  style: :back_button)
              ui_rule.form_object.back_actions.each do |action|
                action ||= {}
                section.add_control(action)
              end
              section.add_control(control_type: :link,
                                  text: 'Print Bin Load',
                                  url: "/raw_materials/reports/bin_load/#{id}",
                                  visible: ui_rule.form_object.products,
                                  loading_window: true,
                                  style: :button)
            end
            page.form do |form|
              form.no_submit!
              form.row do |row|
                row.column do |col|
                  col.add_field :id
                  col.add_field :bin_load_purpose_id
                  col.add_field :customer_party_role_id
                  col.add_field :transporter_party_role_id
                  col.add_field :dest_depot_id
                end
                row.column do |col|
                  col.add_field :qty_bins
                  col.add_field :completed_at
                  col.add_field :completed
                  col.add_field :shipped_at
                  col.add_field :shipped
                end
              end
            end
            page.section do |section|
              section.add_progress_step ui_rule.form_object.steps, position: ui_rule.form_object.step
              section.show_border!
              ui_rule.form_object.actions.each do |action|
                action ||= {}
                section.add_control(action)
              end
            end
            page.form do |form|
              form.action '/list/bin_loads'
              form.submit_captions 'Close'
            end
            page.section do |section|
              section.add_grid('bin_load_products',
                               "/list/bin_load_products/grid?key=standard&bin_load_id=#{id}",
                               caption: 'Bin Load Products',
                               height: 15)
              if ui_rule.form_object.allocated
                section.add_grid('rmt_bins',
                                 "/list/bin_loads_matching_rmt_bins/grid?key=shipped_bin_load&bin_load_id=#{id}",
                                 caption: 'Shipped Bins on Load',
                                 height: 45)
              else
                section.add_grid('rmt_bins',
                                 "/list/bin_loads_matching_rmt_bins/grid?key=bin_load&bin_load_id=#{id}",
                                 caption: 'Available Bins for Load',
                                 height: 45)
              end
            end
          end

          layout
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
