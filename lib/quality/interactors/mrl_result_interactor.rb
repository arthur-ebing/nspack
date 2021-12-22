# frozen_string_literal: true

module QualityApp
  class MrlResultInteractor < BaseInteractor
    def validate_existing_mrl_result(params)
      res = validate_mrl_result_params(params)
      return validation_failed_response(res) if res.failure?

      attrs = res.to_h
      args = attrs[:pre_harvest_result] ? attrs.slice(:farm_id, :orchard_id) : attrs.slice(:production_run_id)
      attrs[:existing_id] = repo.look_for_existing_mrl_result_id(args)

      success_response('Found existing mrl result', attrs)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def create_mrl_result(params) # rubocop:disable Metrics/AbcSize
      res = validate_mrl_result_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_mrl_result(res)
        log_status(:mrl_results, id, "MRL CREATED: num ingredients: #{res[:num_active_ingredients]}")
        log_transaction
      end
      instance = mrl_result(id)
      success_response("Created mrl result #{instance.waybill_number}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { waybill_number: ['This mrl result already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_mrl_result(id, params)
      res = validate_mrl_result_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_mrl_result(id, res)
        log_status(:mrl_results, id, "MRL UPDATED: num ingredients: #{res[:num_active_ingredients]}")
        log_transaction
      end
      instance = mrl_result(id)
      success_response("Updated mrl result #{instance.waybill_number}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_mrl_result(id) # rubocop:disable Metrics/AbcSize
      name = mrl_result(id).waybill_number
      repo.transaction do
        repo.delete_mrl_result(id)
        log_status(:mrl_results, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted mrl result #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete mrl result. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::MrlResult.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def delivery_mrl_result_attrs(delivery_id)
      arr = %i[farm_id puc_id orchard_id cultivar_id season_id reference_number date_delivered]
      attrs = repo.mrl_result_attrs_for(delivery_id, arr)

      success_response('Ok', attrs.merge({ rmt_delivery_id: delivery_id,
                                           fruit_received_at: attrs[:date_delivered],
                                           sample_submitted_at: Time.now,
                                           result_received_at: Time.now }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def print_mrl_result_label(mrl_result_id, params) # rubocop:disable Metrics/AbcSize
      instance = repo.find_mrl_result_label_data(mrl_result_id)
      label_name = repo.get(:label_templates, params[:label_template_id], :label_template_name)

      LabelPrintingApp::PrintLabel.call(label_name, instance, no_of_prints: params[:no_of_prints].to_i, printer: params[:printer])
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue StandardError => e
      ErrorMailer.send_exception_email(e, subject: self.class.name, message: decorate_mail_message(__method__))
      failed_response(e.message)
    end

    private

    def repo
      @repo ||= MrlResultRepo.new
    end

    def mrl_result(id)
      repo.find_mrl_result(id)
    end

    def validate_mrl_result_params(params)
      MrlResultSchema.call(params)
    end
  end
end
