# frozen_string_literal: true

module MasterfilesApp
  class FruitSizeInteractor < BaseInteractor
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

      id = repo.create_fruit_actual_counts_for_pack(process_array_params(res.to_h))
      instance = fruit_actual_counts_for_pack(id)
      success_response("Created fruit actual counts for pack #{instance.id}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { actual_count_for_pack: ['This fruit actual counts for pack already exists'] }))
    end

    def process_array_params(attrs)
      standard_pack_code_ids = attrs.delete(:standard_pack_code_ids)
      size_reference_ids = attrs.delete(:size_reference_ids)

      default = {
        standard_pack_code_ids: "{#{standard_pack_code_ids.join(',')}}",
        size_reference_ids: "{#{size_reference_ids.join(',')}}"
      }
      attrs.merge(default)
    end

    def update_fruit_actual_counts_for_pack(id, params)
      res = validate_fruit_actual_counts_for_pack_params(params)
      return validation_failed_response(res) if res.failure?

      repo.update_fruit_actual_counts_for_pack(id, process_array_params(res.to_h))
      instance = fruit_actual_counts_for_pack(id)
      success_response("Updated fruit actual counts for pack #{instance.id}", instance)
    end

    def delete_fruit_actual_counts_for_pack(id)
      name = fruit_actual_counts_for_pack(id).id
      repo.delete_fruit_actual_counts_for_pack(id)
      success_response("Deleted fruit actual counts for pack #{name}")
    end

    private

    def repo
      @repo ||= FruitSizeRepo.new
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
  end
end
