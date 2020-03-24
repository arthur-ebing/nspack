# frozen_string_literal: true

module MesscadaApp
  class CartonLabeling < BaseService
    attr_reader :repo, :resource_code, :production_run_id, :setup_data, :carton_label_id, :pick_ref, :pallet_number, :identifier, :personnel_number

    def initialize(params)
      @resource_code = params[:device]
      @identifier = params.to_h[:identifier]
    end

    def call
      @repo = MesscadaApp::MesscadaRepo.new

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

    def carton_labeling  # rubocop:disable Metrics/AbcSize
      res = retrieve_resource_cached_setup_data
      return res unless res.success

      attrs = setup_data[:production_run_data].merge(setup_data[:setup_data]).reject { |k, _| k == :id }
      @pick_ref = UtilityFunctions.calculate_pick_ref(packhouse_no)
      attrs = attrs.merge(pick_ref: pick_ref)
      @personnel_number = nil
      unless identifier.nil_or_empty?
        hr_ids = MesscadaApp::HrRepo.new.contract_worker_ids(identifier)
        raise Crossbeams::InfoError, "Personnel identifier #{identifier} is not registered" if hr_ids.nil?

        @personnel_number = hr_ids[:personnel_number]
        attrs = attrs.merge(personnel_identifier_id: hr_ids[:personnel_identifier_id],
                            contract_worker_id: hr_ids[:contract_worker_id])
      end

      res = validate_carton_label_params(attrs)
      return validation_failed_response(res) unless res.messages.empty?

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

    def retrieve_resource_cached_setup_data
      @setup_data = search_cache_files
      raise Crossbeams::InfoError, "No setup data cached for resource #{resource_code}." if setup_data.empty?

      # return failed_response("No setup data cached for resource #{resource_code}.") if setup_data.empty?

      @production_run_id = setup_data[:production_run_data][:production_run_id]
      raise Crossbeams::InfoError, "Production Run:#{production_run_id} could not be found" unless production_run_exists?

      # return failed_response("Production Run:#{production_run_id} could not be found") unless production_run_exists?

      ok_response
    end

    def search_cache_files
      cache_files = File.join(AppConst::LABELING_CACHED_DATA_FILEPATH, 'line_*.yml')
      Dir.glob(cache_files).each do |f|
        if File.file?(f)
          file_data = YAML.load_file(f)
          return file_data[resource_code] unless file_data.empty? || file_data[resource_code].nil?
        end
      end

      {}
    end

    def production_run_exists?
      repo.production_run_exists?(production_run_id)
    end

    def validate_carton_label_params(params)
      CartonLabelSchema.call(params)
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
