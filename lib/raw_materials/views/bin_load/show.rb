# frozen_string_literal: true

module RawMaterials
  module Dispatch
    module BinLoad
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:bin_load, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: '/list/bin_loads',
                                  style: :back_button)
            end
            page.form do |form|
              form.submit_captions 'Close'
              form.action '/list/bin_loads'
              form.row do |row|
                row.column do |col|
                  col.add_field :id
                  col.add_field :bin_load_purpose_id
                  col.add_field :customer_party_role_id
                  col.add_field :transporter_party_role_id
                  col.add_field :dest_depot_id
                  col.add_field :qty_bins
                end
                row.column do |col|
                  col.add_field :shipped_at
                  col.add_field :shipped
                  col.add_field :completed_at
                  col.add_field :completed
                  col.add_field :active
                end
              end
            end
            page.section do |section|
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
