# frozen_string_literal: true

module UiRules
  class PalletHoldoverRule < Base
    def generate_rules
      @repo = FinishedGoodsApp::PalletHoldoverRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show].include? @mode

      form_name 'pallet_holdover'
    end

    def set_show_fields
      fields[:pallet_id] = { renderer: :label,
                             with_value: @form_object.pallet_number,
                             caption: 'Pallet',
                             hide_on_load: @form_object.pallet_number.nil? }
      fields[:holdover_quantity] = { renderer: :label }
      fields[:buildup_remarks] = { renderer: :label }
      fields[:completed] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      {
        pallet_id: { renderer: :label,
                     with_value: @form_object.pallet_number,
                     include_hidden_field: true,
                     hidden_value: @form_object.pallet_id,
                     caption: 'Pallet',
                     hide_on_load: @form_object.pallet_number.nil? },
        holdover_quantity: { renderer: :number,
                             required: true },
        buildup_remarks: { required: true },
        completed: { renderer: :checkbox }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_pallet_holdover(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(pallet_id: nil,
                                    holdover_quantity: nil,
                                    buildup_remarks: nil,
                                    completed: nil)
    end
  end
end
