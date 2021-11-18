# frozen_string_literal: true

module UiRules
  class PresortStagingRunChildRule < Base
    def generate_rules
      @repo = RawMaterialsApp::PresortStagingRunRepo.new
      make_form_object
      apply_form_values

      @rules[:parent_has_supplier] = !@repo.get_value(:presort_staging_runs, :supplier_id, id: @options[:staging_run_id]).nil?

      common_values_for_fields common_fields

      form_name 'presort_staging_run_child'
    end

    def common_fields
      {
        farm_id: { renderer: :select, options: rules[:parent_has_supplier] ? MasterfilesApp::SupplierRepo.new.for_presort_staging_run_supplier_farms(@options[:staging_run_id]) : MasterfilesApp::FarmRepo.new.for_select_farms,
                   caption: 'Farm',
                   prompt: true,
                   required: true }
      }
    end

    def make_form_object
      if @mode == :new
        make_new_form_object
        return
      end

      @form_object = @repo.find_presort_staging_run_child(@options[:id])
    end

    def make_new_form_object
      @form_object = OpenStruct.new(presort_staging_run_id: nil,
                                    completed_at: nil,
                                    staged_at: nil,
                                    canceled: nil,
                                    farm_id: nil,
                                    editing: nil,
                                    staged: nil)
    end
  end
end
