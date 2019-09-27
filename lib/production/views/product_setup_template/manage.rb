# frozen_string_literal: true

module Production
  module ProductSetups
    module ProductSetupTemplate
      class Manage
        def self.call(id, back_url: request.referer)
          ui_rule = UiRules::Compiler.new(:product_setup_template, :manage, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: back_url,
                                  style: :back_button)
            end
            page.add_text rules[:compact_header]
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'New Product Setup',
                                  url: "/production/product_setups/product_setup_templates/#{id}/product_setups/new",
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
