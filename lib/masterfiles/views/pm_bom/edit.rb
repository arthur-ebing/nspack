# frozen_string_literal: true

module Masterfiles
  module Packaging
    module PmBom
      class Edit
        def self.call(id, is_update: nil, form_values: nil, form_errors: nil) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:pm_bom, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors

            page.section do |section|
              section.row do |row|
                row.column do |col|
                  col.add_control(control_type: :link,
                                  text: 'Back to PM BOMs',
                                  url: '/list/pm_boms',
                                  style: :back_button)

                  col.add_control(control_type: :link,
                                  text: 'Suggest Weights',
                                  url: "/masterfiles/packaging/pm_boms/#{id}/calculate_bom_weights",
                                  style: :button,
                                  visible: rules[:require_extended_packaging])
                end
              end
            end

            page.form do |form|
              form.caption 'Edit PM BOM'
              form.action "/masterfiles/packaging/pm_boms/#{id}"
              form.remote!
              form.method :update
              form.row do |row|
                row.column do |col|
                  col.add_field :bom_code
                  col.add_field :erp_bom_code
                  col.add_field :gross_weight
                end
                row.column do |col|
                  col.add_field :system_code
                  col.add_field :description
                  col.add_field :label_description
                  col.add_field :nett_weight
                end
              end
            end

            unless is_update

              page.section do |section|
                section.add_control(control_type: :link,
                                    text: 'New PM BOMs Products',
                                    url: "/masterfiles/packaging/pm_boms/#{id}/pm_boms_products/new",
                                    behaviour: :popup,
                                    style: :button)
                section.add_grid('pm_boms_products',
                                 "/list/pm_boms_products/grid?key=standard&pm_boms_products.pm_bom_id=#{id}",
                                 height: 25,
                                 caption: 'PM BOM Products')
              end
            end
          end

          layout
        end
      end
    end
  end
end
