# frozen_string_literal: true

module RawMaterials
  module Dispatch
    module BinLoad
      class Edit
        def self.call(id, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:bin_load, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: '/list/bin_loads',
                                  style: :back_button)
            end
            page.form do |form|
              form.action "/raw_materials/dispatch/bin_loads/#{id}"
              form.method :update
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
                  col.add_field :shipped_at
                  col.add_field :shipped
                  col.add_field :completed_at
                  col.add_field :completed
                end
              end
            end
          end

          layout
        end
      end
    end
  end
end
