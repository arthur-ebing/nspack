# frozen_string_literal: true

module QualityApp
  class QcSampleInteractor < BaseInteractor
    def create_qc_sample(params)
      res = validate_qc_sample_params(params)
      return validation_failed_response(res) if res.failure?

      # Check that a sample does not already exist for same context and type
      id = nil
      repo.transaction do
        id = repo.create_qc_sample(res)
        log_status(:qc_samples, id, 'CREATED')
        log_transaction
      end
      instance = qc_sample(id)
      success_response('Created qc sample', qc_sample_created_redirect(instance))
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { presort_run_lot_number: ['This qc sample already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_qc_sample(id, params)
      res = validate_qc_sample_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_qc_sample(id, res)
        log_transaction
      end
      instance = qc_sample(id)
      success_response("Updated qc sample #{instance.presort_run_lot_number}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_qc_sample(id) # rubocop:disable Metrics/AbcSize
      name = qc_sample(id).presort_run_lot_number
      repo.transaction do
        repo.delete_qc_sample(id)
        log_status(:qc_samples, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted qc sample #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete qc sample. It is still referenced#{e.message.partition('referenced').last}")
    end

    # def complete_a_qc_sample(id, params)
    #   res = complete_a_record(:qc_samples, id, params.merge(enqueue_job: false))
    #   if res.success
    #     success_response(res.message, qc_sample(id))
    #   else
    #     failed_response(res.message, qc_sample(id))
    #   end
    # end

    # def reopen_a_qc_sample(id, params)
    #   res = reopen_a_record(:qc_samples, id, params.merge(enqueue_job: false))
    #   if res.success
    #     success_response(res.message, qc_sample(id))
    #   else
    #     failed_response(res.message, qc_sample(id))
    #   end
    # end

    # def approve_or_reject_a_qc_sample(id, params)
    #   res = if params[:approve_action] == 'a'
    #           approve_a_record(:qc_samples, id, params.merge(enqueue_job: false))
    #         else
    #           reject_a_record(:qc_samples, id, params.merge(enqueue_job: false))
    #         end
    #   if res.success
    #     success_response(res.message, qc_sample(id))
    #   else
    #     failed_response(res.message, qc_sample(id))
    #   end
    # end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::QcSample.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def print_sample_barcode(id, params)
      instance = repo.find_qc_sample_label(id)
      LabelPrintingApp::PrintLabel.call(params[:label_name], instance, params)
    end

    def create_test_for_sample(id, params)
      instance = qc_sample(id)
      test_id = nil
      test_type = repo.get(:qc_test_types, params[:qc_test_type_id], :qc_test_type_name)
      repo.transaction do
        test_id = repo.create_qc_test(params.merge(qc_sample_id: id, sample_size: instance.sample_size))
        log_status(:qc_samples, id, "CREATED TEST #{test_type}")
        log_transaction
      end
      success_response('Created test', test_id: test_id, test_type: test_type)
    end

    def find_test_for_sample(id, test_type) # rubocop:disable Metrics/AbcSize
      res = UtilityFunctions.validate_integer_length(:sample, id)
      return res if res.failure?

      sample = qc_sample(id)
      return failed_response('Sample does not exist') if sample.nil?

      test_type_id = repo.get_id(:qc_test_types, qc_test_type_name: test_type)
      test_id = repo.find_sample_test_of_type(id, test_type_id)
      return success_response('Found test', test_id: test_id, test_type: test_type) unless test_id.nil?

      raise Crossbeams::FrameworkError, "There is no test type named #{test_type}" if test_type_id.nil?

      repo.transaction do
        test_id = repo.create_qc_test(qc_sample_id: id, qc_test_type_id: test_type_id, sample_size: sample.sample_size) # TODO: other attributes for instrument...
        log_status(:qc_samples, id, "CREATED TEST #{test_type}")
        log_transaction
      end
      success_response('Created test', test_id: test_id, test_type: test_type) unless test_id.nil?
    end

    private

    def repo
      @repo ||= QcRepo.new
    end

    def qc_sample(id)
      repo.find_qc_sample(id)
    end

    def validate_qc_sample_params(params)
      QcSampleSchema.call(params)
    end

    # After creating a QC sample, calculate the route to be redirected.
    def qc_sample_created_redirect(instance)
      return "/raw_materials/deliveries/rmt_deliveries/#{instance.rmt_delivery_id}" if instance.rmt_delivery_id

      '/'
    end
  end
end
