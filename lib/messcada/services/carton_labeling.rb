# frozen_string_literal: true

module MesscadaApp
  class CartonLabeling < BaseService # rubocop:disable Metrics/ClassLength
    attr_reader :repo, :hr_repo, :production_run_id, :setup_data, :carton_label_id, :pick_ref,
                :pallet_number, :personnel_number, :params, :incentivised_labeling

    def initialize(params)
      @params = params
      @repo = MesscadaApp::MesscadaRepo.new
      @hr_repo = MesscadaApp::HrRepo.new
      @incentivised_labeling = AppConst::INCENTIVISED_LABELING
    end

    def call
      if incentivised_labeling && params[:system_resource][:group_incentive]
        res = validate_packer_incentive_group_combination
        return res unless res.success
      end

      res = carton_labeling
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      success_response('Carton Label printed successfully', print_command)
    end

    private

    # Built-in functions
    def iso_day
      Date.today.strftime('%j')
    end

    def iso_week
      Date.today.strftime('%V')
    end

    def iso_week_day
      Date.today.strftime('%u')
    end

    def current_date
      Date.today.strftime('%Y-%m-%d')
    end

    def print_command # rubocop:disable Metrics/AbcSize
      setup_data[:print_command]
        .gsub('$:carton_label_id$', carton_label_id.to_s)
        .gsub('$:pick_ref$', pick_ref.to_s)
        .gsub('$:pallet_number$', pallet_number.to_s)
        .gsub('$:personnel_number$', personnel_number.to_s)
        .gsub('$:FNC:iso_day$', iso_day)
        .gsub('$:FNC:iso_week$', iso_week)
        .gsub('$:FNC:iso_week_day$', iso_week_day)
        .gsub('$:FNC:current_date$', current_date)
    end

    def validate_packer_incentive_group_combination  # rubocop:disable Metrics/AbcSize
      contract_worker = hr_repo.contract_worker_name(params[:identifier])
      packer_belongs_to_group = hr_repo.packer_belongs_to_incentive_group?(params[:system_resource][:group_incentive_id], params[:system_resource][:contract_worker_id])
      raise Crossbeams::InfoError, "No active incentive group for resource #{params[:device]} and contract worker #{contract_worker}" unless packer_belongs_to_group

      ok_response
    end

    def carton_labeling  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
      res = retrieve_resource_cached_setup_data
      return res unless res.success

      attrs = setup_data[:production_run_data].merge(setup_data[:setup_data]).reject { |k, _| k == :id }
      @pick_ref = UtilityFunctions.calculate_pick_ref(packhouse_no)
      attrs = attrs.merge(pick_ref: pick_ref)
      @personnel_number = nil

      if incentivised_labeling
        @personnel_number = hr_repo.contract_worker_personnel_number(params[:system_resource][:contract_worker_id])
        attrs = attrs.merge(personnel_identifier_id: params[:system_resource][:personnel_identifier_id],
                            contract_worker_id: params[:system_resource][:contract_worker_id])
        attrs = attrs.merge(group_incentive_id: params[:system_resource][:group_incentive_id]) if params[:system_resource][:group_incentive]
      end

      if AppConst::USE_MARKETING_PUC
        marketing_puc_id = marketing_puc
        attrs = attrs.merge(marketing_puc_id: marketing_puc_id, marketing_orchard_id: marketing_orchard(marketing_puc_id))
      end

      res = validate_carton_label_params(attrs)
      return validation_failed_response(res) if res.failure?

      res = create_carton_label(res)
      return res unless res.success

      ok_response
    end

    def packhouse_no
      repo.find_resource_packhouse_no(setup_data[:production_run_data][:packhouse_resource_id])
    end

    def phc
      repo.find_resource_phc(setup_data[:production_run_data][:production_line_id]) || repo.find_resource_phc(setup_data[:production_run_data][:packhouse_resource_id])
    end

    def marketing_puc
      repo.find_marketing_puc(setup_data[:production_run_data][:marketing_org_party_role_id], setup_data[:production_run_data][:farm_id])
    end

    def marketing_orchard(marketing_puc_id)
      repo.find_marketing_orchard(marketing_puc_id, setup_data[:production_run_data][:cultivar_id])
    end

    def retrieve_resource_cached_setup_data
      @setup_data = search_cache_files
      raise Crossbeams::InfoError, "No setup data cached for resource #{params[:device]}." if setup_data.empty?

      # return failed_response("No setup data cached for resource #{resource_code}.") if setup_data.empty?

      @production_run_id = setup_data[:production_run_data][:production_run_id]
      raise Crossbeams::InfoError, "Production Run:#{production_run_id} could not be found" unless production_run_exists?

      # return failed_response("Production Run:#{production_run_id} could not be found") unless production_run_exists?

      ok_response
    end

    def search_cache_files
      cache_files = File.join(AppConst::LABELING_CACHED_DATA_FILEPATH, 'line_*.yml')
      Dir.glob(cache_files).each do |f|
        next unless File.file?(f)

        file_data = yaml_data_from_file(f)
        next unless file_data

        return file_data[params[:device]] unless file_data.empty? || file_data[params[:device]].nil?
      end

      {}
    end

    # Read with a shared lock to prevent read while file is being written.
    def yaml_data_from_file(file)
      data = nil
      File.open(file, 'r') do |f|
        f.flock(File::LOCK_SH)
        data = YAML.load(f.read) # rubocop:disable Security/YAMLLoad
      end
      data
    end

    def production_run_exists?
      repo.production_run_exists?(production_run_id)
    end

    def validate_carton_label_params(params)
      # CartonLabelSchema.call(params)
      contract = CartonLabelContract.new
      contract.call(params)
    end

    def create_carton_label(params) # rubocop:disable Metrics/AbcSize
      attrs = params.to_h
      treatment_ids = attrs.delete(:treatment_ids)
      attrs = attrs.merge(treatment_ids: "{#{treatment_ids.join(',')}}") unless treatment_ids.nil?

      repo.transaction do
        @carton_label_id = repo.create_carton_label(attrs.merge(carton_equals_pallet: AppConst::CARTON_EQUALS_PALLET, phc: phc))
      end

      @pallet_number = repo.carton_label_pallet_number(carton_label_id)

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end
  end
end
