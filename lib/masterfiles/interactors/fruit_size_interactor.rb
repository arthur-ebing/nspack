# frozen_string_literal: true

module MasterfilesApp
  class FruitSizeInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def create_std_fruit_size_count(params)
      res = validate_std_fruit_size_count_params(params)
      return validation_failed_response(res) if res.failure?

      id = repo.create_std_fruit_size_count(res)
      instance = std_fruit_size_count(id)
      success_response("Created std fruit size count #{instance.size_count_description}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { size_count_description: ['This std fruit size count already exists'] }))
    end

    def update_std_fruit_size_count(id, params)
      res = validate_std_fruit_size_count_params(params)
      return validation_failed_response(res) if res.failure?

      repo.update_std_fruit_size_count(id, res)
      instance = std_fruit_size_count(id)
      success_response("Updated std fruit size count #{instance.size_count_description}", instance)
    end

    def delete_std_fruit_size_count(id)
      name = std_fruit_size_count(id).size_count_description
      repo.delete_std_fruit_size_count(id)
      success_response("Deleted std fruit size count #{name}")
    end

    def create_fruit_actual_counts_for_pack(parent_id, params)
      params[:std_fruit_size_count_id] = parent_id
      res = validate_fruit_actual_counts_for_pack_params(params)
      return validation_failed_response(res) if res.failure?

      id = repo.create_fruit_actual_counts_for_pack(res)
      instance = fruit_actual_counts_for_pack(id)
      success_response("Created fruit actual counts for pack #{instance.id}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { actual_count_for_pack: ['This fruit actual counts for pack already exists'] }))
    end

    def update_fruit_actual_counts_for_pack(id, params)
      res = validate_fruit_actual_counts_for_pack_params(params)
      return validation_failed_response(res) if res.failure?

      repo.update_fruit_actual_counts_for_pack(id, res)
      instance = fruit_actual_counts_for_pack(id)
      success_response("Updated fruit actual counts for pack #{instance.id}", instance)
    end

    def delete_fruit_actual_counts_for_pack(id)
      name = fruit_actual_counts_for_pack(id).id
      repo.delete_fruit_actual_counts_for_pack(id)
      success_response("Deleted fruit actual counts for pack #{name}")
    end

    def sync_pm_boms # rubocop:disable Metrics/AbcSize
      count = 0
      repo.transaction do
        pm_composition_level_id = get_pm_composition_level({ composition_level: AppConst::FRUIT_COMPOSITION_LEVEL, description: AppConst::FRUIT_PM_TYPE })
        pm_type_id = get_pm_type({ pm_composition_level_id: pm_composition_level_id, pm_type_code: AppConst::FRUIT_PM_TYPE, description: AppConst::FRUIT_PM_TYPE })
        repo.find_std_fruit_size_counts.group_by { |h| h[:commodity_code] }.each do |commodity_code, recs|
          pm_subtype_id = get_pm_subtype({ pm_type_id: pm_type_id, subtype_code: commodity_code, description: commodity_code })
          recs.each do |rec|
            next if boms_repo.pm_product_code_exists?(rec[:product_code])

            repo.create(:pm_products,
                        pm_subtype_id: pm_subtype_id,
                        product_code: rec[:product_code],
                        erp_code: rec[:product_code],
                        description: rec[:description])

            # pm_bom_id = get_pm_bom({ bom_code: rec[:product_code], system_code: rec[:system_code], description: rec[:description] })
            # pm_product_id = get_pm_product({ pm_subtype_id: pm_subtype_id, product_code: rec[:product_code], erp_code: rec[:product_code], description: rec[:description] })
            # repo.create(:pm_boms_products,
            #             pm_product_id: pm_product_id,
            #             pm_bom_id: pm_bom_id,
            #             uom_id: rec[:uom_id],
            #             quantity: rec[:size_count_value])
            count += 1
          end
        end
      end

      msg = if count.zero?
              'There are no new pm_boms to add'
            else
              desc = count == 1 ? 'pm_bom was' : 'pm_boms were'
              "#{count} new #{desc} added"
            end
      success_response(msg)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def repo
      @repo ||= FruitSizeRepo.new
    end

    def boms_repo
      @boms_repo ||= BomRepo.new
    end

    def std_fruit_size_count(id)
      repo.find_std_fruit_size_count(id)
    end

    def validate_std_fruit_size_count_params(params)
      StdFruitSizeCountSchema.call(params)
    end

    def fruit_actual_counts_for_pack(id)
      repo.find_fruit_actual_counts_for_pack(id)
    end

    def validate_fruit_actual_counts_for_pack_params(params)
      FruitActualCountsForPackSchema.call(params)
    end

    def get_pm_composition_level(attrs)
      boms_repo.create_pm_composition_level(attrs) unless boms_repo.pm_composition_level_exists?(attrs[:description])
      boms_repo.find_pm_composition_level_by_code(attrs[:description])
    end

    def get_pm_type(attrs)
      boms_repo.create_pm_type(attrs) unless boms_repo.pm_type_code_exists?(attrs[:pm_type_code])
      boms_repo.find_pm_type_by_code(attrs[:pm_type_code])
    end

    def get_pm_subtype(attrs)
      boms_repo.create_pm_subtype(attrs) unless boms_repo.pm_subtype_code_exists?(attrs[:subtype_code])
      boms_repo.find_pm_subtype_by_code(attrs[:subtype_code])
    end

    def get_pm_bom(attrs)
      boms_repo.create_pm_bom(attrs) unless boms_repo.pm_bom_code_exists?(attrs[:bom_code])
      boms_repo.find_pm_bom_by_code(attrs[:bom_code])
    end

    def get_pm_product(attrs)
      boms_repo.create_pm_product(attrs) unless boms_repo.pm_product_code_exists?(attrs[:product_code])
      boms_repo.find_pm_product_by_code(attrs[:product_code])
    end
  end
end
