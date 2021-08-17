# frozen_string_literal: true

module UiRules
  class CommodityRule < Base
    def generate_rules
      @repo = MasterfilesApp::CommodityRepo.new
      make_form_object

      @rules[:colour_applies] = @form_object.colour_applies

      common_values_for_fields common_fields

      set_show_fields if @mode == :show

      form_name 'commodity'
    end

    def set_show_fields
      fields[:commodity_group_id] = { renderer: :label,
                                      with_value: @repo.find_commodity_group(@form_object.commodity_group_id)&.code }
      fields[:code] = { caption: 'Commodity Code', renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:hs_code] = { renderer: :label, caption: 'HS Code' }
      fields[:requires_standard_counts] = { renderer: :label, as_boolean: true }
      fields[:use_size_ref_for_edi] = { renderer: :label, as_boolean: true }
      fields[:active] = { renderer: :label, as_boolean: true }
      fields[:colour_applies] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        commodity_group_id: { renderer: :select,
                              options: @repo.for_select_commodity_groups,
                              disabled_options: @repo.for_select_inactive_commodity_groups },
        code: { caption: 'Commodity Code', required: true },
        description: { required: true },
        hs_code: { caption: 'HS code',
                   hint: 'The Harmonized System is an international nomenclature for the classification of products.
                          It allows participating countries to classify traded goods on a common basis for customs purposes.
                          At the international level, the Harmonized System (HS) for classifying goods is a six-digit code system.' },
        requires_standard_counts: { renderer: :checkbox },
        use_size_ref_for_edi: { renderer: :checkbox },
        active: { renderer: :checkbox },
        colour_applies: { renderer: :checkbox }
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @repo.find_commodity(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(commodity_group_id: nil,
                                    code: nil,
                                    description: nil,
                                    hs_code: nil,
                                    requires_standard_counts: true,
                                    use_size_ref_for_edi: nil,
                                    active: true,
                                    colour_applies: nil)
    end
  end
end
