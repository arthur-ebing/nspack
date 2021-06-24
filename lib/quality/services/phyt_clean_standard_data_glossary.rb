# frozen_string_literal: true

module QualityApp
  class PhytCleanStandardDataGlossary < BaseService
    attr_reader :repo, :api, :phyt_clean_season_id
    attr_accessor :glossary

    def initialize
      @repo = OrchardTestRepo.new
      @api = PhytCleanApi.new
      @phyt_clean_season_id = AppConst::PHYT_CLEAN_SEASON_ID
      @glossary = {}
    end

    def call
      raise ArgumentError, 'PhytClean Season not set' if phyt_clean_season_id.nil?

      res = api.request_phyt_clean_glossary(phyt_clean_season_id)
      return failed_response(res.message) unless res.success

      parse_glossary(res)

      success_response(res.message)
    end

    private

    def parse_glossary(res) # rubocop:disable Metrics/AbcSize
      update_orchard_test_api_attributes('phytoData', 'PhytoData Classification')
      update_orchard_test_api_attributes('isCultivarB', 'CultivarB Status')

      res.instance.each do |row|
        alias_name = row['cpagxmlAliasname']
        next unless alias_name

        attribute = alias_name.downcase
        description = "#{row['controlPointGroupName']} #{row['controlPointName']} #{row['controlpointAllowedGroupName']} ".split.uniq.join(' ')
        glossary[attribute] = description
        update_orchard_test_api_attributes(attribute, description)
      end
      save_to_yaml(glossary, 'PhytCleanStandardGlossary')
    end

    def update_orchard_test_api_attributes(attribute, description)
      attrs = { api_name: AppConst::PHYT_CLEAN_STANDARD, api_attribute: attribute }
      id = repo.get_id(:orchard_test_api_attributes, attrs)
      attrs[:description] = description

      if id.nil?
        repo.create(:orchard_test_api_attributes, attrs)
      else
        repo.update(:orchard_test_api_attributes, id, attrs)
      end
    end

    def save_to_yaml(payload, file_name)
      File.open("tmp/#{file_name}.yml", 'w') { |f| f << payload.to_yaml }
    end
  end
end
