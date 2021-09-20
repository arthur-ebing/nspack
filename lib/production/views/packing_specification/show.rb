# frozen_string_literal: true

module Production
  module PackingSpecifications
    module PackingSpecification
      class Show
        def self.call(id, back_url:)
          ui_rule = UiRules::Compiler.new(:packing_specification_item, :show, id: id)
          rules   = ui_rule.compile

          layout = Crossbeams::Layout::Page.build(rules) do |page|
            page.form_object ui_rule.form_object
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: back_url,
                                  style: :back_button)
            end
            page.form do |form|
              form.view_only!
              form.no_submit!
              form.row do |row|
                row.column do |col|
                  col.add_field :product_setup_template
                  col.add_field :cultivar_group
                  col.add_field :cultivar
                end
              end
              form.row do |row|
                row.column do |col|
                  col.expand_collapse button: true, mini: false
                end
              end
              form.row do |row|
                row.column do |col|
                  col.fold_up do |fold|
                    fold.caption 'Fruit details'
                    fold.add_field :commodity
                    fold.add_field :marketing_variety
                    fold.add_field :std_fruit_size_count
                    fold.add_field :basic_pack
                    fold.add_field :fruit_actual_counts_for_pack
                    fold.add_field :standard_pack
                    fold.add_field :fruit_size_reference
                    fold.add_field :class
                    fold.add_field :grade
                    fold.add_field :colour_percentage
                  end
                end
                row.column do |col|
                  col.fold_up do |fold|
                    fold.caption 'Marketing details'
                    fold.add_field :marketing_org
                    fold.add_field :packed_tm_group
                    fold.add_field :target_market
                    fold.add_field :target_customer
                    fold.add_field :sell_by_code
                    fold.add_field :mark
                    fold.add_field :product_chars
                    fold.add_field :inventory_code
                    fold.add_field :customer_variety
                    fold.add_field :client_product_code
                    fold.add_field :client_size_reference
                    fold.add_field :marketing_order_number
                    fold.add_field :gtin_code
                  end
                end
              end
              form.row do |row|
                row.column do |col|
                  col.fold_up do |fold|
                    fold.caption 'Pallet details'
                    fold.add_field :pallet_base
                    fold.add_field :pallet_stack_type
                    fold.add_field :pallet_format
                    fold.add_field :pallet_label_name
                    fold.add_field :cartons_per_pallet
                    fold.add_field :description
                    fold.add_field :carton_template_name
                  end
                end
                row.column do |col|
                  col.fold_up do |fold|
                    fold.caption 'Treatment Details'
                    fold.add_field :treatments
                  end
                end
              end
              form.row do |row|
                row.column do |col|
                  col.fold_up do |fold|
                    fold.caption 'Packing Specification'
                    fold.add_field :product_setup
                    fold.add_field :pm_bom
                    fold.add_field :pm_mark
                    fold.add_field :tu_labour_product
                    fold.add_field :ru_labour_product
                    fold.add_field :ri_labour_product
                  end
                end
                row.column do |col|
                  col.fold_up do |fold|
                    fold.caption 'Packing Specification Stickers'
                    fold.add_field :fruit_stickers
                    fold.add_field :tu_stickers
                    fold.add_field :ru_stickers
                  end
                end
              end
            end
          end

          layout
        end
      end
    end
  end
end
# rubocop:enable
