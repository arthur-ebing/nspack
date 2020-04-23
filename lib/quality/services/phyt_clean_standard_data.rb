# frozen_string_literal: true

module QualityApp
  class PhytCleanStandardData < BaseService
    attr_reader :repo, :api, :season_id
    attr_accessor :params, :glossary

    def initialize
      @repo = OrchardTestRepo.new
      @api = PhytCleanApi.new
      @season_id = AppConst::PHYT_CLEAN_SEASON_ID
      @params = {}
      @glossary = {}
    end

    def call # rubocop:disable Metrics/AbcSize
      raise ArgumentError, 'PhytClean Season not set' if season_id.nil?

      res = api.auth_token_call
      return failed_response(res.message) unless res.success

      repo.select_values(:pallet_sequences, :puc_id).uniq.each do |puc_id|
        res = api.request_phyt_clean_standard_data(season_id, puc_id)
        return failed_response(res.message) unless res.success

        parse_standard_data(res)

        update_orchard_tests
      end

      success_response(res.message)
    end

    private

    def parse_standard_data(res) # rubocop:disable Metrics/AbcSize
      head = res.instance['season']
      params[:season_name] = head['seasonName']
      puc = head['fbo'].first
      params[:puc_code] = puc['code']
      params[:orchards] = []
      orchards = puc['orchard']
      orchards.each do |orchard|
        orchard_args = {}
        orchard_args[:puc_code] = puc['code']
        orchard_args[:orchard_code] = orchard['name']
        orchard_args[:cultivar_code] = orchard['cultivarCode']
        orchard_attrs = {}
        calculated_data = orchard['calculateddata'].first['cd']
        calculated_data.each do |data|
          orchard_attrs[data['name'].to_sym] = data['value']
        end
        control_point_groups = orchard['controlpointgroups'].first['cpg']
        control_point_groups.each do |group|
          control_points = group['controlpoints'].first['cp']
          control_points.each do |point|
            point_params = point['params'].first['p']
            point_params.each do |point_param|
              orchard_attrs[point_param['name'].downcase.to_sym] = point_param['value']
            end
          end
        end
        params[:orchards] << [orchard_args, orchard_attrs]
      end
    end

    def update_orchard_tests # rubocop:disable Metrics/AbcSize
      save_to_yaml(params, "PhytCleanStandardData_#{params[:puc_code]}")
      values = YAML.load_file('tmp/PhytCleanStandardGlossary.yml')

      params[:orchards].each do |args, attrs|
        values['orchards'] = [values['orchards'], args].flatten.uniq
        puc_id = repo.get_id(:pucs, puc_code: args[:puc_code])
        orchard_id = repo.get_id(:orchards, orchard_code: args[:orchard_code], puc_id: puc_id)
        cultivar_id = repo.get_id(:cultivars, cultivar_code: args[:cultivar_code])
        attrs.each do |api_attribute, api_result|
          values[api_attribute.to_s] = [values[api_attribute.to_s], api_result].flatten.uniq

          orchard_test_type_id = repo.get_id(:orchard_test_types, api_name: AppConst::PHYT_CLEAN_STANDARD, api_attribute: api_attribute.to_s)
          next if orchard_test_type_id.nil?

          update_params = { puc_id: puc_id, orchard_id: orchard_id, cultivar_id: cultivar_id, orchard_test_type_id: orchard_test_type_id }
          orchard_test_result_id = repo.get_id(:orchard_test_results, update_params)
          next if orchard_test_result_id.nil?

          next if repo.get(:orchard_test_results, orchard_test_result_id, :freeze_result)

          update_params[:api_result] = api_result
          QualityApp::UpdateOrchardTestResult.call(orchard_test_result_id, update_params)
        end
      end
      save_to_yaml(values, 'PhytCleanStandardGlossary')
    end

    def save_to_yaml(payload, file_name)
      File.open("tmp/#{file_name}.yml", 'w') { |f| f << payload.to_yaml }
    end
  end
end
