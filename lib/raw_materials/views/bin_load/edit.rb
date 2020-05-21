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
              form.add_field :id
              form.add_field :bin_load_purpose_id
              form.add_field :customer_party_role_id
              form.add_field :transporter_party_role_id
              form.add_field :dest_depot_id
              form.add_field :qty_bins
            end
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Add Product',
                                  url: "/raw_materials/dispatch/bin_loads/#{id}/bin_load_products/new",
                                  grid_id: 'bin_load_products',
                                  behaviour: :popup,
                                  style: :button)
              section.add_grid('bin_load_products',
                               "/list/bin_load_products/grid?key=standard&bin_load_id=#{id}",
                               caption: 'Bin Load Products',
                               height: 40)
            end
          end

          layout
        end
      end
    end
  end
end
