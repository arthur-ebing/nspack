# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize

module UiRules
  class StdFruitSizeCountRule < Base
    def generate_rules
      @this_repo = MasterfilesApp::FruitSizeRepo.new
      @gen_repo = MasterfilesApp::GeneralRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if @mode == :show

      form_name 'std_fruit_size_count'
    end

    def set_show_fields
      fields[:commodity_code] = { renderer: :label }
      fields[:uom_code] = { renderer: :label, caption: 'Unit Of Measure' }
      fields[:size_count_description] = { renderer: :label }
      fields[:marketing_size_range_mm] = { renderer: :label, caption: 'Marketing Size Range (mm)'  }
      fields[:marketing_weight_range] = { renderer: :label, caption: 'Marketing Weight Range (g)' }
      fields[:size_count_interval_group] = { renderer: :label }
      fields[:size_count_value] = { renderer: :label }
      fields[:minimum_size_mm] = { renderer: :label, caption: 'Minimum Size (mm)' }
      fields[:maximum_size_mm] = { renderer: :label, caption: 'Maximum Size (mm)' }
      fields[:average_size_mm] = { renderer: :label, caption: 'Average Size (mm)' }
      fields[:minimum_weight_gm] = { renderer: :label, caption: 'Minimum Weight (g)' }
      fields[:maximum_weight_gm] = { renderer: :label, caption: 'Maximum Weight (g)' }
      fields[:average_weight_gm] = { renderer: :label, caption: 'Average Weight (g)' }
      fields[:active] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        commodity_id: { renderer: :select,
                        options: MasterfilesApp::CommodityRepo.new.for_select_commodities,
                        disabled_options: MasterfilesApp::CommodityRepo.new.for_select_inactive_commodities,
                        required: true  },
        uom_id: { renderer: :select,
                  options: @gen_repo.for_select_uoms(where: { code: AppConst::UOM_TYPE }),
                  disabled_options: @gen_repo.for_select_inactive_uoms,
                  caption: 'Unit of Measure',
                  required: true  },
        size_count_description: {},
        marketing_size_range_mm: { caption: 'Marketing Size Range (mm)' },
        marketing_weight_range: { caption: 'Marketing Weight Range (g)' },
        size_count_interval_group: {},
        size_count_value: { required: true },
        minimum_size_mm: { caption: 'Minimum Size (mm)' },
        maximum_size_mm: { caption: 'Maximum Size (mm)' },
        average_size_mm: { caption: 'Average Size (mm)' },
        minimum_weight_gm: { caption: 'Minimum Weight (g)' },
        maximum_weight_gm: { caption: 'Maximum Weight (g)' },
        average_weight_gm: { caption: 'Average Weight (g)' }
      }
    end

    def make_form_object
      make_new_form_object && return if @mode == :new

      @form_object = @this_repo.find_std_fruit_size_count(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(commodity_id: nil,
                                    uom_id: nil,
                                    size_count_description: nil,
                                    marketing_size_range_mm: nil,
                                    marketing_weight_range: nil,
                                    size_count_interval_group: nil,
                                    size_count_value: nil,
                                    minimum_size_mm: nil,
                                    maximum_size_mm: nil,
                                    average_size_mm: nil,
                                    minimum_weight_gm: nil,
                                    maximum_weight_gm: nil,
                                    average_weight_gm: nil)
    end
  end
end
# rubocop:enable Metrics/AbcSize
