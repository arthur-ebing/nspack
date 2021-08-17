# frozen_string_literal: true

module UiRules
  class ColourPercentageRule < Base
    def generate_rules
      @repo = MasterfilesApp::CommodityRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode
      form_name 'colour_percentage'
    end

    def set_show_fields
      commodity_id_label = @repo.get(:commodities, @form_object.commodity_id, :code)
      fields[:commodity_id] = { renderer: :label,
                                with_value: commodity_id_label,
                                caption: 'Commodity' }
      fields[:colour_percentage] = { renderer: :label }
      fields[:description] = { renderer: :label }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      commodity_id = @options[:commodity_id] || @repo.get(:colour_percentages, @options[:id], :commodity_id)
      commodity_id_label = @repo.get(:commodities, commodity_id, :code)
      {
        commodity_code: { renderer: :label,
                          with_value: commodity_id_label,
                          caption: 'Commodity',
                          readonly: true },
        commodity_id: { renderer: :hidden,
                        value: commodity_id },
        colour_percentage: {},
        description: { required: true }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_colour_percentage(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(commodity_id: @options[:commodity_id],
                                    colour_percentage: nil,
                                    description: nil)
    end
  end
end
