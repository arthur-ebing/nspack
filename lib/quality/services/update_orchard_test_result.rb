# frozen_string_literal: true

module QualityApp
  class UpdateOrchardTestResult < BaseService
    attr_reader :id, :orchard_test_type, :orchard_test_result, :api_result, :result_attribute
    attr_accessor :params, :otmc_result

    def initialize(id, params)
      @id = id
      @params = params.to_h
      @api_result = @params[:api_result] || {}
      @orchard_test_result = repo.find_orchard_test_result_flat(id)
      @orchard_test_type = repo.find_orchard_test_type_flat(@orchard_test_result.orchard_test_type_id)
      @result_attribute = @orchard_test_type.result_attribute&.to_sym
    end

    def call
      if orchard_test_type.result_type == AppConst::CLASSIFICATION
        classification_rules
      else
        pass_fail_rules
      end

      expand_selection

      update_orchard_otmc_results unless result_attribute.nil?

      update_orchard_test_results

      success_response('Updated Orchard Test Result')
    end

    private

    def repo
      @repo ||= OrchardTestRepo.new
    end

    def expand_selection # rubocop:disable Metrics/AbcSize
      puc_codes = repo.select_values(:pucs, :puc_code, id: params[:puc_ids])
      params[:puc_ids] = repo.select_values(:pucs, :id, puc_code: puc_codes)
      params[:puc_ids] = Array(params[:puc_id]) if params[:puc_ids].empty?

      orchard_codes = repo.select_values(:orchards, :orchard_code, id: params[:orchard_ids])
      params[:orchard_ids] = repo.select_values(:orchards, :id, orchard_code: orchard_codes, puc_id: params[:puc_ids])
      params[:orchard_ids] = Array(params[:orchard_id]) if params[:orchard_ids].empty?

      cultivar_codes = repo.select_values(:cultivars, :cultivar_code, id: params[:cultivar_ids])
      params[:cultivar_ids] = repo.select_values(:cultivars, :id, cultivar_code: cultivar_codes)
      params[:cultivar_ids] = Array(params[:cultivar_id]) if params[:cultivar_ids].empty?
    end

    def classification_rules
      params[:passed] = true
      params[:classification_only] = true
      @otmc_result = api_result[result_attribute] || params[:classification]
      params[:classification] = otmc_result
    end

    def pass_fail_rules
      params[:passed] = AppConst::PHYT_CLEAN_PASSED.include? api_result[result_attribute] unless api_result.empty?
      params[:classification_only] = false
      @otmc_result = params[:passed]
      params[:classification] = nil
    end

    def update_orchard_test_results # rubocop:disable Metrics/AbcSize
      params[:puc_ids].each do |puc_id|
        params[:orchard_ids].each do |orchard_id|
          params[:cultivar_ids].each do |cultivar_id|
            args = { puc_id: puc_id, orchard_id: orchard_id, cultivar_id: cultivar_id, orchard_test_type_id: orchard_test_result.orchard_test_type_id }
            id = repo.get_id(:orchard_test_results, args)

            if id.nil_or_empty?
              # check if id combination exists
              next unless repo.select_values(:orchards, :cultivar_ids, puc_id: puc_id, id: orchard_id).flatten.include? cultivar_id

              id = repo.create_orchard_test_result(args)
            end

            @orchard_test_result = repo.find_orchard_test_result_flat(id)
            args.merge!(params)
            args.reject! { |k, _| %i[puc_ids orchard_ids cultivar_ids].include? k }

            new_args = args
            new_args.delete(:api_result)
            next if new_args == orchard_test_result.to_h.select { |key, _| new_args.keys.include?(key) }

            repo.update_orchard_test_result(id, args)
            repo.update_pallet_sequences_phyto_data(args) if @orchard_test_type.result_attribute == 'phytoData'
          end
        end
      end
    end

    def update_orchard_otmc_results
      otmc_results = repo.get(:orchards, params[:orchard_id], :otmc_results) || {}
      otmc_results[orchard_test_type.test_type_code.to_sym] = otmc_result
      repo.update(:orchards, params[:orchard_id], otmc_results: Sequel.hstore(otmc_results))
    end
  end
end
