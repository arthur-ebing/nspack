# frozen_string_literal: true

module Production
  module ProductSetups
    module ProductSetupTemplate
      class Edit
        def self.call(id, form_values: nil, form_errors: nil)  # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:product_setup_template, :edit, id: id, form_values: form_values)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.form_values form_values
            page.form_errors form_errors
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: '/list/product_setup_templates',
                                  style: :back_button)
            end
            page.form do |form|
              form.caption 'Edit Product Setup Template'
              form.action "/production/product_setups/product_setup_templates/#{id}"
              form.remote!
              form.method :update
              form.row do |row|
                row.column do |col|
                  col.add_field :template_name
                  col.add_field :description
                  col.add_field :cultivar_group_id
                  col.add_field :cultivar_id
                end
                row.column do |col|
                  col.add_field :packhouse_resource_id
                  col.add_field :production_line_resource_id
                  col.add_field :season_group_id
                  col.add_field :season_id
                end
              end
            end

            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'New Product Setup',
                                  url: "/production/product_setups/product_setup_templates/#{id}/product_setups/new",
                                  behaviour: :popup,
                                  style: :button)
              section.add_grid('product_setups',
                               "/list/product_setups/grid?key=standard&product_setups.product_setup_template_id=#{id}",
                               caption: 'Product Setups')
            end
          end

          layout
        end
      end
    end
  end
end
