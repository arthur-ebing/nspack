# frozen_string_literal: true

module MasterfilesApp
  class QcInteractor < BaseInteractor
    def create_qc_measurement_type(params)
      res = validate_qc_measurement_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_qc_measurement_type(res)
        log_status(:qc_measurement_types, id, 'CREATED')
        log_transaction
      end
      instance = qc_measurement_type(id)
      success_response("Created qc measurement type #{instance.qc_measurement_type_name}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { qc_measurement_type_name: ['This qc measurement type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_qc_measurement_type(id, params)
      res = validate_qc_measurement_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_qc_measurement_type(id, res)
        log_transaction
      end
      instance = qc_measurement_type(id)
      success_response("Updated qc measurement type #{instance.qc_measurement_type_name}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_qc_measurement_type(id) # rubocop:disable Metrics/AbcSize
      name = qc_measurement_type(id).qc_measurement_type_name
      repo.transaction do
        repo.delete_qc_measurement_type(id)
        log_status(:qc_measurement_types, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted qc measurement type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete qc measurement type. It is still referenced#{e.message.partition('referenced').last}")
    end

    def create_qc_sample_type(params)
      res = validate_qc_sample_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_qc_sample_type(res)
        log_status(:qc_sample_types, id, 'CREATED')
        log_transaction
      end
      instance = qc_sample_type(id)
      success_response("Created qc sample type #{instance.qc_sample_type_name}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { qc_sample_type_name: ['This qc sample type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_qc_sample_type(id, params)
      res = validate_qc_sample_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_qc_sample_type(id, res)
        log_transaction
      end
      instance = qc_sample_type(id)
      success_response("Updated qc sample type #{instance.qc_sample_type_name}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_qc_sample_type(id) # rubocop:disable Metrics/AbcSize
      name = qc_sample_type(id).qc_sample_type_name
      repo.transaction do
        repo.delete_qc_sample_type(id)
        log_status(:qc_sample_types, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted qc sample type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete qc sample type. It is still referenced#{e.message.partition('referenced').last}")
    end

    def create_qc_test_type(params)
      res = validate_qc_test_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_qc_test_type(res)
        log_status(:qc_test_types, id, 'CREATED')
        log_transaction
      end
      instance = qc_test_type(id)
      success_response("Created qc test type #{instance.qc_test_type_name}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { qc_test_type_name: ['This qc test type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_qc_test_type(id, params)
      res = validate_qc_test_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_qc_test_type(id, res)
        log_transaction
      end
      instance = qc_test_type(id)
      success_response("Updated qc test type #{instance.qc_test_type_name}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_qc_test_type(id) # rubocop:disable Metrics/AbcSize
      name = qc_test_type(id).qc_test_type_name
      repo.transaction do
        repo.delete_qc_test_type(id)
        log_status(:qc_test_types, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted qc test type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete qc test type. It is still referenced#{e.message.partition('referenced').last}")
    end

    def create_fruit_defect_category(params)
      res = validate_fruit_defect_category_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_fruit_defect_category(res)
        log_status(:fruit_defect_categories, id, 'CREATED')
        log_transaction
      end
      instance = fruit_defect_category(id)
      success_response("Created fruit defect category #{instance.defect_category}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { defect_category: ['This fruit defect category already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_fruit_defect_category(id, params)
      res = validate_fruit_defect_category_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_fruit_defect_category(id, res)
        log_transaction
      end
      instance = fruit_defect_category(id)
      success_response("Updated fruit defect category #{instance.defect_category}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_fruit_defect_category(id) # rubocop:disable Metrics/AbcSize
      name = fruit_defect_category(id).defect_category
      repo.transaction do
        repo.delete_fruit_defect_category(id)
        log_status(:fruit_defect_categories, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted fruit defect category #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete fruit defect category. It is still referenced#{e.message.partition('referenced').last}")
    end

    def create_fruit_defect_type(params)
      res = validate_fruit_defect_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_fruit_defect_type(res)
        log_status(:fruit_defect_types, id, 'CREATED')
        log_transaction
      end
      instance = fruit_defect_type(id)
      success_response("Created fruit defect type #{instance.fruit_defect_type_name}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { fruit_defect_type_name: ['This fruit defect type already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_fruit_defect_type(id, params)
      res = validate_fruit_defect_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_fruit_defect_type(id, res)
        log_transaction
      end
      instance = fruit_defect_type(id)
      success_response("Updated fruit defect type #{instance.fruit_defect_type_name}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_fruit_defect_type(id) # rubocop:disable Metrics/AbcSize
      name = fruit_defect_type(id).fruit_defect_type_name
      repo.transaction do
        repo.delete_fruit_defect_type(id)
        log_status(:fruit_defect_types, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted fruit defect type #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete fruit defect type. It is still referenced#{e.message.partition('referenced').last}")
    end

    def create_fruit_defect(params)
      res = validate_fruit_defect_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_fruit_defect(res)
        log_status(:fruit_defects, id, 'CREATED')
        log_transaction
      end
      instance = fruit_defect(id)
      success_response("Created fruit defect #{instance.fruit_defect_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { fruit_defect_code: ['This fruit defect already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_fruit_defect(id, params)
      res = validate_fruit_defect_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_fruit_defect(id, res)
        log_transaction
      end
      instance = fruit_defect(id)
      success_response("Updated fruit defect #{instance.fruit_defect_code}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_fruit_defect(id) # rubocop:disable Metrics/AbcSize
      name = fruit_defect(id).fruit_defect_code
      repo.transaction do
        repo.delete_fruit_defect(id)
        log_status(:fruit_defects, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted fruit defect #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete fruit defect. It is still referenced#{e.message.partition('referenced').last}")
    end

    def assert_permission!(masterfile, task, id = nil) # rubocop:disable Metrics/CyclomaticComplexity
      res = case masterfile
            when :qc_measurement_type
              TaskPermissionCheck::QcMeasurementType.call(task, id)
            when :qc_sample_type
              TaskPermissionCheck::QcSampleType.call(task, id)
            when :qc_test_type
              TaskPermissionCheck::QcTestType.call(task, id)
            when :fruit_defect_category
              TaskPermissionCheck::FruitDefectCategory.call(task, id)
            when :fruit_defect_type
              TaskPermissionCheck::FruitDefectType.call(task, id)
            when :fruit_defect
              TaskPermissionCheck::FruitDefect.call(task, id)
            else
              raise Crossbeams::FrameworkError, "QcInteractor: unknown masterfile #{masterfile} for assert."
            end
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= QcRepo.new
    end

    def qc_measurement_type(id)
      repo.find_qc_measurement_type(id)
    end

    def validate_qc_measurement_type_params(params)
      QcMeasurementTypeSchema.call(params)
    end

    def qc_sample_type(id)
      repo.find_qc_sample_type(id)
    end

    def validate_qc_sample_type_params(params)
      QcSampleTypeSchema.call(params)
    end

    def qc_test_type(id)
      repo.find_qc_test_type(id)
    end

    def validate_qc_test_type_params(params)
      QcTestTypeSchema.call(params)
    end

    def fruit_defect_type(id)
      repo.find_fruit_defect_type_flat(id)
    end

    def validate_fruit_defect_type_params(params)
      FruitDefectTypeSchema.call(params)
    end

    def fruit_defect(id)
      repo.find_fruit_defect(id)
    end

    def validate_fruit_defect_params(params)
      FruitDefectSchema.call(params)
    end

    def fruit_defect_category(id)
      repo.find_fruit_defect_category(id)
    end

    def validate_fruit_defect_category_params(params)
      FruitDefectCategorySchema.call(params)
    end
  end
end
