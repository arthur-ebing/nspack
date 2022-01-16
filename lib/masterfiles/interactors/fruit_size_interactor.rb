# frozen_string_literal: true

module MasterfilesApp
  class FruitSizeInteractor < BaseInteractor
    def create_std_fruit_size_count(params)
      res = validate_std_fruit_size_count_params(params)
      return validation_failed_response(res) if res.failure?

      id = repo.create_std_fruit_size_count(res)
      instance = std_fruit_size_count(id)
      success_response("Created std fruit size count #{instance.size_count_description}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { size_count_description: ['This std fruit size count already exists'] }))
    end

    def update_std_fruit_size_count(id, params)
      res = validate_std_fruit_size_count_params(params)
      return validation_failed_response(res) if res.failure?

      repo.update_std_fruit_size_count(id, res)
      instance = std_fruit_size_count(id)
      success_response("Updated std fruit size count #{instance.size_count_description}", instance)
    end

    def delete_std_fruit_size_count(id)
      name = std_fruit_size_count(id).size_count_description
      repo.delete_std_fruit_size_count(id)
      success_response("Deleted std fruit size count #{name}")
    end

    def create_fruit_actual_counts_for_pack(parent_id, params)
      params[:std_fruit_size_count_id] = parent_id
      res = validate_fruit_actual_counts_for_pack_params(params)
      return validation_failed_response(res) if res.failure?

      id = repo.create_fruit_actual_counts_for_pack(res)
      instance = fruit_actual_counts_for_pack(id)
      success_response("Created fruit actual counts for pack #{instance.id}", instance)
    rescue Sequel::UniqueConstraintViolation
      validation_failed_response(OpenStruct.new(messages: { actual_count_for_pack: ['This fruit actual counts for pack already exists'] }))
    end

    def update_fruit_actual_counts_for_pack(id, params)
      res = validate_fruit_actual_counts_for_pack_params(params)
      return validation_failed_response(res) if res.failure?

      repo.update_fruit_actual_counts_for_pack(id, res)
      instance = fruit_actual_counts_for_pack(id)
      success_response("Updated fruit actual counts for pack #{instance.id}", instance)
    end

    def delete_fruit_actual_counts_for_pack(id)
      name = fruit_actual_counts_for_pack(id).id
      repo.delete_fruit_actual_counts_for_pack(id)
      success_response("Deleted fruit actual counts for pack #{name}")
    end

    def sync_pm_boms
      repo.transaction do
        boms_repo.sync_pm_boms
      end
      success_response('Successfully synced PKG BOMs')
    rescue Crossbeams::InfoError => e
      failed_response(e.message)
    end

    def for_select_standard_packs(where: {})
      repo.for_select_standard_packs(where: where)
    end

    def validate_standard_and_actual_counts(params) # rubocop:disable Metrics/AbcSize
      res = validate_standard_and_actual_count_params(params)
      return unwrap_failed_response(validation_failed_response(res)) if res.failure?
      return validation_failed_message_response(list_of_counts: ['must be just counts separated by commas']) unless res[:list_of_counts].match?(/^\d+\s?(,\s?\d+\s?)*$/)

      list = res[:list_of_counts].split(',').map { |c| c.strip.to_i }
      return validation_failed_message_response(list_of_counts: ['cannot contain duplicates']) if list.length != list.uniq.length

      # Do any of these actual counts already exist?
      current_counts = repo.actual_and_standard_counts_for(res[:commodity_id], res[:standard_pack_code_id])
      dups = []
      current_counts.each do |rec|
        dups << rec[:actual_count_for_pack] if list.include?(rec[:actual_count_for_pack])
      end
      return validation_failed_message_response(list_of_counts: ["cannot add existing counts: #{dups.join(', ')}"]) unless dups.empty?

      ok_response
    end

    def counts_grid(params)
      res = validate_standard_and_actual_count_params(params)
      raise Crossbeams::InfoError, unwrap_failed_response(validation_failed_response(res)) if res.failure?

      commodity_id = res[:commodity_id]
      standard_pack_code_id = res[:standard_pack_code_id]
      list_of_counts = res[:list_of_counts].strip.split(',').map(&:to_i)

      {
        fieldUpdateUrl: "/masterfiles/fruit/setup_standard_and_actual_counts/inline_edit/#{commodity_id}/#{standard_pack_code_id}/$:id$",
        columnDefs: col_defs_for_counts_grid,
        rowDefs: rows_for_counts_grid(commodity_id, standard_pack_code_id, list_of_counts)
      }.to_json
    end

    def add_actual_and_standard_counts(commodity_id, standard_pack_code_id, actual_count, std_count)
      repo.transaction do
        uom_id = repo.get_id(:uoms, uom_code: AppConst::DEFAULT_UOM_CODE)
        std_id = repo.get_id(:std_fruit_size_counts, commodity_id: commodity_id, size_count_value: std_count)
        std_id = repo.create(:std_fruit_size_counts, commodity_id: commodity_id, size_count_value: std_count, uom_id: uom_id) if std_id.nil?
        # NOTE: This will not work if AppConst::CR_MF.basic_pack_equals_standard_pack? - could return > 1 base pack...
        base_id = repo.get_value(:basic_packs_standard_packs, :basic_pack_id, standard_pack_id: standard_pack_code_id)
        repo.create(:fruit_actual_counts_for_packs, std_fruit_size_count_id: std_id, basic_pack_code_id: base_id, actual_count_for_pack: actual_count, standard_pack_code_ids: [standard_pack_code_id])
      end
      success_response('Added actual and standard counts')
    end

    private

    def col_defs_for_counts_grid
      Crossbeams::DataGrid::ColumnDefiner.new.make_columns do |mk|
        mk.integer :id, 'ID', hide: true
        mk.boolean :exists, 'Exists?', groupable: true
        mk.integer :actual_count, 'Actual Count', width: 150
        mk.integer :standard_count, 'Standard Count', editable: true, width: 150
      end
    end

    def rows_for_counts_grid(commodity_id, standard_pack_code_id, list_of_counts)
      rows = list_of_counts.map do |count|
        { id: "n#{count}", exists: false, actual_count: count, standard_count: nil }
      end

      repo.actual_and_standard_counts_for(commodity_id, standard_pack_code_id).each do |rec|
        rows << { id: "e#{rec[:id]}",
                  exists: true,
                  actual_count: rec[:actual_count_for_pack],
                  standard_count: rec[:size_count_value] }
      end
      rows
    end

    def repo
      @repo ||= FruitSizeRepo.new
    end

    def boms_repo
      @boms_repo ||= BomRepo.new
    end

    def std_fruit_size_count(id)
      repo.find_std_fruit_size_count(id)
    end

    def validate_std_fruit_size_count_params(params)
      StdFruitSizeCountSchema.call(params)
    end

    def fruit_actual_counts_for_pack(id)
      repo.find_fruit_actual_counts_for_pack(id)
    end

    def validate_fruit_actual_counts_for_pack_params(params)
      FruitActualCountsForPackSchema.call(params)
    end

    def validate_standard_and_actual_count_params(params)
      Dry::Schema.Params do
        required(:commodity_id).filled(:integer)
        required(:standard_pack_code_id).filled(:integer)
        required(:list_of_counts).filled(:string)
      end.call(params)
    end
  end
end
