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
              form.add_field :production_line_id
              form.add_field :season_group_id
              form.add_field :season_id
              form.add_field :active
            end
          end

          layout
        end
      end
    end
  end
end
