# frozen_string_literal: true

module QualityApp
  class QcTestInteractor < BaseInteractor
    def create_qc_test(params)
      res = validate_qc_test_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_qc_test(res)
        log_status(:qc_tests, id, 'CREATED')
        log_transaction
      end
      instance = qc_test(id)
      success_response("Created qc test #{instance.id}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { id: ['This qc test already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_qc_test(id, params)
      res = validate_qc_test_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_qc_test(id, res)
        log_transaction
      end
      instance = qc_test(id)
      success_response("Updated qc test #{instance.id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_qc_test_sample_size(id, params)
      res = UtilityFunctions.validate_integer_length(:sample_size, params[:sample_size])
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_qc_test(id, res)
        log_transaction
      end
      instance = qc_test(id)
      success_response("Updated qc test #{instance.id}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_qc_test(id) # rubocop:disable Metrics/AbcSize
      name = qc_test(id).id
      repo.transaction do
        repo.delete_qc_test(id)
        log_status(:qc_tests, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted qc test #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete qc test. It is still referenced#{e.message.partition('referenced').last}")
    end

    def find_or_create_test(qc_sample_id, qc_test_type)
      test_type_id = repo.get_id(:qc_test_types, qc_test_type_name: qc_test_type)
      test_id = repo.find_sample_test_of_type(qc_sample_id, test_type_id)
      return test_id unless test_id.nil?

      repo.transaction do
        test_id = repo.create_qc_test(qc_sample_id: qc_sample_id, qc_test_type_id: test_type_id, sample_size: 20)
        log_status(:qc_samples, qc_sample_id, "CREATED TEST #{qc_test_type}")
        log_transaction
      end
      test_id
    end

    def save_starch_test(id, params) # rubocop:disable Metrics/AbcSize
      res = QcStarchTestContract.new.call(params)
      return validation_failed_response(res) if res.failure?

      # check sample size vs total
      current_set = Hash[repo.select_values(:qc_starch_measurements, %i[starch_percentage qty_fruit_with_percentage], qc_test_id: id)]
      selection = params.keys.select { |k| k.to_s.start_with?('percentage') }

      repo.transaction do
        repo.update_qc_test(id, sample_size: res[:sample_size])
        selection.each do |sel|
          perc = sel.to_s.delete_prefix('percentage').to_i
          val = params[sel].empty? ? 0 : params[sel].to_i
          if current_set[perc]
            if current_set[perc] != params[sel].to_i
              m_id = repo.get_id(:qc_starch_measurements, qc_test_id: id, starch_percentage: perc)
              repo.update_qc_starch_measurement(m_id, qty_fruit_with_percentage: val)
            end
          else
            repo.create_qc_starch_measurement(qc_test_id: id, starch_percentage: perc, qty_fruit_with_percentage: val)
          end
        end
        current_set.each_key do |k|
          next if params["percentage#{k}".to_sym]

          m_id = repo.get_id(:qc_starch_measurements, qc_test_id: id, starch_percentage: k)
          repo.delete_qc_starch_measurement(m_id)
        end
      end
      success_response('Starch test saved')
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::QcTest.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    def defects_grid(qc_test_id)
      # extraContext: { keyColumn: 'id' },
      {
        fieldUpdateUrl: "/quality/qc/qc_tests/#{qc_test_id}/inline_defect/$:id$",
        columnDefs: col_defs_for_defects_grid,
        rowDefs: repo.rows_for_defects_test(qc_test_id)
      }.to_json
    end

    def save_defect_measure(qc_test_id, fruit_defect_id, params) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      id = repo.get_id(:qc_defect_measurements, qc_test_id: qc_test_id, fruit_defect_id: fruit_defect_id)
      col = params[:column_name].to_sym

      res = UtilityFunctions.validate_integer_length(col, params[:column_value])
      return validation_failed_response(res) if res.failure?

      can_do2, can_do3 = repo.get(:fruit_defects, fruit_defect_id, %i[qc_class_2 qc_class_3])
      case col
      when :qty_class_2
        return validation_failed_message_response('Cannot capture class 2 for this defect') unless can_do2
      when :qty_class_3
        return validation_failed_message_response('Cannot capture class 3 for this defect') unless can_do3
      else
        raise Crossbeams::FrameworkError, "No handler for editing column #{col}"
      end
      sample_size = repo.get(:qc_tests, qc_test_id, :sample_size)
      return validation_failed_message_response('Cannot capture a quantity more than the sample size') if res[col] > sample_size

      if id.nil?
        repo.create_qc_defect_measurement(res.to_h.merge(qc_test_id: qc_test_id, fruit_defect_id: fruit_defect_id))
      else
        repo.update_qc_defect_measurement(id, res)
      end
      success_response("Changed #{col}")
    end

    private

    def col_defs_for_defects_grid
      Crossbeams::DataGrid::ColumnDefiner.new.make_columns do |mk|
        mk.integer :id, 'ID', hide: true
        mk.col :defect_category, 'Category', groupable: true, width: 100
        mk.col :fruit_defect_type_name, 'Type', groupable: true
        mk.col :fruit_defect_code, 'Code', width: 100
        mk.col :short_description, 'Description'
        mk.boolean :internal, 'Int?', groupable: true
        mk.boolean :external, 'Ext?', groupable: true
        mk.boolean :pre_harvest, 'Pre?', groupable: true
        mk.boolean :post_harvest, 'Post?', groupable: true
        mk.col :severity, 'Severity', groupable: true, width: 100
        mk.boolean :qc_class_2, 'CL2?', groupable: true
        mk.integer :qty_class_2, 'CL2 Qty', editable: true
        mk.boolean :qc_class_3, 'CL3?', groupable: true
        mk.integer :qty_class_3, 'CL3 Qty', editable: true
      end
    end

    def repo
      @repo ||= QcRepo.new
    end

    def qc_test(id)
      repo.find_qc_test(id)
    end

    def validate_qc_test_params(params)
      QcTestSchema.call(params)
    end
  end
end
