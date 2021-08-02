# frozen_string_literal: true

module MesscadaApp
  class BatchPrintCartonLabels < BaseService
    attr_reader :repo, :production_run_id, :product_setup_id, :request_ip,
                :label_name, :printer_id, :no_of_prints, :run_repo, :label_template_id,
                :packing_specification_item_id, :production_repo

    def initialize(args, label_template_id, request_ip, params)
      @production_run_id = args[:id]
      @no_of_prints = params[:no_of_prints]
      @printer_id = params[:printer]
      @label_template_id = label_template_id
      @repo = MesscadaApp::MesscadaRepo.new
      @production_repo = ProductionApp::ProductionRunRepo.new
      @request_ip = LabelApp::PrinterRepo.new.print_to_robot?(request_ip) ? request_ip : nil
      @label_name = repo.get(:label_templates, label_template_id, :label_template_name)
      resolve_product_setup_id(args)
    end

    def resolve_product_setup_id(args)
      if AppConst::CR_PROD.use_packing_specifications?
        @packing_specification_item_id = args[:packing_specification_item_id]
        @product_setup_id = DB[:packing_specification_items].where(id: packing_specification_item_id).get(:product_setup_id)
      else
        @product_setup_id = args[:product_setup_id]
      end
    end

    def call
      attrs = prepare_carton_label_record

      repo.transaction do
        ids = repo.create_carton_labels(no_of_prints, attrs)
        args = { packhouse_resource_id: attrs[:packhouse_resource_id],
                 label_template_id: label_template_id,
                 printer_id: printer_id }
        args = args.merge(supporting_data: { packed_date: run_start_date }) unless active_run?
        Job::BatchPrintCartonLabels.enqueue(args, ids, request_ip)
      end
      ok_response
    end

    EXCLUDE_PROD_SET_COLS = %i[created_at updated_at id active product_setup_template_id pallet_label_name].freeze
    INCLUDE_PROD_RUN_COLS = %i[farm_id puc_id orchard_id cultivar_group_id cultivar_id packhouse_resource_id production_line_id season_id].freeze
    # sell_by_code grade_id product_chars
    def prepare_carton_label_record # rubocop:disable Metrics/AbcSize
      attrs = repo.find_hash(:product_setups, product_setup_id).reject { |k, _| EXCLUDE_PROD_SET_COLS.include?(k) }
      attrs[:rmt_container_material_owner_id] = repo.get_value(:standard_pack_codes, :rmt_container_material_owner_id, id: attrs[:standard_pack_code_id])
      pr = repo.find_hash(:production_runs, production_run_id).select { |k, _| INCLUDE_PROD_RUN_COLS.include?(k) }
      pr[:cultivar_id] = pr[:cultivar_id].nil_or_empty? ? production_repo.resolve_setup_cultivar_id(product_setup_id) : pr[:cultivar_id]

      phc = repo.find_resource_phc(pr[:production_line_id]) || repo.find_resource_phc(pr[:packhouse_resource_id])
      default_packing_method_id = MasterfilesApp::PackagingRepo.new.find_packing_method_by_code(AppConst::DEFAULT_PACKING_METHOD)&.id
      raise Crossbeams::FrameworkError, "Default Packing Method: #{AppConst::DEFAULT_PACKING_METHOD} does not exist." if default_packing_method_id.nil_or_empty?

      packing_spec = production_repo.packing_specification_keys(packing_specification_item_id)
      attrs.merge(pr).merge(packing_spec.to_h).merge(production_run_id: production_run_id, label_name: label_name, phc: phc, packing_method_id: default_packing_method_id)
    end

    def active_run?
      repo.active_run?(production_run_id)
    end

    def run_start_date
      repo.run_start_date(production_run_id)
    end
  end
end
