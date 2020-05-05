# frozen_string_literal: true

module QualityApp
  class PhytCleanStandardData < BaseService
    attr_reader :repo, :api, :season_id, :puc_ids
    attr_accessor :attrs, :glossary

    def initialize(puc_ids = nil)
      @repo = OrchardTestRepo.new
      @api = PhytCleanApi.new
      @season_id = AppConst::PHYT_CLEAN_SEASON_ID
      @puc_ids = Array(puc_ids)
      @puc_ids = repo.select_values(:orchard_test_results, :puc_id).uniq if @puc_ids.empty?
      @attrs = {}
      @glossary = {}
    end

    def call # rubocop:disable Metrics/AbcSize
      raise ArgumentError, 'PhytClean Season not set' if season_id.nil?

      res = api.auth_token_call
      return failed_response(res.message) unless res.success

      puc_ids.each do |puc_id|
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
      attrs[:season_name] = head['seasonName']
      puc = head['fbo'].first
      attrs[:puc_code] = puc['code']
      attrs[:orchards] = []
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
            point_attrs = point['params'].first['p']
            point_attrs.each do |point_attr|
              orchard_attrs[point_attr['name'].downcase.to_sym] = point_attr['value']
            end
          end
        end
        attrs[:orchards] << [orchard_args, orchard_attrs]
      end
    end

    def update_orchard_tests # rubocop:disable Metrics/AbcSize
      save_to_yaml(attrs, "PhytCleanStandardData_#{attrs[:puc_code]}")

      attrs[:orchards].each do |orchard_args, orchard_attrs|
        puc_id = repo.get_id(:pucs, puc_code: orchard_args[:puc_code])
        orchard_id = repo.get_id(:orchards, orchard_code: orchard_args[:orchard_code].downcase, puc_id: puc_id)
        cultivar_ids = repo.select_values(:cultivars, :id, cultivar_code: orchard_args[:cultivar_code])
        orchard_attrs.each do |api_attribute, api_result|
          orchard_test_type_id = repo.get_id(:orchard_test_types, api_name: AppConst::PHYT_CLEAN_STANDARD, api_attribute: api_attribute.to_s)
          next if orchard_test_type_id.nil?

          cultivar_ids.each do |cultivar_id|
            update_attrs = { puc_id: puc_id, orchard_id: orchard_id, cultivar_id: cultivar_id, orchard_test_type_id: orchard_test_type_id }
            orchard_test_result_id = repo.get_id(:orchard_test_results, update_attrs)
            next if orchard_test_result_id.nil?

            next if repo.get(:orchard_test_results, orchard_test_result_id, :freeze_result)

            update_attrs[:api_result] = api_result
            QualityApp::UpdateOrchardTestResult.call(orchard_test_result_id, update_attrs)
          end
        end
      end
    end

    def save_to_yaml(payload, file_name)
      File.open("tmp/#{file_name}.yml", 'w') { |f| f << payload.to_yaml }
    end
  end
end
