# frozen_string_literal: true

module RawMaterialsApp
  class CreatePresortGrowerGradingPool < BaseService
    attr_reader :repo, :maf_lot_number, :user_name, :presort_grading_pool_id

    def initialize(maf_lot_number, user_name)
      @repo = RawMaterialsApp::PresortGrowerGradingRepo.new
      @maf_lot_number = maf_lot_number
      @user_name = user_name
    end

    def call
      res = create_presort_grower_grading_pools
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      success_response('ok', presort_grading_pool_id: presort_grading_pool_id)
    end

    private

    def create_presort_grower_grading_pools # rubocop:disable Metrics/AbcSize
      return failed_response("Maf lot number : #{maf_lot_number} does not exist") unless repo.maf_lot_number_exists?(maf_lot_number)
      return failed_response("Presort Grading Pool for Maf lot number : #{maf_lot_number} already exists") if repo.grading_pool_exists?(maf_lot_number)
      return failed_response("Maf lot number : #{maf_lot_number} does not have tipped bins") unless repo.grading_pool_bins_exists?(maf_lot_number)

      res = create_presort_grading_pools
      return res unless res.success

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_presort_grading_pools
      repo.presort_grading_pool_details_for(maf_lot_number).each do |pool|
        pool[:created_by] = user_name
        res = validate_presort_grading_pool_params(pool)
        return validation_failed_response(res) if res.failure?

        @presort_grading_pool_id = repo.create_presort_grower_grading_pool(res)
        repo.log_status(:presort_grower_grading_pools, presort_grading_pool_id, 'CREATED')
      end

      ok_response
    end

    def validate_presort_grading_pool_params(params)
      PresortGrowerGradingPoolSchema.call(params)
    end
  end
end
