# frozen_string_literal: true

module MasterfilesApp
  class MasterfileVariantInteractor < BaseInteractor
    def create_masterfile_variant(params) # rubocop:disable Metrics/AbcSize
      res = validate_masterfile_variant_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_masterfile_variant(res)
        log_status(:masterfile_variants, id, 'CREATED')
        log_transaction
      end
      instance = masterfile_variant(id)
      success_response("Created masterfile variant #{instance.masterfile_table}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { variant_code: ['This variant code already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def update_masterfile_variant(id, params) # rubocop:disable Metrics/AbcSize
      res = validate_masterfile_variant_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_masterfile_variant(id, res)
        log_transaction
      end
      instance = masterfile_variant(id)
      success_response("Updated masterfile variant #{instance.variant_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { variant_code: ['This variant code already exists'] }))
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def delete_masterfile_variant(id)
      name = masterfile_variant(id).variant_code
      repo.transaction do
        repo.delete_masterfile_variant(id)
        log_status(:masterfile_variants, id, 'DELETED')
        log_transaction
      end
      success_response("Deleted masterfile variant #{name}")
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def masterfile_variant_grid(params = nil)
      rows = repo.select_values(:masterfile_variants, :id, params)
      row_defs = []
      rows.each do |row_id|
        row_defs << repo.find_masterfile_variant_flat(row_id).to_h
      end
      {
        columnDefs: col_defs_for_masterfile_variant_grid,
        rowDefs: row_defs
      }.to_json
    end

    def col_defs_for_masterfile_variant_grid
      Crossbeams::DataGrid::ColumnDefiner.new.make_columns do |mk|
        mk.action_column do |act|
          act.popup_view_link '/masterfiles/general/masterfile_variants/$id$', id: 'id'
          act.popup_edit_link '/masterfiles/general/masterfile_variants/$id$/edit', id: 'id'
          act.popup_delete_link '/masterfiles/general/masterfile_variants/$id$', id: 'id'
        end
        mk.integer 'id', 'id', hide: true
        mk.integer 'masterfile_id', 'masterfile_id', hide: true
        mk.col 'variant', 'Variant', width: 120
        mk.col 'masterfile_code', 'Masterfile code', width: 300
        mk.col 'variant_code', 'Variant code', width: 300
        mk.col 'masterfile_table', 'Masterfile table', width: 200
        mk.col 'created_at', 'Created at', data_type: :datetime
        mk.col 'updated_at', 'Updated at', data_type: :datetime
      end
    end

    private

    def repo
      @repo ||= MasterfileVariantRepo.new
    end

    def masterfile_variant(id)
      repo.find_masterfile_variant_flat(id)
    end

    def validate_masterfile_variant_params(params)
      MasterfileVariantSchema.call(params)
    end
  end
end
