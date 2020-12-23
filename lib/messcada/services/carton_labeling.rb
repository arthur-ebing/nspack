# frozen_string_literal: true

module MesscadaApp
  class CartonLabeling < BaseService # rubocop:disable Metrics/ClassLength
    attr_reader :repo, :hr_repo, :production_run_id, :setup_data, :carton_label_id, :pick_ref,
                :pallet_number, :personnel_number, :params, :system_resource, :bin_attrs

    def initialize(params)
      @params = params
      @repo = MesscadaApp::MesscadaRepo.new
      @hr_repo = MesscadaApp::HrRepo.new
      @system_resource = params[:system_resource]
    end

    def call
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

    def carton_labeling  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      res = retrieve_resource_cached_setup_data
      return res unless res.success

      attrs = setup_data[:production_run_data].merge(setup_data[:setup_data]).reject { |k, _| k == :id }
      @pick_ref = UtilityFunctions.calculate_pick_ref(packhouse_no)
      attrs = attrs.merge(pick_ref: pick_ref)
      @personnel_number = nil

      if system_resource.group_incentive
        # Group incentive
        attrs = attrs.merge(group_incentive_id: system_resource.group_incentive_id)
      elsif system_resource.login
        # individual incentive
        @personnel_number = hr_repo.contract_worker_personnel_number(system_resource.contract_worker_id)
        attrs = attrs.merge(personnel_identifier_id: system_resource.personnel_identifier_id,
                            contract_worker_id: system_resource.contract_worker_id)
      end

      attrs = attrs.merge(resolve_marketing_attrs) if AppConst::USE_MARKETING_PUC

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

    def resolve_marketing_attrs
      farm_id = params[:bin_number].nil_or_empty? ? setup_data[:production_run_data][:farm_id] : find_bin_farm

      marketing_puc_id = marketing_puc(farm_id)
      attrs = { farm_id: farm_id,
                marketing_puc_id: marketing_puc_id,
                marketing_orchard_id: marketing_orchard(marketing_puc_id) }
      attrs = attrs.merge(bin_attrs) unless bin_attrs.nil_or_empty?
      attrs
    end

    def find_bin_farm
      res = validate_dp_bin
      return res unless res.success

      repo.find_rmt_bin_farm(bin_attrs[:rmt_bin_id])
    end

    def validate_dp_bin
      rmt_bin = repo.find_rmt_bin_by_bin_number(params[:bin_number])
      raise Crossbeams::InfoError, "DP Bin #{rmt_bin} not found" unless rmt_bin_exists?(rmt_bin)

      @bin_attrs = { rmt_bin_id: rmt_bin, dp_carton: true }

      ok_response
    end

    def rmt_bin_exists?(rmt_bin)
      repo.rmt_bin_exists?(rmt_bin)
    end

    def marketing_puc(farm_id)
      repo.find_marketing_puc(setup_data[:production_run_data][:marketing_org_party_role_id], farm_id)
    end

    def marketing_orchard(marketing_puc_id)
      repo.find_marketing_orchard(marketing_puc_id, setup_data[:production_run_data][:cultivar_id])
    end

    def retrieve_resource_cached_setup_data
      @setup_data = search_cache_files
      raise Crossbeams::InfoError, "No setup data cached for resource #{system_resource[:packpoint]}." if setup_data.empty?

      @production_run_id = setup_data[:production_run_data][:production_run_id]
      raise Crossbeams::InfoError, "Production Run:#{production_run_id} could not be found" unless production_run_exists?

      ok_response
    end

    def search_cache_files
      cache_files = File.join(AppConst::LABELING_CACHED_DATA_FILEPATH, 'line_*.yml')
      Dir.glob(cache_files).each do |f|
        next unless File.file?(f)

        file_data = yaml_data_from_file(f)
        next unless file_data

        return file_data[system_resource[:packpoint]] unless file_data.empty? || file_data[system_resource[:packpoint]].nil?
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
