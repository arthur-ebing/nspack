# frozen_string_literal: true

module UiRules
  class OrderItemRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules
      @repo = FinishedGoodsApp::OrderRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields unless %i[show].include? @mode

      set_show_fields if %i[show].include? @mode
      add_behaviours
      form_name 'order_item'
    end

    def set_show_fields # rubocop:disable Metrics/AbcSize
      fields[:order_id] = { renderer: :label }
      fields[:load_id] = { renderer: :label }
      fields[:commodity] = { renderer: :label }
      fields[:basic_pack] = { renderer: :label }
      fields[:standard_pack] = { renderer: :label }
      fields[:actual_count] = { renderer: :label }
      fields[:size_reference] = { renderer: :label }
      fields[:grade] = { renderer: :label }
      fields[:mark] = { renderer: :label }
      fields[:marketing_variety] = { renderer: :label }
      fields[:inventory] = { renderer: :label }
      fields[:carton_quantity] = { renderer: :label }
      fields[:price_per_carton] = { renderer: :label }
      fields[:price_per_kg] = { renderer: :label }
      fields[:sell_by_code] = { renderer: :label }
      fields[:pallet_format] = { renderer: :label }
      fields[:pkg_mark] = { renderer: :label,
                            caption: 'PKG Mark' }
      fields[:pkg_bom] = { renderer: :label,
                           caption: 'PKG BOM' }
      fields[:rmt_class] = { renderer: :label,
                             caption: 'RMT Class' }
      fields[:treatment] = { renderer: :label, hide_on_load: true }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields # rubocop:disable Metrics/AbcSize
      {
        order_id: { renderer: :select,
                    options: FinishedGoodsApp::OrderRepo.new.for_select_orders,
                    disabled_options: FinishedGoodsApp::OrderRepo.new.for_select_inactive_orders,
                    caption: 'Order',
                    hide_on_load: true,
                    required: true },
        load_id: { renderer: :select,
                   options: FinishedGoodsApp::LoadRepo.new.for_select_loads(
                     where: { order_id: @form_object.order_id },
                     active: true
                   ),
                   disabled_options: FinishedGoodsApp::LoadRepo.new.for_select_loads(active: false),
                   caption: 'Load',
                   required: true },
        commodity_id: { renderer: :select,
                        options: MasterfilesApp::CommodityRepo.new.for_select_commodities,
                        disabled_options: MasterfilesApp::CommodityRepo.new.for_select_inactive_commodities,
                        caption: 'Commodity',
                        required: true,
                        prompt: true },
        basic_pack_id: { renderer: :select,
                         options: MasterfilesApp::FruitSizeRepo.new.for_select_basic_packs,
                         disabled_options: MasterfilesApp::FruitSizeRepo.new.for_select_inactive_basic_packs,
                         caption: 'Basic Pack',
                         required: true,
                         prompt: true },
        standard_pack_id: { renderer: :select,
                            options: MasterfilesApp::FruitSizeRepo.new.for_select_standard_packs(
                              where: { basic_pack_id: @form_object.basic_pack_id }
                            ),
                            disabled_options: MasterfilesApp::FruitSizeRepo.new.for_select_inactive_standard_packs,
                            caption: 'Standard Pack',
                            required: true,
                            prompt: true },
        actual_count_id: { renderer: :select,
                           options: MasterfilesApp::FruitSizeRepo.new.for_select_fruit_actual_counts_for_packs(
                             where: { basic_pack_code_id: @form_object.basic_pack_id }
                           ),
                           disabled_options: MasterfilesApp::FruitSizeRepo.new.for_select_inactive_fruit_actual_counts_for_packs,
                           caption: 'Actual Count',
                           required: true,
                           prompt: true },
        size_reference_id: { renderer: :select,
                             options: MasterfilesApp::FruitSizeRepo.new.for_select_fruit_size_references,
                             disabled_options: MasterfilesApp::FruitSizeRepo.new.for_select_inactive_fruit_size_references,
                             caption: 'Size Reference',
                             prompt: true },
        grade_id: { renderer: :select,
                    options: MasterfilesApp::FruitRepo.new.for_select_grades,
                    disabled_options: MasterfilesApp::FruitRepo.new.for_select_inactive_grades,
                    caption: 'Grade',
                    required: true,
                    prompt: true },
        mark_id: { renderer: :select,
                   options: MasterfilesApp::MarketingRepo.new.for_select_marks,
                   disabled_options: MasterfilesApp::MarketingRepo.new.for_select_inactive_marks,
                   caption: 'Mark',
                   required: true,
                   prompt: true },
        marketing_variety_id: { renderer: :select,
                                options: MasterfilesApp::CultivarRepo.new.for_select_marketing_varieties,
                                disabled_options: MasterfilesApp::CultivarRepo.new.for_select_inactive_marketing_varieties,
                                caption: 'Marketing Variety',
                                required: true,
                                prompt: true },
        inventory_id: { renderer: :select,
                        options: MasterfilesApp::FruitRepo.new.for_select_inventory_codes,
                        disabled_options: MasterfilesApp::FruitRepo.new.for_select_inactive_inventory_codes,
                        caption: 'Inventory Code',
                        prompt: true },
        carton_quantity: { required: true },
        price_per_carton: {},
        price_per_kg: {},
        sell_by_code: {},
        pallet_format_id: { renderer: :select,
                            options: MasterfilesApp::PackagingRepo.new.for_select_pallet_formats,
                            disabled_options: MasterfilesApp::PackagingRepo.new.for_select_inactive_pallet_formats,
                            caption: 'Pallet Format',
                            prompt: true },
        pm_mark_id: { renderer: :select,
                      options: MasterfilesApp::BomRepo.new.for_select_pm_marks,
                      disabled_options: MasterfilesApp::BomRepo.new.for_select_inactive_pm_marks,
                      caption: 'PKG Mark',
                      prompt: true },
        pm_bom_id: { renderer: :select,
                     options: MasterfilesApp::BomRepo.new.for_select_pm_boms,
                     disabled_options: MasterfilesApp::BomRepo.new.for_select_inactive_pm_boms,
                     caption: 'PKG BOM',
                     prompt: true },
        rmt_class_id: { renderer: :select,
                        options: MasterfilesApp::FruitRepo.new.for_select_rmt_classes,
                        disabled_options: MasterfilesApp::FruitRepo.new.for_select_inactive_rmt_classes,
                        caption: 'RMT Class',
                        prompt: true },
        treatment_id: { renderer: :select,
                        options: MasterfilesApp::FruitRepo.new.for_select_treatments,
                        disabled_options: MasterfilesApp::FruitRepo.new.for_select_inactive_treatments,
                        caption: 'Treatment',
                        hide_on_load: true,
                        prompt: true }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_order_item(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(order_id: nil,
                                    commodity_id: nil,
                                    basic_pack_id: nil,
                                    standard_pack_id: nil,
                                    actual_count_id: nil,
                                    size_reference_id: nil,
                                    grade_id: nil,
                                    mark_id: nil,
                                    marketing_variety_id: nil,
                                    inventory_id: nil,
                                    carton_quantity: nil,
                                    price_per_carton: nil,
                                    price_per_kg: nil,
                                    sell_by_code: nil,
                                    pallet_format_id: nil,
                                    pm_mark_id: nil,
                                    pm_bom_id: nil,
                                    rmt_class_id: nil,
                                    treatment_id: nil)
    end

    def handle_behaviour
      changed = {
        basic_pack: :basic_pack_changed
      }
      changed = changed[@options[:field]]
      return unhandled_behaviour! if changed.nil?

      send(changed)
    end

    private

    def add_behaviours
      url = "/finished_goods/orders/order_items/change/#{@mode}"
      behaviours do |behaviour|
        behaviour.dropdown_change :basic_pack_id, notify: [{ url: "#{url}/basic_pack" }]
      end
    end

    def basic_pack_changed
      form_object_merge!(params)
      @form_object[:basic_pack_id] = params[:changed_value].to_i
      fields = common_fields

      json_actions([OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'order_item_standard_pack_id',
                                   options_array: fields[:standard_pack_id][:options]),
                    OpenStruct.new(type: :replace_select_options,
                                   dom_id: 'order_item_actual_count_id',
                                   options_array: fields[:actual_count_id][:options])])
    end
  end
end
