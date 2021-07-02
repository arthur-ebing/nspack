# frozen_string_literal: true

module MasterfilesApp
  class MasterfileTransformationInteractor < BaseInteractor
    def create_masterfile_transformation(params)
      res = validate_masterfile_transformation_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_masterfile_transformation(res)
        log_status(:masterfile_transformations, id, 'CREATED')
        log_transaction
      end
      instance = masterfile_transformation(id)
      success_response("Created masterfile transformation #{instance.transformation}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { masterfile_table: ['This masterfile transformation already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_masterfile_transformation(id, params)
      res = validate_masterfile_transformation_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_masterfile_transformation(id, res)
        log_transaction
      end
      instance = masterfile_transformation(id)
      success_response("Updated masterfile transformation #{instance.transformation}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_masterfile_transformation(id) # rubocop:disable Metrics/AbcSize
      name = masterfile_transformation(id).transformation
      repo.transaction do
        repo.delete_masterfile_transformation(id)
        log_status(:masterfile_transformations, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted masterfile transformation #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete masterfile transformation. It is still referenced#{e.message.partition('referenced').last}")
    end

    def masterfile_transformation_grid(params = nil)
      rows = repo.select_values(:masterfile_transformations, :id, params)
      row_defs = []
      rows.each do |row_id|
        row_defs << repo.find_masterfile_transformation(row_id).to_h
      end
      {
        columnDefs: col_defs_for_masterfile_transformation_grid,
        rowDefs: row_defs
      }.to_json
    end

    def col_defs_for_masterfile_transformation_grid
      Crossbeams::DataGrid::ColumnDefiner.new.make_columns do |mk|
        mk.action_column do |act|
          act.popup_view_link '/masterfiles/general/masterfile_transformations/$id$', id: 'id'
          act.popup_edit_link '/masterfiles/general/masterfile_transformations/$id$/edit', id: 'id'
          act.popup_delete_link '/masterfiles/general/masterfile_transformations/$id$', id: 'id'
        end
        mk.integer 'id', 'id', hide: true
        mk.integer 'masterfile_id', 'masterfile_id', hide: true
        mk.col 'external_system', 'External system', width: 200
        mk.col 'transformation', 'Transformation', width: 150
        mk.col 'masterfile_code', 'Masterfile code', width: 300
        mk.col 'external_code', 'External code', width: 300
        mk.col 'masterfile_table', 'Masterfile table', width: 200
        mk.col 'created_at', 'Created at', data_type: :datetime
        mk.col 'updated_at', 'Updated at', data_type: :datetime
      end
    end

    def lookup_mf_transformation(table_name)
      repo.lookup_mf_transformation(table_name)
    end

    def select_values(table_name, columns)
      repo.select_values(table_name, columns)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::MasterfileTransformation.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= GeneralRepo.new
    end

    def masterfile_transformation(id)
      repo.find_masterfile_transformation(id)
    end

    def validate_masterfile_transformation_params(params)
      MasterfileTransformationSchema.call(params)
    end
  end
end
