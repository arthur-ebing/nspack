# frozen_string_literal: true

module MesscadaApp
  class BatchPrintCartonLabels < BaseService
    attr_reader :repo, :production_run_id, :product_setup_id,
                :label_name, :printer_id, :no_of_prints, :run_repo, :label_template_id

    def initialize(production_run_id, product_setup_id, label_template_id, params)
      @production_run_id = production_run_id
      @product_setup_id = product_setup_id
      @no_of_prints = params[:no_of_prints]
      @printer_id = params[:printer]
      @label_template_id = label_template_id
      @repo = MesscadaApp::MesscadaRepo.new
      @label_name = repo.get(:label_templates, label_template_id, :label_template_name)
    end

    def call
      attrs = prepare_carton_label_record

      repo.transaction do
        ids = repo.create_carton_labels(no_of_prints, attrs)
        Job::BatchPrintCartonLabels.enqueue(attrs[:packhouse_resource_id], ids, label_template_id, printer_id)
      end
      ok_response
    end

    EXCLUDE_PROD_SET_COLS = %i[created_at updated_at id active product_setup_template_id pallet_label_name].freeze
    INCLUDE_PROD_RUN_COLS = %i[farm_id puc_id orchard_id cultivar_group_id cultivar_id packhouse_resource_id production_line_id season_id].freeze
    # sell_by_code grade_id product_chars
    def prepare_carton_label_record
      attrs = repo.find_hash(:product_setups, product_setup_id).reject { |k, _| EXCLUDE_PROD_SET_COLS.include?(k) }
      pr = repo.find_hash(:production_runs, production_run_id).select { |k, _| INCLUDE_PROD_RUN_COLS.include?(k) }
      attrs.merge(pr).merge(production_run_id: production_run_id, label_name: label_name)
    end
  end
end
