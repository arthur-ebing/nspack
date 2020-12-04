# frozen_string_literal: true

module Production
  module ProductSetups
    module ProductSetup
      class Show
        def self.call(id, back_url: nil)  # rubocop:disable Metrics/AbcSize
          ui_rule = UiRules::Compiler.new(:product_setup, :show, id: id)
          rules   = ui_rule.compile

          pm_boms_products = ProductionApp::ProductSetupRepo.new.pm_boms_products(id)

          layout = Crossbeams::Layout::Page.build(rules) do |page| # rubocop:disable Metrics/BlockLength
            page.form_object ui_rule.form_object
            page.section do |section|
              section.add_control(control_type: :link,
                                  text: 'Back',
                                  url: back_url,
                                  style: :back_button)
            end
            page.form do |form| # rubocop:disable Metrics/BlockLength
              # form.caption 'Product Setup'
              form.view_only!
              form.no_submit!
              form.row do |row|
                row.column do |col|
                  col.add_field :product_setup_template_id
                  col.add_field :cultivar_group
                  col.add_field :cultivar
                end
              end
              form.row do |row|
                row.column do |col|
                  col.expand_collapse button: true, mini: false
                end
              end
              form.row do |row| # rubocop:disable Metrics/BlockLength
                row.column do |col|
                  col.fold_up do |fold|
                    fold.caption 'Fruit details'
                    fold.add_field :commodity_id
                    fold.add_field :marketing_variety_id
                    fold.add_field :std_fruit_size_count_id
                    fold.add_field :basic_pack_code_id
                    fold.add_field :fruit_actual_counts_for_pack_id
                    fold.add_field :standard_pack_code_id
                    fold.add_field :fruit_size_reference_id
                    fold.add_field :grade_id
                  end
                end
                row.column do |col|
                  col.fold_up do |fold|
                    fold.caption 'Marketing details'
                    fold.add_field :marketing_org_party_role_id
                    fold.add_field :packed_tm_group_id
                    fold.add_field :target_market_id
                    fold.add_field :sell_by_code
                    fold.add_field :mark_id
                    fold.add_field :pm_mark_id
                    fold.add_field :product_chars
                    fold.add_field :inventory_code_id
                    fold.add_field :customer_variety_id
                    fold.add_field :client_product_code
                    fold.add_field :client_size_reference
                    fold.add_field :marketing_order_number
                  end
                end
              end
              form.row do |row|
                row.column do |col|
                  col.fold_up do |fold|
                    fold.caption 'Packaging details'
                    fold.add_field :pallet_base_id
                    fold.add_field :pallet_stack_type_id
                    fold.add_field :pallet_format_id
                    fold.add_field :pallet_label_name
                    fold.add_field :cartons_per_pallet_id
                    fold.add_field :pm_bom_id
                    fold.add_field :description
                    fold.add_field :erp_bom_code
                    fold.add_table pm_boms_products,
                                   %i[product_code pm_type_code subtype_code uom_code quantity],
                                   dom_id: 'product_setup_pm_boms_products',
                                   alignment: { quantity: :right },
                                   cell_transformers: { quantity: :decimal }
                  end
                end
                row.column do |col|
                  col.fold_up do |fold|
                    fold.caption 'Treatment Details'
                    fold.add_field :treatment_ids
                  end
                end
              end
              # form.fold_up do |fold|
              #   fold.caption 'Custom fields'
              #   fold.add_field :extended_columns
              # end
              form.row do |row|
                row.column do |col|
                  col.add_field :active
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
