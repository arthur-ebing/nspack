# frozen_string_literal: true

module Production
  module ProductSetups
    module ProductSetupTemplate
      class Show
        def self.call(id)  # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:product_setup_template, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: '/list/product_setup_templates',
                                  style: :back_button)
            end
            page.form do |form|
              # form.caption 'Product Setup Template'
              form.view_only!
              form.no_submit!
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
                  col.add_field :active
                end
              end
            end

            page.section do |section|
              section.add_grid('product_setups',
                               "/list/product_setups_view/grid?key=standard&product_setups.product_setup_template_id=#{id}",
                               caption: 'Product Setups')
            end
          end

          layout
        end
      end
    end
  end
end
