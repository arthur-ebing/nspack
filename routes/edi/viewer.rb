# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
class Nspack < Roda # rubocop:disable Metrics/ClassLength
  route 'viewer', 'edi' do |r|
    interactor = EdiApp::ViewerInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})

    # UPLOAD
    # --------------------------------------------------------------------------
    r.on 'upload' do
      r.get do
        show_partial_or_page(r) { Edi::Viewer::File::Upload.call(remote: fetch?(r)) }
      end

      r.post do
        res = interactor.edi_upload(params[:edi_file_upload])
        if res.success
          if res.instance[:upload_name].match(/.xml$/i)
            show_partial_or_page(r) { Edi::Viewer::File::XML.call(res.instance[:flow_type], res.instance[:fn]) }
          elsif res.instance[:upload_name].match(/.csv$/i)
            show_partial_or_page(r) { Edi::Viewer::File::CSV.call(res.instance[:flow_type], res.instance[:fn], upload_name: res.instance[:upload_name]) }
          else
            @page = interactor.build_grids_for(res.instance[:flow_type], res.instance[:fn], upload_name: res.instance[:upload_name])
            view('edi/show_in_grids')
          end
        else
          re_show_form(r, res, url: '/edi/viewer/upload') do
            Edi::Viewer::File::Upload.call(form_values: params[:edi_file_upload],
                                           form_errors: res.errors,
                                           remote: fetch?(r))
          end
        end
      end
    end

    r.on 'download_edi_file' do
      response.headers['content_type'] = 'plain/text'
      response.headers['Content-Disposition'] = "attachment; filename=\"#{File.basename(params[:file_path])}\""
      response.write(File.read(params[:file_path]))
    end

    r.on 'display_raw_edi_file' do
      view(inline: <<~HTML)
        <h2>#{params[:flow_type]} - #{File.basename(params[:file_path])}</h2>
        <p>#{Crossbeams::Layout::Link.new(text: 'Back', url: back_button_url, style: :back_button).render} #{params[:file_path]}</p>
        <pre>
          #{File.read(params[:file_path])}
        </pre>
      HTML
    end

    r.on 'display_edi_file' do
      r.on 'csv_grid' do
        interactor.csv_grid(params[:file_path])
      end

      if UtilityFunctions.xml_file?(params[:file_path])
        show_partial_or_page(r) { Edi::Viewer::File::XML.call(params[:flow_type], params[:file_path]) }
      elsif params[:file_path].match(/.csv$/i)
        show_partial_or_page(r) { Edi::Viewer::File::CSV.call(params[:flow_type], params[:file_path]) }
      else
        @page = interactor.build_grids_for(params[:flow_type], params[:file_path])
        view('edi/show_in_grids')
      end
    end

    r.on 'display_edi_in_transaction_file', Integer do |id|
      res = interactor.file_path_from_in_transaction(id)
      if res.success
        flow_type = res.instance[:flow_type]
        file_path = res.instance[:file_path]
        if UtilityFunctions.xml_file?(file_path)
          show_partial_or_page(r) { Edi::Viewer::File::XML.call(flow_type, file_path, back_url: request.referer) }
        elsif file_path.match(/.csv$/i)
          show_partial_or_page(r) { Edi::Viewer::File::CSV.call(flow_type, file_path) }
        else
          @page = interactor.build_grids_for(flow_type, file_path)
          view('edi/show_in_grids')
        end
      else
        flash[:error] = res.message
        redirect_to_last_grid(r)
      end
    end

    # SENT
    # --------------------------------------------------------------------------
    r.on 'sent' do
      r.on 'recently' do
        r.is do
          set_last_grid_url(request.path)
          show_page { Edi::Viewer::File::ListFiles.call('Recently sent EDI files', '/edi/viewer/sent/recently/grid') }
        end

        r.on 'grid' do
          interactor.recent_sent_files
        rescue StandardError => e
          show_json_exception(e)
        end
      end
      r.on 'search_by_name' do
        r.is do
          show_page do
            Edi::Viewer::File::SearchByName.call('Search sent files by name',
                                                 'Search for files where the file names contain the search term below',
                                                 '/edi/viewer/sent/search_by_name/list')
          end
        end

        r.on 'list' do
          set_last_grid_url(request.path)
          show_page { Edi::Viewer::File::ListFiles.call('Search by name', "/edi/viewer/sent/search_by_name/grid?search=#{URI.encode_www_form_component(params[:search])}") }
        end

        r.on 'grid' do
          interactor.search_sent_files(params[:search])
        rescue StandardError => e
          p e
          puts e.backtrace
          show_json_exception(e)
        end
      end
      r.on 'search_by_content' do
        r.is do
          show_page do
            Edi::Viewer::File::SearchByName.call('Search sent files by content',
                                                 'Search for files that contain the search term below',
                                                 '/edi/viewer/sent/search_by_content/list')
          end
        end

        r.on 'list' do
          set_last_grid_url(request.path)
          show_page { Edi::Viewer::File::ListFiles.call('Search by content', "/edi/viewer/sent/search_by_content/grid?search=#{URI.encode_www_form_component(params[:search])}") }
        end

        r.on 'grid' do
          interactor.search_sent_files_for_content(params[:search])
        rescue StandardError => e
          p e
          puts e.backtrace
          show_json_exception(e)
        end
      end
    end

    # RECEIVED
    # --------------------------------------------------------------------------
    r.on 'received' do
      r.on 'recently' do
        r.is do
          set_last_grid_url(request.path)
          show_page { Edi::Viewer::File::ListFiles.call('Recently received EDI files', '/edi/viewer/received/recently/grid') }
        end

        r.on 'grid' do
          interactor.recent_received_files
        rescue StandardError => e
          show_json_exception(e)
        end
      end
      r.on 'errors' do
        r.is do
          set_last_grid_url(request.path)
          show_page { Edi::Viewer::File::ListFiles.call('Received EDI files in error', '/edi/viewer/received/errors/grid') }
        end

        r.on 'grid' do
          interactor.received_files_in_error
        rescue StandardError => e
          show_json_exception(e)
        end
      end
      r.on 'search_by_name' do
        r.is do
          show_page do
            Edi::Viewer::File::SearchByName.call('Search received files by name',
                                                 'Search for files where the file names contain the search term below',
                                                 '/edi/viewer/received/search_by_name/list')
          end
        end

        r.on 'list' do
          set_last_grid_url(request.path)
          show_page { Edi::Viewer::File::ListFiles.call('Search by name', "/edi/viewer/received/search_by_name/grid?search=#{URI.encode_www_form_component(params[:search])}") }
        end

        r.on 'grid' do
          interactor.search_received_files(params[:search])
        rescue StandardError => e
          p e
          puts e.backtrace
          show_json_exception(e)
        end
      end
      r.on 'search_by_content' do
        r.is do
          show_page do
            Edi::Viewer::File::SearchByName.call('Search received files by content',
                                                 'Search for files that contain the search term below',
                                                 '/edi/viewer/received/search_by_content/list')
          end
        end

        r.on 'list' do
          set_last_grid_url(request.path)
          show_page { Edi::Viewer::File::ListFiles.call('Search by content', "/edi/viewer/received/search_by_content/grid?search=#{URI.encode_www_form_component(params[:search])}") }
        end

        r.on 'grid' do
          interactor.search_received_files_for_content(params[:search])
        rescue StandardError => e
          p e
          puts e.backtrace
          show_json_exception(e)
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
