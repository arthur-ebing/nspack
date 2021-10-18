# frozen_string_literal: true

module Production
  module ProductSetups
    module ProductSetupTemplate
      class Manage
        def self.call(id)
          ui_rule = UiRules::Compiler.new(:product_setup_template, :manage, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            if AppConst::CR_PROD.use_packing_specifications?
              page.section do |section|
                section.add_control(control_type: :link,
                                    text: 'Back',
                                    url: '/list/packing_specification_templates/with_params?key=active&product_setup_templates.active=true',
                                    style: :back_button)
              end
              page.add_text rules[:compact_header]
              page.section do |section|
                section.add_control(control_type: :link,
                                    text: 'New Packing Specification',
                                    url: "/production/packing_specifications/wizard/setup?product_setup_template_id=#{id}",
                                    style: :button)
                section.add_control(control_type: :link,
                                    text: 'New Rebin Product Setup',
                                    url: "/production/packing_specifications/wizard/setup?product_setup_template_id=#{id}&rebin=true",
                                    style: :button)
                section.add_grid('packing_specification_items',
                                 "/list/packing_specification_items/grid?key=product_setup_template&id=#{id}",
                                 caption: 'Packing Specifications Items')
              end
            else
              page.section do |section|
                section.add_control(control_type: :link,
                                    text: 'Back',
                                    url: '/list/product_setup_templates/with_params?key=active&product_setup_templates.active=true',
                                    style: :back_button)
              end
              page.add_text rules[:compact_header]
              page.section do |section|
                section.add_control(control_type: :link,
                                    text: 'New Product Setup',
                                    url: "/production/product_setups/product_setup_templates/#{id}/product_setups/new",
                                    style: :button)
                section.add_control(control_type: :link,
                                    text: 'New Product Setup Wizard',
                                    url: "/production/packing_specifications/wizard/setup?product_setup_template_id=#{id}",
                                    style: :button)
                section.add_control(control_type: :link,
                                    text: 'New Rebin Product Setup',
                                    url: "/production/packing_specifications/wizard/setup?product_setup_template_id=#{id}&rebin=true",
                                    style: :button)
                section.add_grid('product_setups',
                                 "/list/product_setups/grid?key=standard&product_setups.product_setup_template_id=#{id}",
                                 caption: 'Product Setups')
              end
            end
          end

          layout
        end
      end
    end
  end
end
