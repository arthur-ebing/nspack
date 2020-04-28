# frozen_string_literal: true

module QualityApp
  class PhytCleanOrchardDiff < BaseService
    attr_reader :repo, :api, :season_id, :puc_ids
    attr_accessor :attrs, :puc_id

    def initialize(puc_ids)
      @repo = OrchardTestRepo.new
      @api = PhytCleanApi.new
      @season_id = AppConst::PHYT_CLEAN_SEASON_ID
      @attrs = {}
      @puc_ids = Array(puc_ids).uniq
      @puc_id = nil
    end

    def call # rubocop:disable Metrics/AbcSize
      raise ArgumentError, 'PhytClean Season not set' if season_id.nil?

      res = api.auth_token_call
      return failed_response(res.message) unless res.success

      puc_ids.each do |puc_id|
        @puc_id = puc_id
        res = api.request_phyt_clean_standard_data(season_id, puc_id)
        return failed_response(res.message) unless res.success

        parse_standard_data(res)
      end

      success_response(res.message, Hash[attrs.sort])
    end

    private

    def parse_standard_data(res)
      head = res.instance['season']
      puc = head['fbo'].first
      orchards = puc['orchard']
      orchards.each do |orchard|
        next unless repo.exists?(:orchards, orchard_code: orchard['name'], puc_id: puc_id)

        attrs["Puc #{puc['code']} - Orchard #{orchard['name']}"] = "Cultivar #{orchard['cultivarCode']}   "
      end
    end
  end
end
