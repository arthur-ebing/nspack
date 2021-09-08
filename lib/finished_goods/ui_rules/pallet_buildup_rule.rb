# frozen_string_literal: true

module UiRules
  class PalletBuildupRule < Base
    def generate_rules
      @repo = FinishedGoodsApp::BuildupsRepo.new
      make_form_object
      apply_form_values

      common_values_for_fields common_fields

      set_show_fields if %i[show reopen].include? @mode
      # set_complete_fields if @mode == :complete
      # set_approve_fields if @mode == :approve

      # add_approve_behaviours if @mode == :approve

      form_name 'pallet_buildup'
    end

    def set_show_fields
      fields[:destination_pallet_number] = { renderer: :label, caption: 'Destination Pallet'  }
      fields[:source_pallets] = { renderer: :label }
      fields[:qty_cartons_to_move] = { renderer: :label }
      fields[:created_by] = { renderer: :label }
      fields[:completed_at] = { renderer: :label, format: :without_timezone_or_seconds }
      fields[:cartons_moved] = { renderer: :label }
      fields[:completed] = { renderer: :label, as_boolean: true }
    end

    def common_fields
      fields = {
        destination_pallet_number: { required: true },
        source_pallets: { required: true },
        qty_cartons_to_move: {},
        created_by: {},
        completed_at: {},
        cartons_moved: {},
        completed: { renderer: :checkbox }
      }

      fields
    end

    def make_form_object
      @form_object = @repo.find_pallet_buildup(@options[:id]).to_h
    end
  end
end
