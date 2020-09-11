# frozen_string_literal: true

module EdiApp
  class ViewerInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def edi_upload(params)
      # res = validate_edi_upload_params(params)
      # p res
      # return validation_failed_response(res) if res.failure?
      # unless params[:convert] && params[:convert][:file] &&
      #        (tempfile = params[:convert][:file][:tempfile]) &&
      #        (filename = params[:convert][:file][:filename])

      # repo = EdiApp::FlatFileRepo.new(params[:flow_type])
      # repo.records_from_file(params[:file_name])
      # grd = repo.grid_cols_and_rows
      # success_response('ok', grd)
      success_response('ok', flow_type: params[:flow_type], fn: params[:file_name][:tempfile], upload_name: params[:file_name][:filename])
    end

    def build_grids_for(flow_type, file_name, upload_name: nil)
      repo = EdiApp::FlatFileRepo.new(flow_type)
      repo.records_from_file(file_name)
      OpenStruct.new(
        grd: repo.grid_cols_and_rows,
        flow_type: flow_type,
        file_name: upload_name || file_name
      )
    end

    def csv_grid(file_name)
      recs = CSV.read(file_name, headers: true)
      {
        columnDefs: grid_columns_for_csv(recs.first),
        rowDefs: recs.map { |r| Hash[r.to_a] }
      }.to_json
    end

    def file_path_from_in_transaction(id)
      repo = EdiInRepo.new
      tran = repo.find_edi_in_transaction(id)
      return failed_response('This transaction does not exist') if tran.nil?

      file_path = repo.file_path_for_edi_in_transaction(id)
      success_response('ok', flow_type: tran.flow_type, file_path: file_path)
    end

    def recent_sent_files
      recent_edi_files(true)
    end

    def recent_received_files
      recent_edi_files(false)
    end

    def received_files_in_error
      error_in_edi_files
    end

    def search_sent_files(search_term)
      search_edi_files(true, search_term)
    end

    def search_received_files(search_term)
      search_edi_files(false, search_term)
    end

    def search_sent_files_for_content(search_term)
      search_edi_files_for_content(true, search_term)
    end

    def search_received_files_for_content(search_term)
      search_edi_files_for_content(false, search_term)
    end

    private

    def recent_edi_files(for_send)
      edi_files = []
      row_count = 0
      edi_paths(for_send: for_send).each do |path|
        Pathname.glob(path + '*').sort_by(&:mtime).reverse.take(20).each do |file|
          edi_files << file_row_for_grid(file, edi_in: !for_send, edi_out: for_send) { row_count += 1 }
        end
      end

      {
        columnDefs: grid_columns_for_edi_files,
        rowDefs: edi_files
      }.to_json
    end

    def error_in_edi_files
      edi_files = []
      row_count = 0
      [Pathname.new(AppConst::EDI_RECEIVE_DIR).parent + 'process_errors'].each do |path|
        Pathname.glob(path + '*').sort_by(&:mtime).reverse.take(20).each do |file|
          edi_files << file_row_for_grid(file, edi_in: true, in_error: true) { row_count += 1 }
        end
      end

      {
        columnDefs: grid_columns_for_edi_files,
        rowDefs: edi_files
      }.to_json
    end

    def search_edi_files(for_send, search_term)
      edi_files = []
      row_count = 0
      edi_paths(for_send: for_send).each do |path|
        path.find do |file|
          next unless file.fnmatch("*#{search_term}*")
          next unless file.file?

          edi_files << file_row_for_grid(file, edi_in: !for_send, edi_out: for_send) { row_count += 1 }
        end
      end

      {
        columnDefs: grid_columns_for_edi_files,
        rowDefs: edi_files
      }.to_json
    end

    def search_edi_files_for_content(for_send, search_term)
      edi_files = []
      row_count = 0
      cmd = "grep -hrn #{search_term} #{edi_paths(for_send: for_send).join(' ')} -l"
      files = `#{cmd}`.split("\n")
      files.each do |str_file|
        file = Pathname.new(str_file)
        edi_files << file_row_for_grid(file, edi_in: !for_send, edi_out: for_send) { row_count += 1 }
      end

      {
        columnDefs: grid_columns_for_edi_files,
        rowDefs: edi_files
      }.to_json
    end

    def edi_config_for_send
      config = EdiOutRepo.new.load_config
      [config, Pathname.new(config[:root].sub('$HOME', ENV['HOME']))]
    end

    def edi_path_list(config, root, key, suffix)
      dirs = config["#{key}_dirs".to_sym].values

      dirs.uniq.map { |p| Pathname.new(p.sub('$ROOT', root.to_s)) + suffix }
    end

    def edi_paths(for_send: true)
      if for_send
        config, root = edi_config_for_send
        edi_path_list(config, root, :out, 'transmitted')
      else
        [Pathname.new(AppConst::EDI_RECEIVE_DIR).parent + 'processed']
      end
    end

    def file_row_for_grid(file, options = {}) # rubocop:disable Metrics/AbcSize
      flow = work_out_flow_type(file.basename.to_s)
      {
        id: yield,
        flow_type: flow,
        file_name: file.basename.to_s,
        modified_date: file.mtime,
        directory: file.dirname.to_s,
        size: UtilityFunctions.filesize(file.size),
        file_path: URI.encode_www_form_component(file.to_s),
        edi_in: options[:edi_in] || false,
        edi_out: options[:edi_out] || false,
        in_error: options[:in_error] || false
      }
    end

    def work_out_flow_type(file_name)
      config = EdiOutRepo.new.schema_record_sizes
      # Ensure longest flow types are matched first
      # (in case of something like flows: PO and POS)
      keys = config.keys.sort_by(&:length).reverse

      flow_type = '???'
      keys.each do |key|
        next unless file_name.upcase.start_with?(key.upcase)

        flow_type = if config[key].is_a?(String)
                      config[key]
                    else
                      key.upcase
                    end
        break
      end
      flow_type
    end

    def grid_columns_for_edi_files
      Crossbeams::DataGrid::ColumnDefiner.new.make_columns do |mk|
        mk.action_column do |act|
          act.link 'view', '/edi/viewer/display_edi_file?flow_type=$col1$&file_path=$col2$', col1: 'flow_type', col2: 'file_path', icon: 'document-add'
          act.link 're-process this file', '/edi/actions/re_receive_file?file_path=$col1$', col1: 'file_path', icon: 'play', hide_if_false: 'in_error', prompt: 'Are you sure?'
        end
        mk.col 'id', 'ID', hide: true
        mk.col 'flow_type', 'Type', width: 80
        mk.col 'file_name', 'File name'
        mk.col 'modified_date', 'Modified'
        mk.col 'directory', 'Directory', width: 600
        mk.col 'size', 'Size'
        mk.col 'file_path', 'File path', hide: true
        mk.col 'edi_in', 'EDI in?', data_type: :boolean, hide: true
        mk.col 'edi_out', 'EDI out?', data_type: :boolean, hide: true
        mk.col 'in_error', 'Error?', data_type: :boolean, hide: true
      end
    end

    def grid_columns_for_csv(rec)
      Crossbeams::DataGrid::ColumnDefiner.new.make_columns do |mk|
        rec.to_a.each { |key, _| mk.col key }
      end
    end

    def validate_edi_upload_params(params)
      EdiFileUploadSchema.call(params)
    end
  end
end
