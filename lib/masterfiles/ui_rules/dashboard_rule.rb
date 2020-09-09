# frozen_string_literal: true

module UiRules
  class DashboardRule < Base # rubocop:disable Metrics/ClassLength
    def generate_rules # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
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
                               when :new_text_page
                                 new_text_fields
                               when :new_page, :edit_page, :new_internal
                                 page_fields
                               when :change_columns
                                 column_fields
                               else
                                 {}
                               end
      make_dash_items if @mode == :reorder
      add_behaviour if @mode == :new_text_page
      add_internal_behaviour if %i[new_internal edit_page].include?(@mode)

      form_name 'dashboard'
    end

    def make_dash_items
      dash = load_config(@options[:key])
      @rules[:dash_items] = dash['boards'].each_with_index.map { |b, i| [b['desc'], i] }
    end

    def new_fields
      {
        key: { required: true, pattern: :alphanumeric },
        description: { required: true }
      }
    end

    def edit_fields
      {
        key: { renderer: :label, pattern: :alphanumeric },
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
                       { renderer: :select, options: AppConst::DASHBOARD_INTERNAL_PAGES, required: true, caption: 'URL', min_charwidth: 40 }
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
        parameter: { renderer: :select, options: param_options, hide_on_load: hide_param?, prompt: true, invisible: @mode == :new_page },
        select_image: { renderer: :select, options: images, invisible: !image_dashboard?, min_charwidth: 40 },
        secs: { renderer: :integer, required: true, caption: 'No seconds to display', minvalue: 1 }
      }
    end

    def hide_param?
      return true if @mode == :new_internal

      return false if @form_object.url.include?('$:')

      dash_rules = dash_rules_for(@form_object.url)
      return true if dash_rules.nil?

      false
    end

    def param_options
      return [] if @mode == :new_internal

      mtc = @form_object.url.match(/\$:(.+)?\$/)
      return url_params_for(mtc[1]) unless mtc.nil?

      dash_rules = dash_rules_for(@form_object.url)
      return [] if dash_rules.nil?

      url_params_for(dash_rules.first[:key])
    end

    def dash_rules_for(url)
      dash_key = AppConst::DASHBOARD_INTERNAL_PAGES.rassoc(url)
      return nil if dash_key.nil?

      AppConst::DASHBOARD_QUERYSTRING_PARAMS[dash_key.first]
    end

    def url_params_for(key)
      ProductionApp::ResourceRepo.new.for_select_plant_resource_codes(key)
    end

    def images
      img_dir = File.join(ENV['ROOT'], 'public/dashboard_images')
      FileUtils.mkdir_p(img_dir)
      full_dir = Pathname.new(img_dir)
      Dir.glob(File.join(full_dir, '*.*')).map { |f| f.delete_prefix("#{full_dir}/") }
    end

    def new_image_fields
      {
        key: { renderer: :label },
        description: { renderer: :label },
        desc: { required: true, caption: 'Page description' },
        secs: { renderer: :integer, required: true, caption: 'No seconds to display', minvalue: 1 },
        select_image: { renderer: :select, options: images },
        image_file: { renderer: :file, accept: '.jpg,.png,.pdf,.gif,.jpeg' }
      }
    end

    COLOUR_CLASSES = %w[
      black
      near-black
      dark-gray
      mid-gray
      gray
      silver
      light-silver
      moon-gray
      light-gray
      near-white
      white
      dark-red
      red
      light-red
      orange
      gold
      yellow
      light-yellow
      purple
      light-purple
      dark-pink
      hot-pink
      pink
      light-pink
      dark-green
      green
      light-green
      navy
      dark-blue
      blue
      light-blue
      lightest-blue
      washed-blue
      washed-green
      washed-yellow
      washed-red
    ].freeze

    def new_text_fields
      {
        key: { renderer: :label },
        description: { renderer: :label },
        desc: { required: true, caption: 'Page description' },
        secs: { renderer: :integer, required: true, caption: 'No seconds to display', minvalue: 1 },
        background_colour: { renderer: :select, options: COLOUR_CLASSES.zip(COLOUR_CLASSES.map { |c| "bg-#{c}" }) },
        text_page_key: { required: true, force_lowercase: true, pattern: :lowercase_underscore },
        existing_text: { renderer: :select, options: text_pages, prompt: true },
        # TODO: set required attr off for text & key if a value selected...
        text: { renderer: :textarea, required: true }
      }
    end

    def text_pages
      fn = File.join(ENV['ROOT'], 'config', 'dashboard_texts.yml')
      return [] unless File.exist?(fn)

      YAML.load_file(fn).keys
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

    def image_name(url)
      url.delete_prefix('/dashboard/image/')
    end

    def make_form_object
      @form_object = if @mode == :edit
                       read_form_object
                     elsif @mode == :url
                       { url: @options[:url] }
                     elsif %i[new_page new_internal new_text_page new_image_page].include?(@mode)
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
      p_value = dash['boards'][@options[:index]]['params']&.first
      p_value = p_value['value'] unless p_value.nil?
      OpenStruct.new(key: @options[:key],
                     description: dash['description'],
                     desc: dash['boards'][@options[:index]]['desc'],
                     url: dash['boards'][@options[:index]]['url'],
                     parameter: p_value,
                     select_image: image_name(dash['boards'][@options[:index]]['url']),
                     secs: dash['boards'][@options[:index]]['secs'])
    end

    def add_behaviour
      behaviours do |behaviour|
        behaviour.dropdown_change :existing_text, notify: [{ url: '/masterfiles/config/dashboards/existing_text_changed' }]
      end
    end

    def add_internal_behaviour
      return if @mode == :edit_page && !internal_url?

      behaviours do |behaviour|
        behaviour.dropdown_change :url, notify: [{ url: '/masterfiles/config/dashboards/internal_url_changed' }]
      end
    end
  end
end
