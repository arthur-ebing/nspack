# frozen_string_literal: true

module MasterfilesApp
  class MasterfileVariantInteractor < BaseInteractor
    def create_masterfile_variant(params) # rubocop:disable Metrics/AbcSize
      res = validate_masterfile_variant_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      id = nil
      repo.transaction do
        id = repo.create_masterfile_variant(res)
        log_status(:masterfile_variants, id, 'CREATED')
        log_transaction
      end
      instance = masterfile_variant(id)
      success_response("Created masterfile variant #{instance.masterfile_table}",
                       instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { masterfile_table: ['This masterfile variant already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_masterfile_variant(id, params)
      res = validate_masterfile_variant_params(params)
      return validation_failed_response(res) unless res.messages.empty?

      repo.transaction do
        repo.update_masterfile_variant(id, res)
        log_transaction
      end
      instance = masterfile_variant(id)
      success_response("Updated masterfile variant #{instance.masterfile_table}",
                       instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_masterfile_variant(id)
      name = masterfile_variant(id).masterfile_table
      repo.transaction do
        repo.delete_masterfile_variant(id)
        log_status(:masterfile_variants, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted masterfile variant #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    private

    def repo
      @repo ||= MasterfileVariantRepo.new
    end

    def masterfile_variant(id)
      repo.find_masterfile_variant(id)
    end

    def validate_masterfile_variant_params(params)
      MasterfileVariantSchema.call(params)
    end
  end
end
