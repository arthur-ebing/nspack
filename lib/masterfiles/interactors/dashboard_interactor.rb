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
          out << { id: key, key: key, desc: desc, page: nil, seconds: nil } if config[key]['boards'].length.zero?
          config[key]['boards'].each_with_index do |board, index|
            out << { id: "#{key}_#{index}", key: key, desc: desc, page: board['desc'] || board['url'], seconds: board['secs'] }
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
          act.popup_link 'new page', '/masterfiles/config/dashboards/$col1$/new_page',
                         icon: 'add-solid',
                         title: 'New page',
                         col1: 'id'
          act.popup_link 'edit page', '/masterfiles/config/dashboards/$col1$/edit_page',
                         icon: 'edit',
                         title: 'Edit page',
                         col1: 'id',
                         hide_if_null: 'page'
          act.popup_delete_link '/masterfiles/config/dashboards/$col1$',
                                col1: 'id'
        end
        mk.col 'desc', 'Dashboard Description', width: 200, groupable: true, group_by_seq: 1
        mk.col 'key', 'Key', width: 100
        mk.col 'page', 'Page description', width: 500
        mk.integer 'seconds', 'Seconds'
        mk.col 'id', 'ID', hide: true
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

      out = config.map do |section|
        styles = text_style(section)
        "<p style='#{styles.join(';')}'>#{section['text']}</p>"
      end
      out.join("\n")
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

    def update_dashboard_page(key, page, params) # rubocop:disable Metrics/AbcSize
      config = load_config('dashboards.yml')
      config[key]['boards'][page]['desc'] = params[:desc]
      config[key]['boards'][page]['url'] = params[:url]
      config[key]['boards'][page]['secs'] = params[:secs].to_i
      rewrite_config('dashboards.yml', config)
      success_response('Saved change', { page: params[:desc], secs: params[:secs] })
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
      styles << "color:#{section['colour']}" if section['colour']
      styles << "font-size:#{size}rem"
      styles
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
