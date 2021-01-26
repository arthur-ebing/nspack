# frozen_string_literal: true

module MasterfilesApp
  class ValidateCompileProductCode < BaseService
    attr_reader :repo, :pm_subtype, :pm_type
    attr_accessor :params, :res

    def initialize(params, id = nil)
      @repo = BomRepo.new
      @params = params
      if id
        existing = repo.find_hash(:pm_products, id).reject { |k, _| k == :pm_subtype_id }
        @params = existing.merge(params)
      end
      @pm_subtype = repo.find_pm_subtype(params[:pm_subtype_id])
      @pm_type = repo.find_pm_type(@pm_subtype.pm_type_id)
    end

    def call # rubocop:disable Metrics/AbcSize
      @res = ExtendedPmProductContract.new.call(params)
      return res unless res.errors[:pm_subtype_id].nil?
      return res unless res.failure?

      compile_product_code

      ExtendedPmProductContract.new.call(params)
    rescue Crossbeams::FrameworkError
      res
    end

    private

    def compile_product_code # rubocop:disable Metrics/AbcSize
      raise Crossbeams::InfoError, 'Unable to find PM Subtype' if pm_subtype.nil? || pm_type.nil?

      params[:product_code] = if pm_subtype.minimum_composition_level
                                minimum_composition_level_product_code
                              elsif !(pm_subtype.minimum_composition_level || pm_subtype.fruit_composition_level)
                                mid_composition_level_product_code
                              else
                                else_product_code
                              end
    end

    def minimum_composition_level_product_code # rubocop:disable Metrics/AbcSize
      @res = MinimumPmProductSchema.call(params)
      raise Crossbeams::FrameworkError if res.failure?

      params[:basic_pack_code] = repo.get(:basic_pack_codes, params[:basic_pack_id], :basic_pack_code)
      params[:pm_subtype_short_code] = pm_subtype.short_code
      params[:pm_type_short_code] = pm_type.short_code

      @res = ProductCodeMinimumCompositionLevelSchema.call(params)
      raise Crossbeams::FrameworkError if res.failure?

      "#{params[:pm_type_short_code]}#{params[:basic_pack_code]}#{params[:pm_subtype_short_code]}#{params[:height_mm]}"
    end

    def mid_composition_level_product_code # rubocop:disable Metrics/AbcSize
      args = {}
      args[:pm_subtype_short_code] = pm_subtype.short_code
      args[:pm_type_short_code] = pm_type.short_code
      args[:gross_weight_per_unit] = params[:gross_weight_per_unit].nil_or_empty? ? '*' : params[:gross_weight_per_unit].to_f
      args[:items_per_unit] = params[:items_per_unit].nil_or_empty? ? '*' : params[:items_per_unit].to_i

      @res = ProductCodeMidCompositionLevelSchema.call(args)
      raise Crossbeams::FrameworkError if res.failure?

      "#{args[:pm_type_short_code]}#{args[:gross_weight_per_unit]}#{args[:pm_subtype_short_code]}#{args[:items_per_unit]}"
    end

    def else_product_code
      @res = PmProductErpSchema.call(params)
      raise Crossbeams::FrameworkError if res.failure?

      params[:erp_code]
    end
  end
end
