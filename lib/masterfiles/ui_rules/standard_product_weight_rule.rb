# frozen_string_literal: true

module UiRules
  class StandardProductWeightRule < Base
    def generate_rules
      @repo = MasterfilesApp::FruitSizeRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode

      form_name 'standard_product_weight'
    end

    def set_show_fields
      fields[:commodity_code] = { renderer: :label }
      fields[:standard_pack_code] = { renderer: :label }
      fields[:gross_weight] = { renderer: :label,
                                caption: 'Gross Weight (kg)' }
      fields[:nett_weight] = { renderer: :label,
                               caption: 'Nett Weight (kg)' }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:standard_carton_nett_weight] = { renderer: :label,
                                               caption: 'Standard Carton Nett Weight (kg)' }
      fields[:ratio_to_standard_carton] = { renderer: :label }
      fields[:is_standard_carton] = { renderer: :label, as_boolean: true }
      fields[:min_gross_weight] = { renderer: :label }
      fields[:max_gross_weight] = { renderer: :label }
    end

    def common_fields
      {
        commodity_id: { renderer: :select,
                        options: MasterfilesApp::CommodityRepo.new.for_select_commodities,
                        disabled_options: MasterfilesApp::CommodityRepo.new.for_select_inactive_commodities,
                        caption: 'Commodity Code',
                        required: true },
        standard_pack_id: { renderer: :select,
                            options: @repo.for_select_standard_packs,
                            disabled_options: @repo.for_select_inactive_standard_packs,
                            caption: 'Standard Pack Code',
                            required: true },
        gross_weight: { renderer: :numeric,
                        caption: 'Gross Weight (kg)',
                        required: true },
        nett_weight: { renderer: :numeric,
                       caption: 'Nett Weight (kg)',
                       required: true },
        is_standard_carton: { renderer: :checkbox,
                              hint: 'Sets the selected standard pack code as the standard for the commodity, <br>
                                     i.e. it is the implied packaging of any standard size count of the same commodity.' },
        standard_carton_nett_weight: {
          renderer: :numeric,
          caption: 'Standard Carton Nett Weight (kg)',
          hint: "This weight is only used for the calculation of standard cartons. <br>
                Standard cartons for any pallet is calculated as follows: <br>
                <blockquote>
                  <em>carton quantity</em> &times; (<em>standard nett weight</em> of the commodity's <em>standard pack</em>) <br>
                  &divide; (<em>standard carton nett weight</em> of the <em>standard pack</em> of the pallet)
                </blockquote>"
        },
        ratio_to_standard_carton: { renderer: :numeric },
        min_gross_weight: { renderer: :numeric },
        max_gross_weight: { renderer: :numeric }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_standard_product_weight(@options[:id])
    end

    def make_new_form_object
      @form_object = new_form_object_from_struct(MasterfilesApp::StandardProductWeight)
    end
  end
end
