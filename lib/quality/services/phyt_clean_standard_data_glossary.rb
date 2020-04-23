# frozen_string_literal: true

module QualityApp
  class PhytCleanStandardDataGlossary < BaseService
    attr_reader :repo, :api, :season_id
    attr_accessor :glossary

    def initialize
      @repo = OrchardTestRepo.new
      @api = PhytCleanApi.new
      @season_id = AppConst::PHYT_CLEAN_SEASON_ID
      @glossary = {}
    end

    def call # rubocop:disable Metrics/AbcSize
      raise ArgumentError, 'PhytClean Season not set' if season_id.nil?

      res = api.auth_token_call
      return failed_response(res.message) unless res.success

      res = api.request_phyt_clean_glossary(season_id)
      return failed_response(res.message) unless res.success

      parse_glossary(res)

      success_response(res.message)
    end

    private

    def parse_glossary(res)
      res.instance.each do |row|
        control_attr = "#{row['controlPointGroupName']} #{row['controlPointName']} #{row['controlpointAllowedGroupName']} ".split.uniq.join(' ')
        glossary[row['cpagxmlAliasname'].downcase] = control_attr
      end
      save_to_yaml(glossary, 'PhytCleanStandardGlossary')
    end

    def save_to_yaml(payload, file_name)
      File.open("tmp/#{file_name}.yml", 'w') { |f| f << payload.to_yaml }
    end
  end
end
