# frozen_string_literal: true

module UiRules
  class SetupStandardAndActualCountsRule < Base
    def generate_rules
      @repo = MasterfilesApp::FruitSizeRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if @mode == :grid

      form_name 'setup_counts'
    end

    def set_show_fields
      fields[:commodity_id] = { renderer: :label, with_value: @repo.get(:commodities, :code, @form_object[:commodity_id]) }
      fields[:list_of_counts] = { renderer: :label }
      fields[:standard_pack_code_id] = { renderer: :label, with_value: @repo.get(:standard_pack_codes, :standard_pack_code, @form_object[:standard_pack_code_id]) }
    end

    def common_fields
      {
        commodity_id: { renderer: :select,
                        options: MasterfilesApp::CommodityRepo.new.for_select_commodities,
                        required: true },
        list_of_counts: { required: true,
                          hint: <<~HTML },
                            <p>Provide a list of the counts that apply to this pack for this commodity.</p>
                            <p>Counts must be a comma-separated list &mdash; e.g.: <em>45,48,52,60,70,80</em>.</p>
                          HTML
        standard_pack_code_id: { renderer: :select,
                                 options: MasterfilesApp::FruitSizeRepo.new.for_select_standard_packs,
                                 required: true }
      }
    end

    def make_form_object
      make_new_form_object # && return if %i[new grid].include?(@mode)

      # @form_object = @repo.find_fruit_actual_counts_for_pack(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(commodity_id: nil,
                                    list_of_counts: nil,
                                    standard_pack_code_id: nil)
    end
  end
end
