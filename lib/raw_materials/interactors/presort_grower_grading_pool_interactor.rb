# frozen_string_literal: true

module RawMaterialsApp
  class PresortGrowerGradingPoolInteractor < BaseInteractor
    def create_presort_grower_grading_pool(params) # rubocop:disable Metrics/AbcSize
      res = validate_new_presort_grower_grading_pool_params(params)
      return validation_failed_response(res) if res.failure?

      pool_res = nil
      repo.transaction do
        pool_res = CreatePresortGrowerGradingPool.call(res[:maf_lot_number], @user.user_name)
        raise Crossbeams::InfoError, pool_res unless pool_res.success

        log_transaction
      end
      instance = presort_grower_grading_pool(pool_res.instance[:presort_grading_pool_id])
      success_response("Created presort grower grading pool #{instance.maf_lot_number}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { maf_lot_number: ['This presort grower grading pool already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_presort_grower_grading_pool(id, params)
      res = validate_edit_presort_grower_grading_pool_params(include_updated_by_in_changeset(params))
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_presort_grower_grading_pool(id, res)
        log_transaction
      end
      instance = presort_grower_grading_pool(id)
      success_response("Updated presort grower grading pool #{instance.maf_lot_number}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_presort_grower_grading_pool(id) # rubocop:disable Metrics/AbcSize
      name = presort_grower_grading_pool(id).maf_lot_number
      repo.transaction do
        repo.delete_presort_grower_grading_pool(id)
        log_status(:presort_grower_grading_pools, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted presort grower grading pool #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete presort grower grading pool. It is still referenced#{e.message.partition('referenced').last}")
    end

    def create_presort_grading_pools(maf_lot_numbers) # rubocop:disable Metrics/AbcSize
      return failed_response('Maf lot number selection cannot be empty') if maf_lot_numbers.nil_or_empty?

      repo.transaction do
        maf_lot_numbers.each do |maf_lot_number|
          next if maf_lot_number.nil_or_empty?

          res = CreatePresortGrowerGradingPool.call(maf_lot_number, @user.user_name)
          raise Crossbeams::InfoError, res unless res.success
        end
        log_transaction
      end
      success_response('Created presort grading pools')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      puts e.backtrace.join("\n")
      failed_response(e.message)
    end

    def mark_pool_as_complete(id)
      complete_a_record(:presort_grower_grading_pools, id, status_text: 'GRADED')
    end

    def mark_pool_as_incomplete(id)
      reject_a_record(:presort_grower_grading_pools, id, status_text: 'IN_PROGRESS')
    end

    def import_maf_data(presort_grading_pool_id)
      maf_lot_number = repo.get(:presort_grower_grading_pools, presort_grading_pool_id, :maf_lot_number)
      return failed_response("Maf lot number : #{maf_lot_number} does not exist") if maf_lot_number.nil_or_empty?

      repo.transaction do
        res = PresortMafDataImport.call(maf_lot_number, presort_grading_pool_id, @user.user_name)
        raise Crossbeams::InfoError, res.message unless res.success
      end
      success_response('Imported presort pool data imported successfully')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def refresh_presort_grading(presort_grading_pool_id)
      repo.transaction do
        repo.delete_presort_grower_bins_for(presort_grading_pool_id)
        res = import_maf_data(presort_grading_pool_id)
        raise Crossbeams::InfoError, res.message unless res.success
      end
      success_response('Presort pool data refreshed successfully')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::PresortGrowerGradingPool.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= PresortGrowerGradingRepo.new
    end

    def presort_grower_grading_pool(id)
      repo.find_presort_grower_grading_pool(id)
    end

    def validate_new_presort_grower_grading_pool_params(params)
      NewPresortGrowerGradingPoolSchema.call(params)
    end

    def validate_edit_presort_grower_grading_pool_params(params)
      EditPresortGrowerGradingPoolSchema.call(params)
    end
  end
end
