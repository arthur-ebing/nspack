# frozen_string_literal: true

module UiRules
  class DashboardRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules
      make_form_object
      apply_form_values

      common_values_for_fields case @mode
                               when :url
                                 url_fields
                               when :edit
                                 edit_fields
                               when :new
                                 new_fields
                               when :new_page, :edit_page
                                 page_fields
                               when :change_columns
                                 column_fields
                               end

      form_name 'dashboard'
    end

    def new_fields
      {
        key: { required: true },
        description: { required: true }
      }
    end

    def edit_fields
      {
        key: { renderer: :label },
        description: { required: true },
        pages: { renderer: :list, items: @form_object.pages }
      }
    end

    def url_fields
      {
        url: { readonly: true, copy_to_clipboard: true }
      }
    end

    def page_fields
      {
        key: { renderer: :label },
        description: { renderer: :label },
        desc: { required: true, caption: 'Page description' },
        url: { required: true, caption: 'URL' },
        secs: { renderer: :integer, required: true, caption: 'No seconds to display' }
      }
    end

    def properties_fields
      {
        database: { readonly: true },
        report_template: { readonly: true },
        report_description: { renderer: :label },
        id: { renderer: :label, caption: 'Report id' },
        webquery_url: { readonly: true, copy_to_clipboard: true },
        param_description: { renderer: :list, items: @options[:instance][:param_texts], caption: 'Parameters applied' }
      }
    end

    def column_fields
      {
        report_description: { renderer: :label },
        column_sequence: { renderer: :sortable_list, caption: 'Column order', prefix: 'co' },
        hidden_columns: { renderer: :sortable_list, caption: 'Hidden columns', prefix: 'hc' }
      }
    end

    def make_form_object
      @form_object = if @mode == :edit
                       read_form_object
                     elsif @mode == :url
                       { url: @options[:url] }
                     elsif @mode == :new_page
                       new_page_object
                     elsif @mode == :edit_page
                       edit_page_object
                     else
                       form_new_object
                     end
    end

    def read_form_object
      dash = load_config(@options[:key])
      OpenStruct.new(key: @options[:key],
                     description: dash['description'],
                     pages: dash['boards'].map { |b| b['desc'] || b['url'] })
    end

    def load_config(key)
      fn = File.join(ENV['ROOT'], 'config', 'dashboards.yml')
      YAML.load_file(fn)[key]
    end

    def form_new_object
      OpenStruct.new(key: nil,
                     description: nil)
    end

    def new_page_object
      dash = load_config(@options[:key])
      OpenStruct.new(key: @options[:key],
                     description: dash['description'],
                     desc: nil,
                     url: nil,
                     secs: nil)
    end

    def edit_page_object # rubocop:disable Metrics/AbcSize
      dash = load_config(@options[:key])
      OpenStruct.new(key: @options[:key],
                     description: dash['description'],
                     desc: dash['boards'][@options[:index]]['desc'],
                     url: dash['boards'][@options[:index]]['url'],
                     secs: dash['boards'][@options[:index]]['secs'])
    end
  end
end
