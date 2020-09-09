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
          out << { id: key, key: key, desc: desc, page: nil, url: nil, params: nil, seconds: nil, text: false, image: false } if config[key]['boards'].length.zero?
          config[key]['boards'].each_with_index do |board, index|
            p_value = board['params']&.first
            p_value = p_value['value'] unless p_value.nil?
            out << { id: "#{key}_#{index}",
                     key: key,
                     desc: desc,
                     page: board['desc'],
                     url: board['url'],
                     params: p_value,
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
          act.popup_link 're-order pages', '/masterfiles/config/dashboards/$col1$/reorder',
                         icon: 'sort',
                         title: 'Re-order pages',
                         col1: 'id',
                         hide_if_null: 'page'
          act.separator
          act.popup_link 'dashboard link', '/masterfiles/config/dashboards/$col1$/dashboard_url',
                         col1: 'id',
                         icon: 'link',
                         title_field: 'desc',
                         hide_if_null: 'page'
          act.link 'preview this page', '/dashboard/preview_page/$col1$',
                   col1: 'id',
                   icon: 'view-show',
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
          act.popup_delete_link '/masterfiles/config/dashboards/$col1$',
                                col1: 'id'
        end
        mk.col 'desc', 'Dashboard Description', width: 200, groupable: true, group_by_seq: 1
        mk.col 'key', 'Key', width: 100
        mk.col 'page', 'Page description', width: 300
        mk.integer 'seconds', 'Seconds'
        mk.col 'url', 'URL', width: 500
        mk.col 'params', 'Param value'
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
        [apply_url_params(dash), dash['secs']]
      end
      [name, url_set]
    end

    def apply_url_params(config)
      return config['url'] unless config['params']

      url = config['url']
      config['params'].each do |param|
        key = param['key']
        val = param['value']
        if param['type'] == 'inline'
          url.gsub!("$:#{key}$", val)
        else
          key = key.downcase
          url = if url.include?('?')
                  "#{url}&#{key}=#{val}"
                else
                  "#{url}?#{key}=#{val}"
                end
        end
      end
      url
    end

    def url_for(key, index)
      config = section_from_yml('dashboards.yml', key)
      raise Crossbeams::InfoError, "There is no dashboard entry for #{key}" if config.nil?

      if index
        url_set = config['boards']
        apply_url_params(url_set[index])
      else
        "/dashboard/#{key}"
      end
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
      if params[:existing_text]
        url = "/dashboard/text/#{params[:existing_text]}"
      else
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
      end

      config = load_config('dashboards.yml')
      config[key]['boards'] << { 'url' => url, 'desc' => params[:desc], 'secs' => params[:secs].to_i }
      rewrite_config('dashboards.yml', config)
      success_response("Added page #{params[:desc]} to dashboard #{key}")
    end

    def update_dashboard_page(key, page, params) # rubocop:disable Metrics/AbcSize
      url = params[:select_image] ? "/dashboard/image/#{params[:select_image]}" : params[:url]
      config = load_config('dashboards.yml')
      config[key]['boards'][page]['desc'] = params[:desc]
      config[key]['boards'][page]['url'] = url
      config[key]['boards'][page]['secs'] = params[:secs].to_i

      if params[:parameter] && !params[:parameter].empty?
        config[key]['boards'][page]['params'] = param_for_url(url, params[:parameter])
      else
        config[key]['boards'][page].delete('params')
      end
      rewrite_config('dashboards.yml', config)
      success_response('Saved change', { page: params[:desc], url: url, params: params[:parameter], secs: params[:secs] })
    end

    def param_for_url(url, value)
      mtc = url.match(/\$:(.+)?\$/)
      if mtc.nil?
        p_type = 'querystring'
        dash_rules = dash_rules_for(url)
        raise Crossbeams::FrameworkError, "No dashboard rules for URL: #{url}" if dash_rules.empty?

        key = dash_rules.first[:key]
      else
        p_type = 'inline'
        key = mtc[1]
      end

      [{ 'type' => p_type, 'key' => key, 'value' => value }]
    end

    def delete_dashboard_page(key, page)
      config = load_config('dashboards.yml')
      config[key]['boards'].delete_at(page)
      rewrite_config('dashboards.yml', config)
      success_response('Deleted dashboard page')
    end

    def reorder_pages(key, sorted_id_list)
      config = load_config('dashboards.yml')
      current = config[key]['boards']
      new = []
      sorted_id_list.each do |idx|
        new << current[idx]
      end
      config[key]['boards'] = new
      rewrite_config('dashboards.yml', config)
      success_response("Re-ordered dashboard #{config[key]['description']}")
    end

    def internal_url_changed(url)
      mtc = url.match(/\$:(.+)?\$/)
      return url_params_for(mtc[1]) unless mtc.nil?

      dash_rules = dash_rules_for(url)
      return [] if dash_rules.nil?

      url_params_for(dash_rules.first[:key])
    end

    private

    def dash_rules_for(url)
      dash_key = AppConst::DASHBOARD_INTERNAL_PAGES.rassoc(url)
      return nil if dash_key.nil?

      AppConst::DASHBOARD_QUERYSTRING_PARAMS[dash_key.first]
    end

    def url_params_for(key)
      ProductionApp::ResourceRepo.new.for_select_plant_resource_codes(key)
    end

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
      if File.exist?(fn)
        YAML.load_file(fn) || {}
      else
        {}
      end
    end

    def rewrite_config(file, config)
      fn = File.join(ENV['ROOT'], 'config', file)
      File.open(fn, 'w') { |f| f << config.to_yaml }
    end
  end
end
