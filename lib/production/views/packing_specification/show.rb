# frozen_string_literal: true

module Production
  module PackingSpecifications
    module PackingSpecification
      class Show
        def self.call(id) # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:packing_specification, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: '/list/packing_specifications',
                                  style: :back_button)
            end
            page.form do |form|
              form.no_submit!
              form.fold_up do |fold|
                fold.caption 'Packing Specification'
                fold.open!
                fold.row do |row|
                  row.column do |col|
                    col.add_field :product_setup_template
                    col.add_field :packing_specification_code
                    col.add_field :description
                  end
                  row.column do |col|
                    col.add_field :cultivar_group_code
                    col.add_field :packhouse
                    col.add_field :line
                  end
                end
              end
            end
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'New Packing Specification Item',
                                  url: "/production/packing_specifications/packing_specification_items/new/
                                        with_params?packing_specification_id=#{id}&product_setup_template_id=#{ui_rule.form_object.product_setup_template_id}",
                                  behaviour: :popup,
                                  style: :button)
              section.add_grid('packing_specification_items',
                               "/list/packing_specification_items/grid?key=packing_specification&id=#{id}",
                               caption: 'Packing Specification Items',
                               height: 30)
            end
          end

          layout
        end
      end
    end
  end
end
