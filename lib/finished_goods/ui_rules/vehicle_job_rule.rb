# frozen_string_literal: true

module UiRules
  class VehicleJobRule < Base
    def generate_rules
      @repo = FinishedGoodsApp::GovtInspectionRepo.new
      make_form_object
      apply_form_values

      set_show_fields if %i[show reopen].include? @mode

      form_name 'vehicle_job'
    end

    def set_show_fields
      fields[:pallets] = { renderer: :list,
                           items: @form_object[:pallets],
                           scroll_height: :medium,
                           filled_background: true }
    end

    def make_form_object
      @form_object = @repo.find_vehicle_job(@options[:id]).to_h.merge(pallets: @repo.get_vehicle_jobs_pallets(@options[:id]))
    end
  end
end
