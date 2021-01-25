# frozen_string_literal: true

module UiRules
  class PmBomRule < Base
    def generate_rules
      @repo = MasterfilesApp::BomRepo.new
      make_form_object
      apply_form_values

      @rules[:require_extended_packaging] = AppConst::REQUIRE_EXTENDED_PACKAGING

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode
      set_select_pm_types_fields if @mode == :select_pm_types
      set_add_products_fields if @mode == :add_products

      form_name 'pm_bom'
    end

    def set_show_fields
      fields[:bom_code] = { renderer: :label, caption: 'BOM Code' }
      fields[:erp_bom_code] = { renderer: :label, caption: 'ERP BOM Code' }
      fields[:description] = { renderer: :label }
      fields[:label_description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:system_code] = { renderer: :label }
      fields[:pm_boms_products] = { renderer: :list,
                                    items: @repo.for_select_pm_boms_products(where: { pm_bom_id: @options[:id] }),
                                    caption: 'PM BOM Products' }
      fields[:gross_weight] = { renderer: :label }
      fields[:nett_weight] = { renderer: :label }
    end

    def common_fields
      {
        bom_code: { required: true, caption: 'BOM Code' },
        erp_bom_code: { caption: 'ERP BOM Code' },
        description: {},
        label_description: {},
        system_code: { renderer: :label },
        gross_weight: { renderer: :numeric },
        nett_weight: { renderer: :numeric }
      }
    end

    def set_select_pm_types_fields
      fields[:pm_type_ids] = { renderer: :multi,
                               options: @repo.for_select_pm_types(exclude: { Sequel[:pm_products][:id] => nil }),
                               selected: @form_object[:pm_subtype_ids],
                               caption: 'PM types' }
    end

    def set_add_products_fields
      fields[:pm_subtype_ids] = { renderer: :hidden }
      fields[:pm_subtypes] = { renderer: :list,
                               items: @repo.for_select_pm_subtypes(
                                 where: { Sequel[:pm_subtypes][:id] => @options[:attrs][:pm_subtype_ids] }
                               ),
                               filled_background: true,
                               caption: 'PM Subtypes' }
    end

    def make_form_object
      if %i[new select_pm_types].include? @mode
        make_new_form_object
        return
      end

      if @mode == :add_products
        @form_object = OpenStruct.new(pm_subtype_ids: @options[:attrs][:pm_subtype_ids],
                                      selected_product_ids: @options[:attrs][:selected_product_ids])
        return
      end

      @form_object = @repo.find_pm_bom(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(bom_code: nil,
                                    erp_bom_code: nil,
                                    description: nil,
                                    label_description: nil,
                                    system_code: nil,
                                    pm_type_ids: [],
                                    pm_subtype_ids: [],
                                    gross_weight: nil,
                                    nett_weight: nil)
    end
  end
end
