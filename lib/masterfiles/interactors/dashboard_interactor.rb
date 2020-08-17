# frozen_string_literal: true

module MasterfilesApp
  class DashboardInteractor < BaseInteractor # rubocop:disable Metrics/ClassLength
    def dashboard_rows # rubocop:disable Metrics/AbcSize
      config = load_config('dashboards.yml')
      if config.nil?
        []
      else
        out = []
        config.each_key do |key|
          desc = config[key]['description']
          out << { id: key, key: key, desc: desc, page: nil, url: nil, seconds: nil, text: false, image: false } if config[key]['boards'].length.zero?
          config[key]['boards'].each_with_index do |board, index|
            out << { id: "#{key}_#{index}",
                     key: key,
                     desc: desc,
                     page: board['desc'],
                     url: board['url'],
                     seconds: board['secs'],
                     text: board['url'].start_with?('/dashboard/text/'),
                     image: board['url'].start_with?('/dashboard/image/') }
          end
        end
        out
      end
    end

    def dashboards_list_grid # rubocop:disable Metrics/AbcSize
      row_defs = dashboard_rows
      col_defs = Crossbeams::DataGrid::ColumnDefiner.new.make_columns do |mk| # rubocop:disable Metrics/BlockLength
        mk.action_column do |act| # rubocop:disable Metrics/BlockLength
          act.popup_link 'edit dashboard', '/masterfiles/config/dashboards/$col1$/edit',
                         col1: 'id',
                         icon: 'edit',
                         title: 'Dashboard'
          act.separator
          act.popup_link 'dashboard link', '/masterfiles/config/dashboards/$col1$/dashboard_url',
                         col1: 'id',
                         icon: 'link',
                         title_field: 'description',
                         hide_if_null: 'page'
          act.link 'preview this page', '/dashboard/preview_page/$col1$',
                   col1: 'id',
                   icon: 'view-show',
                   title_field: 'desc',
                   hide_if_null: 'page'
          act.separator
          act.popup_link 'new internal page', '/masterfiles/config/dashboards/$col1$/new_internal_page',
                         icon: 'add-solid',
                         title: 'New internal page',
                         col1: 'id'
          act.popup_link 'new external page', '/masterfiles/config/dashboards/$col1$/new_page',
                         icon: 'add-outline',
                         title: 'New external page',
                         col1: 'id'
          act.popup_link 'new text page', '/masterfiles/config/dashboards/$col1$/new_text_page',
                         icon: 'document-add',
                         title: 'New text page',
                         col1: 'id'
          act.popup_link 'new image page', '/masterfiles/config/dashboards/$col1$/new_image_page',
                         icon: 'photo',
                         title: 'New image page',
                         col1: 'id'
          act.separator
          act.popup_link 'edit page', '/masterfiles/config/dashboards/$col1$/edit_page',
                         icon: 'edit',
                         title: 'Edit page',
                         col1: 'id',
                         hide_if_null: 'page'
          # act.popup_link 'change text', '/masterfiles/config/dashboards/$col1$/change_text',
          #                icon: 'edit-pencil',
          #                title: 'Change text',
          #                col1: 'id',
          #                hide_if_false: 'text'
          # act.popup_link 'change image', '/masterfiles/config/dashboards/$col1$/change_image',
          #                icon: 'play',
          #                title: 'Change image',
          #                col1: 'id',
          #                hide_if_false: 'image'
          # act.popup_link 're-sequence pages', '/masterfiles/config/dashboards/$col1$/re_sequence_pages',
          #                icon: 'sort',
          #                title: 'Re-sequence pages',
          #                col1: 'id'
          act.popup_delete_link '/masterfiles/config/dashboards/$col1$',
                                col1: 'id'
        end
        mk.col 'desc', 'Dashboard Description', width: 200, groupable: true, group_by_seq: 1
        mk.col 'key', 'Key', width: 100
        mk.col 'page', 'Page description', width: 300
        mk.integer 'seconds', 'Seconds'
        mk.col 'url', 'URL', width: 500
        mk.integer 'id', 'ID', hide: true
        mk.boolean 'text', 'Text', hide: true
        mk.boolean 'image', 'Image', hide: true
      end
      {
        columnDefs: col_defs,
        rowDefs: row_defs
      }.to_json
    end

    def dashboard_for(key)
      config = section_from_yml('dashboards.yml', key)
      return [nil, nil] if config.nil?

      name = config['description']
      url_set = config['boards'].map do |dash|
        [dash['url'], dash['secs']]
      end
      [name, url_set]
    end

    def url_for(key, index)
      config = section_from_yml('dashboards.yml', key)
      raise CrossbeamsInfoError, "There is no dashboard entry for #{key}" if config.nil?

      url_set = config['boards']
      url_set[index]['url']
    end

    def text_for(key)
      config = section_from_yml('dashboard_texts.yml', key)
      return nil if config.nil?

      bg_class = config['background'] || 'bg-moon-gray'
      out = config['content'].map do |section|
        styles = text_style(section)
        "<p #{styles}'>#{section['text']}</p>"
      end
      <<~HTML
        <div id="text-content" class="#{bg_class}">
          #{out.join("\n")}
        </div>
      HTML
    end

    def create_dashboard(params)
      config = load_config('dashboards.yml')
      key = params[:key]
      config[key] = { 'description' => params[:description], 'boards' => [] }
      rewrite_config('dashboards.yml', config)
      success_response("Created new dashboard #{key}: #{params[:description]}")
    end

    def update_dashboard(key, params) # rubocop:disable Metrics/AbcSize
      config = load_config('dashboards.yml')
      config[key]['description'] = params[:description]
      rewrite_config('dashboards.yml', config)
      ids = if config[key]['boards'].length.zero?
              [key]
            else
              config[key]['boards'].length.times.map { |index| "#{key}_#{index}" }
            end
      success_response('Saved change', { description: params[:description], ids: ids })
    end

    def delete_dashboard(key)
      config = load_config('dashboards.yml')
      config.delete(key)
      rewrite_config('dashboards.yml', config)
      success_response('Deleted dashboard')
    end

    def create_dashboard_page(key, params)
      config = load_config('dashboards.yml')
      config[key]['boards'] << { 'url' => params[:url], 'desc' => params[:desc], 'secs' => params[:secs].to_i }
      rewrite_config('dashboards.yml', config)
      success_response("Added page #{params[:desc]} to dashboard #{key}")
    end

    def create_dashboard_image_page(key, params) # rubocop:disable Metrics/AbcSize
      tempfile = params[:image_file][:tempfile] if params[:image_file]

      url = if tempfile
              fn = params[:image_file][:filename].tr(' ', '_')
              FileUtils.mv(tempfile.path, File.join(ENV['ROOT'], 'public/dashboard_images', fn))
              "/dashboard/image/#{fn}"
            else
              "/dashboard/image/#{params[:select_image]}"
            end

      config = load_config('dashboards.yml')
      config[key]['boards'] << { 'url' => url, 'desc' => params[:desc], 'secs' => params[:secs].to_i }
      rewrite_config('dashboards.yml', config)
      success_response("Added page #{params[:desc]} to dashboard #{key}")
    end

    def create_dashboard_text_page(key, params) # rubocop:disable Metrics/AbcSize
      url = "/dashboard/text/#{params[:text_page_key]}"

      text_ar = []
      params[:text].each_line do |line|
        next if line.strip.chomp.empty?

        ar = line.split(';').map(&:strip)
        text_ar << { 'text' => ar.last, 'size' => ar[1], 'colour' => ar.first }
      end

      config = load_config('dashboard_texts.yml')
      config[params[:text_page_key]] = { 'background' => params[:background_colour], 'content' => text_ar }
      rewrite_config('dashboard_texts.yml', config)

      config = load_config('dashboards.yml')
      config[key]['boards'] << { 'url' => url, 'desc' => params[:desc], 'secs' => params[:secs].to_i }
      rewrite_config('dashboards.yml', config)
      success_response("Added page #{params[:desc]} to dashboard #{key}")
    end

    def update_dashboard_page(key, page, params) # rubocop:disable Metrics/AbcSize
      config = load_config('dashboards.yml')
      config[key]['boards'][page]['desc'] = params[:desc]
      config[key]['boards'][page]['url'] = params[:url]
      config[key]['boards'][page]['secs'] = params[:secs].to_i
      rewrite_config('dashboards.yml', config)
      success_response('Saved change', { page: params[:desc], url: params[:url], secs: params[:secs] })
    end

    def delete_dashboard_page(key, page)
      config = load_config('dashboards.yml')
      config[key]['boards'].delete_at(page)
      rewrite_config('dashboards.yml', config)
      success_response('Deleted dashboard page')
    end

    private

    def text_style(section)
      styles = []
      size = section['size'] || 1
      styles << %(class="#{section['colour']}") if section['colour']
      styles << %(style="font-size:#{size}rem")
      styles.join(' ')
    end

    def section_from_yml(file, key)
      load_config(file)[key]
    end

    def load_config(file)
      fn = File.join(ENV['ROOT'], 'config', file)
      YAML.load_file(fn)
    end

    def rewrite_config(file, config)
      fn = File.join(ENV['ROOT'], 'config', file)
      File.open(fn, 'w') { |f| f << config.to_yaml }
    end
  end
end
