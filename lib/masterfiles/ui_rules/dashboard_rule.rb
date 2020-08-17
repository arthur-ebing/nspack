# frozen_string_literal: true

module UiRules
  class DashboardRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules # rubocop:disable Metrics/CyclomaticComplexity
      make_form_object
      apply_form_values

      common_values_for_fields case @mode
                               when :url
                                 url_fields
                               when :edit
                                 edit_fields
                               when :new
                                 new_fields
                               when :new_image_page
                                 new_image_fields
                               when :new_page, :edit_page, :new_internal
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
      url_renderer = if @mode == :new_internal || @mode == :edit_page && internal_url?
                       { renderer: :select, options: AppConst::DASHBOARD_INTERNAL_PAGES, required: true, caption: 'URL' }
                     elsif text_dashboard? || image_dashboard?
                       { renderer: :hidden }
                     else
                       { required: true, caption: 'URL' }
                     end

      {
        key: { renderer: :label },
        description: { renderer: :label },
        desc: { required: true, caption: 'Page description' },
        url: url_renderer,
        secs: { renderer: :integer, required: true, caption: 'No seconds to display', minvalue: 1 }
      }
    end

    def new_image_fields
      img_dir = File.join(ENV['ROOT'], 'public/dashboard_images')
      FileUtils.mkdir_p(img_dir)
      full_dir = Pathname.new(img_dir)
      images = Dir.glob(File.join(full_dir, '*.*')).map { |f| f.delete_prefix("#{full_dir}/") }
      {
        key: { renderer: :label },
        description: { renderer: :label },
        desc: { required: true, caption: 'Page description' },
        secs: { renderer: :integer, required: true, caption: 'No seconds to display', minvalue: 1 },
        select_image: { renderer: :select, options: images },
        image_file: { renderer: :file, accept: '.jpg,.png,.pdf,.gif,.jpeg' }
      }
    end

    def internal_url?
      AppConst::DASHBOARD_INTERNAL_PAGES.any? { |_, url| url == @form_object[:url] }
    end

    def text_dashboard?
      (@form_object[:url] || '').start_with?('/dashboard/text/')
    end

    def image_dashboard?
      (@form_object[:url] || '').start_with?('/dashboard/image/')
    end

    def make_form_object
      @form_object = if @mode == :edit
                       read_form_object
                     elsif @mode == :url
                       { url: @options[:url] }
                     elsif %i[new_page new_internal new_image_page].include?(@mode)
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
