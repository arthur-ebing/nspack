# frozen_string_literal: true

module Production
  module ProductSetups
    module ProductSetupTemplate
      class Show
        def self.call(id)  # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:product_setup_template, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.form do |form|
              # form.caption 'Product Setup Template'
              form.view_only!
              form.add_field :template_name
              form.add_field :description
              form.add_field :cultivar_group_id
              form.add_field :cultivar_id
              form.add_field :packhouse_resource_id
              form.add_field :production_line_resource_id
              form.add_field :season_group_id
              form.add_field :season_id
              form.add_field :active
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
