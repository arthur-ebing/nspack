# frozen_string_literal: true

module QualityApp
  class PhytCleanStandardPhytoData < BaseService
    attr_reader :repo, :api, :puc_id, :season_id
    attr_accessor :params, :glossary

    def initialize(puc_id)
      @repo = OrchardTestRepo.new
      @api = PhytCleanApi.new
      @puc_id = puc_id
      @season_id = AppConst::PHYT_CLEAN_SEASON_ID
      @params = {}
      @glossary = {}
    end

    def call # rubocop:disable Metrics/AbcSize
      raise ArgumentError, 'PhytClean Season not set' if season_id.nil?

      res = api.auth_token_call
      return failed_response(res.message) unless res.success

      res = api.request_phyt_clean_glossary(season_id)
      return failed_response(res.message) unless res.success

      parse_glossary(res)

      res = api.request_phyt_clean_standard_phyto_data(season_id, puc_id)
      return failed_response(res.message) unless res.success

      parse_standard_phyto_data(res)

      p params

      success_response(res.message)
    end

    private

    def parse_glossary(res)
      res.instance.each do |row|
        glossary[row['cpxmlAliasname'].downcase] = row['controlPointName']
        glossary[row['cpgxmlAliasname'].downcase] = row['controlPointGroupName']
        glossary[row['cpagxmlAliasname'].downcase] = row['controlpointAllowedGroupName']
      end
    end

    def parse_standard_phyto_data(res) # rubocop:disable Metrics/AbcSize
      head = res.instance['season']
      params[:season_name] = head['seasonName']
      puc = head['fbo'].first
      params[:puc_code] = puc['code']
      orchards = puc['orchard']
      orchards.each do |orchard|
        orchard_attrs = {}
        orchard_attrs[:orchard_name] = orchard['name']
        orchard_attrs[:cultivar_code] = orchard['cultivarCode']
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
              orchard_attrs[point_param['name'].to_sym] = { control_group: glossary[group['name']],
                                                            control_point: glossary[point['name']],
                                                            control_param: glossary[point_param['name']],
                                                            control_value: point_param['value'] }
            end
          end
        end
        params[orchard['name']] = orchard_attrs
      end
    end

    def check_orchard_test_types # rubocop:disable Metrics/AbcSize
      orchard_test_types = repo.select_values(:orchard_test_types, :id,  api_name: AppConst::PHYT_CLEAN)
      orchard_test_types.each do |id|
        params[:orchard_test_type_id] = id
        args = params.select { |key, _| %i[orchard_test_type_id puc_id orchard_id cultivar_id].include?(key) }
        orchard_test_result_id = repo.get_id(:orchard_test_results, args)

        if orchard_test_result_id.nil?
          next unless repo.exists?(:pallet_sequences, params.select { |key, _| %i[puc_id orchard_id cultivar_id].include?(key) })

          orchard_test_result_id = repo.create_orchard_test_result(args)
        end

        orchard_test_result = repo.find_orchard_test_result_flat(orchard_test_result_id)
        next if orchard_test_result.freeze_result

        params[:api_result] = api_result
        QualityApp::UpdateOrchardTestResult.call(orchard_test_result_id, params)
      end
    end

    def save_to_yaml(payload)
      File.open('tmp/PhytCleanStandardPhytoData_Store.yml', 'w') { |f| f << payload.to_yaml }
    end
  end
end
