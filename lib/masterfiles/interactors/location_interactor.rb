# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength

module MasterfilesApp
  class LocationInteractor < BaseInteractor
    def create_location_type(params)
      res = validate_location_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_location_type(res)
        log_transaction
      end
      instance = location_type(id)
      success_response("Created location type #{instance.location_type_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { location_type_code: ['This location type already exists'] }))
    end

    def update_location_type(id, params)
      res = validate_location_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_location_type(id, res)
        log_transaction
      end
      instance = location_type(id)
      success_response("Updated location type #{instance.location_type_code}", instance)
    end

    def delete_location_type(id)
      name = location_type(id).location_type_code
      repo.transaction do
        repo.delete_location_type(id)
        log_transaction
      end
      success_response("Deleted location type #{name}")
    end

    def create_root_location(params) # rubocop:disable Metrics/AbcSize
      res = validate_location_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_root_location(res)
        log_transaction
      end
      instance = location(id)
      success_response("Created location #{instance.location_long_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { location_long_code: ['This location already exists: Location Long and Short codes must be Unique'] }))
    rescue Crossbeams::FrameworkError => e
      validation_failed_response(OpenStruct.new(messages: { receiving_bay_type_location: [e.message] }))
    end

    def create_location(parent_id, params) # rubocop:disable Metrics/AbcSize
      res = validate_location_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_child_location(parent_id, res)
        log_transaction
      end
      instance = location(id)
      success_response("Created location #{instance.location_long_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { location_long_code: ['This location already exists: Location Long and Short codes must be Unique'] }))
    rescue Crossbeams::FrameworkError => e
      validation_failed_response(OpenStruct.new(messages: { receiving_bay_type_location: [e.message] }))
    end

    def location_type_code(params)
      repo.find_location_type(params[:location_type_id])&.location_type_code
    end

    def update_location(id, params)
      res = validate_location_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_location(id, res)
        log_transaction
      end
      instance = location(id)
      success_response("Updated location #{instance.location_long_code}", instance)
    rescue Crossbeams::FrameworkError => e
      validation_failed_response(OpenStruct.new(messages: { receiving_bay_type_location: [e.message] }))
    end

    def delete_location(id)
      return failed_response('Cannot delete this location - it has sub-locations') if repo.location_has_children(id)

      name = location(id).location_long_code
      repo.transaction do
        repo.delete_location(id)
        log_transaction
      end
      success_response("Deleted location #{name}")
    end

    def create_location_assignment(params)
      res = validate_location_assignment_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_location_assignment(res)
        log_transaction
      end
      instance = location_assignment(id)
      success_response("Created location assignment #{instance.assignment_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { assignment_code: ['This location assignment already exists'] }))
    end

    def update_location_assignment(id, params)
      res = validate_location_assignment_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_location_assignment(id, res)
        log_transaction
      end
      instance = location_assignment(id)
      success_response("Updated location assignment #{instance.assignment_code}", instance)
    end

    def delete_location_assignment(id)
      name = location_assignment(id).assignment_code
      repo.transaction do
        repo.delete_location_assignment(id)
        log_transaction
      end
      success_response("Deleted location assignment #{name}")
    end

    def create_location_storage_type(params)
      res = validate_location_storage_type_params(params)
      return validation_failed_response(res) if res.failure?

      id = nil
      repo.transaction do
        id = repo.create_location_storage_type(res)
        log_transaction
      end
      instance = location_storage_type(id)
      success_response("Created location storage type #{instance.storage_type_code}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { storage_type_code: ['This location storage type already exists'] }))
    end

    def update_location_storage_type(id, params)
      res = validate_location_storage_type_params(params)
      return validation_failed_response(res) if res.failure?

      repo.transaction do
        repo.update_location_storage_type(id, res)
        log_transaction
      end
      instance = location_storage_type(id)
      success_response("Updated location storage type #{instance.storage_type_code}", instance)
    end

    def delete_location_storage_type(id)
      name = location_storage_type(id).storage_type_code
      repo.transaction do
        repo.delete_location_storage_type(id)
        log_transaction
      end
      success_response("Deleted location storage type #{name}")
    end

    def link_assignments(id, multiselect_ids)
      res = nil
      repo.transaction do
        res = repo.link_assignments(id, multiselect_ids)
      end
      return res unless res.success

      success_response('Assignments linked successfully')
    end

    def link_storage_types(id, multiselect_ids)
      res = nil
      repo.transaction do
        res = repo.link_storage_types(id, multiselect_ids)
      end
      return res unless res.success

      success_response('Storage types linked successfully')
    end

    def location_long_code_suggestion(parent_id, location_type_id)
      res = repo.location_long_code_suggestion(parent_id, location_type_id)
      return res unless res.success

      success_response('See location code suggestion', res.instance)
    end

    def location_short_code_suggestion(storage_type_id)
      res = repo.suggested_short_code(storage_type_id)
      return res unless res.success

      success_response('See location code suggestion', res.instance)
    end

    def print_location_barcode(id, params)
      instance = location(id)
      LabelPrintingApp::PrintLabel.call(AppConst::LABEL_LOCATION_BARCODE, instance, params)
    end

    def print_location_barcode_via_robot(id, ip, params)
      instance = location(id)
      LabelPrintingApp::PrintLabel.call(AppConst::LABEL_LOCATION_BARCODE, instance, params, robot_print_base_ulr(ip))
    end

    def preview_location_barcode(id)
      instance = location(id)
      LabelPrintingApp::PreviewLabel.call(AppConst::LABEL_LOCATION_BARCODE, instance)
    end

    def find_location_children(location_id)
      location_children = repo.descendants_for_ancestor_id(location_id)
      success_response('ok', location_children)
    end

    def location_view_stock_grid(location_id, type)
      col_defs = stock_grid_col_defs(type)
      row_defs = repo.find_location_stock(location_id, type)

      {
        columnDefs: col_defs,
        rowDefs: row_defs
      }.to_json
    end

    private

    def repo
      @repo ||= LocationRepo.new
    end

    def location_type(id)
      repo.find_location_type(id)
    end

    def validate_location_type_params(params)
      LocationTypeSchema.call(params)
    end

    def location(id)
      repo.find_location(id)
    end

    def validate_location_params(params)
      LocationSchema.call(params)
    end

    def location_assignment(id)
      repo.find_location_assignment(id)
    end

    def validate_location_assignment_params(params)
      LocationAssignmentSchema.call(params)
    end

    def location_storage_type(id)
      repo.find_location_storage_type(id)
    end

    def validate_location_storage_type_params(params)
      LocationStorageTypeSchema.call(params)
    end

    def stock_grid_col_defs(type)  # rubocop:disable Metrics/AbcSize
      col_names = stock_grid_col_names(type)

      Crossbeams::DataGrid::ColumnDefiner.new.make_columns do |mk|
        mk.action_column do |act|
          make_actions_for(type).each do |action|
            act.popup_link action[:text],
                           action[:url],
                           col1: action[:col1],
                           icon: action[:icon],
                           title: action[:title]
          end
        end

        make_columns_for(col_names).each do |col|
          mk.col col[:field], col[:options][:caption], col[:options]
        end
      end
    end

    def stock_grid_col_names(type)
      file = if type == 'pallets'
               'grid_definitions/dataminer_queries/all_pallets.yml'
             else
               'grid_definitions/dataminer_queries/rmt_bins.yml'
             end
      persistor = Crossbeams::Dataminer::YamlPersistor.new(file)
      rpt = Crossbeams::Dataminer::Report.load(persistor)
      rpt.columns
    end

    def make_actions_for(type)
      if type == 'pallets'
        actions_for_pallets_grid
      else
        actions_for_rmt_bins_grid
      end
    end

    def actions_for_pallets_grid
      [{
        text: 'sequences',
        url: '/list/pallet_sequences/with_params?key=standard&pallet_id=$col1$',
        col1: 'pallet_id',
        icon: 'list',
        title: 'Pallet sequences'
      }, {
        text: 'status',
        url: '/development/statuses/list/pallets/$col1$',
        col1: 'pallet_id',
        icon: 'information-solid',
        title: 'Status'
      }]
    end

    def actions_for_rmt_bins_grid
      [{
        text: 'view',
        url: '/raw_materials/deliveries/rmt_bins/$col1$',
        col1: 'id',
        icon: 'view-show',
        title: 'View'
      }]
    end

    def make_columns_for(col_names)
      cols = []
      col_names.each { |name, column_def| cols << col_with_attrs(name, column_def) }
      cols
    end

    def col_with_attrs(name, column_def)
      col = { field: name }
      opts = column_def.to_hash
      col.merge(options: opts)
    end
  end
end
# rubocop:enable Metrics/ClassLength
