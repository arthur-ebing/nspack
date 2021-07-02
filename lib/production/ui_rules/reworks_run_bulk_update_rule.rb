# frozen_string_literal: true

module UiRules
  class ReworksRunBulkUpdateRule < Base
    def generate_rules
      @repo = ProductionApp::ReworksRepo.new

      make_form_object
      apply_form_values

      set_production_run_bulk_update_fields if @mode == :production_run_bulk_update

      form_name 'reworks_run_bulk_update'
    end

    def set_production_run_bulk_update_fields # rubocop:disable Metrics/AbcSize
      reworks_run_type_id_label = @repo.find_hash(:reworks_run_types, @form_object.reworks_run_type_id)[:run_type]
      @rules[:bulk_pallet_run_update] = AppConst::RUN_TYPE_BULK_PRODUCTION_RUN_UPDATE == reworks_run_type_id_label
      @rules[:bulk_bin_run_update] = AppConst::RUN_TYPE_BULK_BIN_RUN_UPDATE == reworks_run_type_id_label
      @rules[:bulk_production_run_update] = @rules[:bulk_pallet_run_update] || @rules[:bulk_bin_run_update]

      fields[:reworks_run_type_id] = { renderer: :hidden }
      fields[:reworks_run_type] = { renderer: :label,
                                    with_value: reworks_run_type_id_label,
                                    caption: 'Reworks Run Type' }
      fields[:pallets_selected] = { renderer: :hidden }
      fields[:from_production_run_id] = { renderer: :hidden }
      fields[:to_production_run_id] = { renderer: :hidden }

      fields[:changes_made] = {
        left_caption: 'Before',
        right_caption: 'After',
        left_record: production_run(@form_object.from_production_run_id).sort.to_h,
        right_record: production_run(@form_object.to_production_run_id).sort.to_h
      }
    end

    def make_form_object
      @form_object = OpenStruct.new(reworks_run_type_id: @options[:id],
                                    from_production_run_id: @options[:attrs][:from_production_run_id],
                                    to_production_run_id: @options[:attrs][:to_production_run_id],
                                    pallets_selected: @options[:attrs][:pallets_selected],
                                    params: @options[:attrs])
    end

    def production_run(id)
      @repo.production_run_details(id)[0]
    end
  end
end
