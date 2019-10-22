# frozen_string_literal: true

module MesscadaApp
  class CartonLabeling < BaseService
    attr_reader :repo, :resource_code, :production_run_id, :setup_data, :label_name

    def initialize(params)
      @resource_code = params[:device]
    end

    def call
      @repo = MesscadaApp::MesscadaRepo.new

      res = retrieve_cached_setup_data
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      carton_labeling
    end

    private

    def retrieve_cached_setup_data # rubocop:disable Metrics/AbcSize
      file_data = JSON.parse(File.read(AppConst::LABELING_CACHED_DATA_FILEPATH))
      return failed_response('File does not have any setup data cached.') if file_data.empty?
      return failed_response("No setup data cached for resource #{resource_code}.") if file_data[resource_code].nil?

      @production_run_id = file_data[resource_code].keys.first
      return failed_response("No active production run setup data cached for resource #{resource_code}.") if production_run_id.nil?
      return failed_response("Production Run:#{production_run_id} could not be found") unless production_run_exists?
      return failed_response("No setup data cached for resource #{resource_code} and production_run_id #{production_run_id}.") if file_data[resource_code][production_run_id].nil?

      @setup_data = file_data[resource_code][production_run_id]

      ok_response
    end

    def production_run_exists?
      repo.production_run_exists?(production_run_id)
    end

    def carton_labeling  # rubocop:disable Metrics/AbcSize
      attrs = setup_data['production_run_data'].merge(setup_data['setup_data'])
      res = validate_carton_label_params(attrs)
      return validation_failed_response(res) unless res.messages.empty?

      @label_name = res[:label_name]

      repo.transaction do
        res = create_carton_label(res)
        return res unless res.success

        carton_label_printing
      end
    end

    def validate_carton_label_params(params)
      CartonLabelSchema.call(params)
    end

    def create_carton_label(params)
      attrs = params.to_h
      treatment_ids = attrs.delete(:treatment_ids)
      attrs = attrs.merge(treatment_ids: "{#{treatment_ids.join(',')}}") unless treatment_ids.nil?

      begin
        repo.transaction do
          repo.create_carton_label(attrs)
          # ProductionApp::RunStatsUpdateJob.enqueue(production_run_id, 'CARTON_LABEL_PRINTED')
        end
      rescue StandardError
        return failed_response($ERROR_INFO)
      end
      ok_response
    end

    def carton_label_printing
      print_command = resolve_print_command(setup_data['print_command'])
      atrs = {
        label_name: label_name,
        print_command: print_command
      }
      success_response('Carton Label printed successfully', atrs)
    end

    def resolve_print_command(print_command)
      fvalue_regex = /F\d=/i
      print_commands = (print_command || '').split(fvalue_regex).collect(&:strip).compact.reject(&:empty?)
      fvalue_body = []
      print_commands.each do |fvalue|
        fvalue_body << "<fvalue>#{fvalue}</fvalue>\r"
      end
      fvalue_body.join(' ')
    end
  end
end
