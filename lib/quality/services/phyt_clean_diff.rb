# frozen_string_literal: true

module QualityApp
  class PhytCleanDiff < BaseService
    attr_reader :repo, :api, :phyt_clean_season_id, :puc_ids
    attr_accessor :attrs, :puc_id

    def initialize(mode)
      @mode = mode.to_sym
      @repo = OrchardTestRepo.new
      @api = PhytCleanApi.new
      @phyt_clean_season_id = AppConst::PHYT_CLEAN_SEASON_ID
      @attrs = {}
      @puc_ids = if @mode == :orchards
                   @repo.select_values(:orchards, :puc_id).uniq
                 else
                   @repo.select_values(:pallet_sequences, :puc_id).uniq
                 end
    end

    def call
      raise ArgumentError, 'PhytClean Season not set' if phyt_clean_season_id.nil?

      res = api.request_phyt_clean_standard_data(phyt_clean_season_id, puc_ids)
      return failed_response(res.message) unless res.success

      parse_standard_data(res)
      success_response(res.message, Hash[attrs.sort])
    end

    private

    def parse_standard_data(res) # rubocop:disable Metrics/AbcSize
      head = res.instance['season']
      pucs = head['fbo']
      pucs.each do |puc|
        puc_id = repo.get_id(:pucs, puc_code: puc['code'])
        orchards = puc['orchard']
        orchards.each do |orchard|
          next if orchard['name'].nil?
          next unless repo.exists?(:orchards, orchard_code: orchard['name'].downcase, puc_id: puc_id)

          attrs["PUC #{puc['code']} - Orchard #{orchard['name']}"] = "Cultivar #{orchard['cultivarCode']}   "
        end
      end
    end
  end
end
