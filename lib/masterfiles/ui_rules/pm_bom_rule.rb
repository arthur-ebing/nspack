# frozen_string_literal: true

module UiRules
  class PmBomRule < Base
    def generate_rules  # rubocop:disable Metrics/AbcSize
      @repo = MasterfilesApp::BomRepo.new
      make_form_object
      apply_form_values

      @rules[:require_extended_packaging] = AppConst::REQUIRE_EXTENDED_PACKAGING
      @rules[:pm_subtype_ids] = @form_object[:pm_subtype_ids].nil? ? [] : @form_object[:pm_subtype_ids] if %i[select_subtypes add_products].include? @mode

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode
      set_select_subtypes_fields if @mode == :select_subtypes
      set_add_products_fields if @mode == :add_products

      form_name 'pm_bom'
    end

    def set_show_fields
      fields[:bom_code] = { renderer: :label }
      fields[:erp_bom_code] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:system_code] = { renderer: :label }
      fields[:pm_boms_products] = { renderer: :list, items: pm_boms_products }
      fields[:gross_weight] = { renderer: :label }
      fields[:nett_weight] = { renderer: :label }
    end

    def common_fields
      {
        bom_code: { required: true },
        erp_bom_code: {},
        description: {},
        system_code: { renderer: :label },

        gross_weight: { renderer: :numeric },
        nett_weight: { renderer: :numeric }
      }
    end

    def set_select_subtypes_fields
      fields[:pm_subtype_ids] = { renderer: :multi,
                                  options: @repo.for_select_pm_type_subtypes,
                                  selected: @rules[:pm_subtype_ids],
                                  caption: 'Pm Subtypes' }
    end

    def set_add_products_fields
      fields[:pm_subtype_ids] = { renderer: :hidden }
      fields[:pm_subtypes] = { renderer: :list,
                               items: pm_subtypes,
                               filled_background: true,
                               caption: 'Pm Subtypes' }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      if @mode == :select_subtypes
        @form_object = OpenStruct.new(pm_subtype_ids: nil)
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
                                    system_code: nil,
                                    pm_subtype_ids: nil,
                                    gross_weight: nil,
                                    nett_weight: nil)
    end

    def pm_subtypes
      @repo.pm_subtypes(@options[:attrs][:pm_subtype_ids])
    end

    def pm_boms_products
      @repo.find_pm_bom_products(@options[:id])
    end
  end
end
