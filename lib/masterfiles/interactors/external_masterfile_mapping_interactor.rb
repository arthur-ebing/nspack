# frozen_string_literal: true

module MasterfilesApp
  class ExternalMasterfileMappingInteractor < BaseInteractor
    def create_external_masterfile_mapping(params) # rubocop:disable Metrics/AbcSize
      res = validate_external_masterfile_mapping_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_external_masterfile_mapping(res)
        log_status(:external_masterfile_mappings, id, 'CREATED')
        log_transaction
      end
      instance = external_masterfile_mapping(id)
      success_response("Created external masterfile mapping #{instance.masterfile_table}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { masterfile_table: ['This external masterfile mapping already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_external_masterfile_mapping(id, params)
      res = validate_external_masterfile_mapping_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_external_masterfile_mapping(id, res)
        log_transaction
      end
      instance = external_masterfile_mapping(id)
      success_response("Updated external masterfile mapping #{instance.masterfile_table}", instance)
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_external_masterfile_mapping(id) # rubocop:disable Metrics/AbcSize
      name = external_masterfile_mapping(id).masterfile_table
      repo.transaction do
        repo.delete_external_masterfile_mapping(id)
        log_status(:external_masterfile_mappings, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted external masterfile mapping #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    rescue Sequel::ForeignKeyConstraintViolation => e
      puts e.message
      failed_response("Unable to delete external masterfile mapping. It is still referenced#{e.message.partition('referenced').last}")
    end

    def external_masterfile_mapping_grid(params = nil)
      rows = repo.select_values(:external_masterfile_mappings, :id, params)
      row_defs = []
      rows.each do |row_id|
        row_defs << repo.find_external_masterfile_mapping(row_id).to_h
      end
      {
        columnDefs: col_defs_for_external_masterfile_mapping_grid,
        rowDefs: row_defs
      }.to_json
    end

    def col_defs_for_external_masterfile_mapping_grid
      Crossbeams::DataGrid::ColumnDefiner.new.make_columns do |mk|
        mk.action_column do |act|
          act.popup_view_link '/masterfiles/general/external_masterfile_mappings/$id$', id: 'id'
          act.popup_edit_link '/masterfiles/general/external_masterfile_mappings/$id$/edit', id: 'id'
          act.popup_delete_link '/masterfiles/general/external_masterfile_mappings/$id$', id: 'id'
        end
        mk.integer 'id', 'id', hide: true
        mk.integer 'masterfile_id', 'masterfile_id', hide: true
        mk.col 'external_system', 'External system', width: 200
        mk.col 'mapping', 'Mapping', width: 150
        mk.col 'masterfile_code', 'Masterfile code', width: 300
        mk.col 'external_code', 'External code', width: 300
        mk.col 'masterfile_table', 'Masterfile table', width: 200
        mk.col 'created_at', 'Created at', data_type: :datetime
        mk.col 'updated_at', 'Updated at', data_type: :datetime
      end
    end

    def lookup_mf_mapping(table_name)
      repo.lookup_mf_mapping(table_name)
    end

    def select_values(table_name, columns)
      repo.select_values(table_name, columns)
    end

    def assert_permission!(task, id = nil)
      res = TaskPermissionCheck::ExternalMasterfileMapping.call(task, id)
      raise Crossbeams::TaskNotPermittedError, res.message unless res.success
    end

    private

    def repo
      @repo ||= GeneralRepo.new
    end

    def external_masterfile_mapping(id)
      repo.find_external_masterfile_mapping(id)
    end

    def validate_external_masterfile_mapping_params(params)
      ExternalMasterfileMappingSchema.call(params)
    end
  end
end
