# frozen_string_literal: true

module QualityApp
  class PhytCleanStandardData < BaseService
    attr_reader :repo, :api, :phyt_clean_season_id, :puc_ids
    attr_accessor :attrs, :glossary

    def initialize(puc_ids = nil)
      @repo = OrchardTestRepo.new
      @api = PhytCleanApi.new
      @phyt_clean_season_id = AppConst::PHYT_CLEAN_SEASON_ID
      @puc_ids = Array(puc_ids)
      @puc_ids = repo.select_values(:orchard_test_results, :puc_id).uniq if @puc_ids.empty?
      @attrs = {}
      @glossary = {}
      @user = OpenStruct.new(user_name: 'ApiPhytCleanStandardData')
    end

    def call
      raise ArgumentError, 'PhytClean Season not set' if phyt_clean_season_id.nil?

      QualityApp::CreateOrchardTestResults.call(@user)

      res = api.request_phyt_clean_standard_data(phyt_clean_season_id, puc_ids)
      raise Crossbeams::InfoError, res.message unless res.success

      parse_standard_data(res)

      update_orchard_tests

      success_response(res.message)
    end

    private

    def parse_standard_data(res) # rubocop:disable Metrics/AbcSize
      head = res.instance['season']
      attrs[:season_name] = head['seasonName']
      attrs[:pucs] = []
      head['fbo'].each do |puc|
        puc_args = {}
        puc_args[:puc_code] = puc['code']
        puc_args[:orchards] = []
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
                orchard_attrs[point_attr['name'].to_s.downcase.to_sym] = point_attr['value']
              end
            end
          end
          puc_args[:orchards] << [orchard_args, orchard_attrs]
        end
        attrs[:pucs] << puc_args
      end
    end

    def update_orchard_tests # rubocop:disable Metrics/AbcSize
      attrs[:pucs].each do |puc_args|
        save_to_yaml(puc_args, "PhytCleanStandardData_#{puc_args[:puc_code]}")

        puc_args[:orchards].each do |orchard_args, orchard_attrs|
          puc_id = repo.get_id(:pucs, Sequel.function(:lower, :puc_code) => orchard_args[:puc_code].downcase)
          orchard_id = repo.get_id(:orchards, Sequel.function(:lower, :orchard_code) => orchard_args[:orchard_code].downcase, puc_id: puc_id)
          cultivar_ids = repo.select_values(:cultivars, :id, Sequel.function(:lower, :cultivar_code) => orchard_args[:cultivar_code].downcase)
          orchard_attrs.each do |api_attribute, api_result|
            orchard_test_type_id = repo.get_id(:orchard_test_types, api_name: AppConst::PHYT_CLEAN_STANDARD, api_attribute: api_attribute.to_s)
            next if orchard_test_type_id.nil?

            cultivar_ids.each do |cultivar_id|
              update_attrs = { puc_id: puc_id, orchard_id: orchard_id, cultivar_id: cultivar_id, orchard_test_type_id: orchard_test_type_id }
              result_id = repo.get_id(:orchard_test_results, update_attrs)
              next if result_id.nil?

              next if repo.get(:orchard_test_results, :freeze_result, result_id)

              update_attrs[:api_result] = api_result
              QualityApp::UpdateOrchardTestResult.call(result_id, update_attrs, @user)
            end
          end
        end
      end
    end

    def save_to_yaml(payload, file_name)
      File.open(File.join(ENV['ROOT'], 'tmp', "#{file_name}.yml"), 'w') { |f| f << payload.to_yaml }
    end
  end
end
