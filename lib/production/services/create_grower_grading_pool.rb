# frozen_string_literal: true

module ProductionApp
  class CreateGrowerGradingPool < BaseService
    attr_reader :repo, :messcada_repo, :production_run_id, :user_name, :grading_pool_id, :opts

    def initialize(production_run_id, user_name, opts = {})
      @repo = ProductionApp::GrowerGradingRepo.new
      @messcada_repo = MesscadaApp::MesscadaRepo.new
      @production_run_id = production_run_id
      @user_name = user_name
      @opts = opts
    end

    def call
      res = create_grower_grading_pool
      raise Crossbeams::InfoError, unwrap_failed_response(res) unless res.success

      success_response('ok', grading_pool_id: grading_pool_id)
    end

    private

    def create_grower_grading_pool
      return failed_response("Production run : #{production_run_id} does not exist") unless production_run_exists?
      return failed_response("Grading Pool for production run: #{production_run_id} already exists") if grading_pool_exists?
      return failed_response("Production run: #{production_run_id} does not have cartons or rebins") unless run_objects_exists?

      res = create_grading_pool_and_objects
      return res unless res.success

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def production_run_exists?
      messcada_repo.production_run_exists?(production_run_id)
    end

    def grading_pool_exists?
      repo.grading_pool_exists?(production_run_id)
    end

    def run_objects_exists?
      repo.production_run_carton_exists?(production_run_id) || repo.production_run_rebin_exists?(production_run_id)
    end

    def create_grading_pool_and_objects
      res = create_grading_pool
      return res unless res.success

      res = create_grading_cartons
      return res unless res.success

      res = create_grading_rebins
      return res unless res.success

      log_transaction_statuses

      ok_response
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_grading_pool
      res = validate_grading_pool_params(grading_pool_params)
      return validation_failed_response(res) if res.failure?

      @grading_pool_id = repo.create_grower_grading_pool(res)

      ok_response
    end

    def grading_pool_params
      params = repo.production_run_grading_pool_details(production_run_id).merge(opts)
      params[:created_by] = user_name
      legacy_data = AppConst::CR_PROD.grower_grading_json_fields[:legacy_data].map { |f| [f, params[f]] }
      params[:legacy_data] = Hash[legacy_data] unless legacy_data.empty?
      params
    end

    def validate_grading_pool_params(params)
      GrowerGradingPoolSchema.call(params)
    end

    def create_grading_cartons
      repo.production_run_grading_carton_details(production_run_id).each do |carton|
        carton[:grower_grading_pool_id] = grading_pool_id
        carton[:not_inspected_quantity] = carton[:carton_quantity] - carton[:inspected_quantity]
        res = validate_grading_carton_params(carton)
        return validation_failed_response(res) if res.failure?

        repo.create_grower_grading_carton(res)
      end

      ok_response
    end

    def validate_grading_carton_params(params)
      GrowerGradingCartonSchema.call(params)
    end

    def create_grading_rebins
      repo.production_run_grading_rebin_details(production_run_id).each do |rebin|
        rebin[:grower_grading_pool_id] = grading_pool_id
        res = validate_grading_rebin_params(rebin)
        return validation_failed_response(res) if res.failure?

        repo.create_grower_grading_rebin(res)
      end

      ok_response
    end

    def log_transaction_statuses
      repo.log_status(:grower_grading_pools, grading_pool_id, 'CREATED')
      repo.log_multiple_statuses(:grower_grading_cartons, repo.grower_grading_carton_ids(grading_pool_id), 'CREATED')
      repo.log_multiple_statuses(:grower_grading_rebins, repo.grower_grading_rebin_ids(grading_pool_id), 'CREATED')
    end

    def validate_grading_rebin_params(params)
      GrowerGradingRebinSchema.call(params)
    end

    def grower_grading_pool(id)
      repo.find_grower_grading_pool(id)
    end
  end
end
