module UiRules
  class BlockAuth
    def authorized?
      raise 'Cannot check authorization - no authorizer supplied to UiRules::Compiler.'
    end
  end

  class Compiler
    attr_reader :params

    def initialize(rule, mode, options = {})
      @options = options
      @params = {}
      authorizer = options.delete(:authorizer) || BlockAuth.new
      klass = UiRules.const_get("#{rule.to_s.split('_').map(&:capitalize).join}Rule")
      @rule = klass.new(mode, authorizer, options)
    end

    def compile
      @rule.generate_rules
      @rule.rules
    end

    def respond_to_behaviour(params)
      raise Crossbeams::FrameworkError, "#{self.class.name} does not implement the handle_behaviour method" unless @rule.respond_to?(:handle_behaviour)

      @rule.params = params
      @rule.handle_behaviour
    end

    def form_object
      @rule.form_object
    end
  end

  class Base
    include JsonHelpers

    attr_reader :rules, :inflector
    attr_accessor :params

    def initialize(mode, authorizer, options)
      @mode        = mode
      @authorizer  = authorizer
      @options     = options
      @form_object = nil
      @inflector   = Dry::Inflector.new
      @rules       = { fields: {} }
      @params      = {}
    end

    def form_object
      @form_object || raise("#{self.class} did not implement the form object")
    end

    private

    def unhandled_behaviour!
      raise Crossbeams::FrameworkError, %(#{self.class} has not implemented a behaviour handler for mode "#{@mode}")
    end

    def make_caption(value)
      inflector.humanize(value.to_s).gsub(/\s\D/, &:upcase)
    end

    # Get an OpenStruct with keys for every attribute of an entity.
    # Optionally include values for some attributes in the merge_hash.
    #
    # @param struct [DryStruct] the entity to base the struct on.
    # @param merge_hash [hash] optional hash to merge with non-nil values.
    # @return [OpenStruct]
    def new_form_object_from_struct(struct, merge_hash: {})
      cols = struct.attribute_names.reject { |c| %i[id created_at updated_at].include?(c) }
      hash = Hash[cols.zip([nil] * cols.length)]
      OpenStruct.new(hash.merge(merge_hash))
    end

    def extended_columns(repo, table, edit_mode: true)
      config = Crossbeams::Config::ExtendedColumnDefinitions.config_for(table)
      return if config.nil?

      config.each do |key, defn|
        caption = make_caption(key)
        fields["extcol_#{key}".to_sym] = if edit_mode
                                           renderer_for_extcol(repo, defn, caption)
                                         else
                                           { renderer: :label, caption: caption, as_boolean: defn[:type] == :boolean }
                                         end
      end
    end

    # Generate HTML for a table of columns from the +@form_object+.
    # The table shows only elements that are in the `columns` array.
    # If the columns array is an array of arrays, each array will be a vertical set of items.
    #
    # @param columns [array] the columns to display in the table in sequence. Array of symbols matching attributes in the +@`form_object+. (Can be multidemensional)
    # @param display_columns [integer] the number of table columns (combination of `th` for label and `td` for value) to display. Defaults to 2.
    # @param header_captions [hash] captions for columns where the default is not good enough. Hash in the form `{ column_name: 'Header caption' }`.
    # @param with_object [hash] object to use for values instead of the +@form_object+. Hash in the form `{ column_name: value }`.
    def compact_header(columns:, display_columns: 2, header_captions: {}, with_object: nil) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      raise Crossbeams::FrameworkError, "#{self.class} form object has not been set up before calling 'compact_header`" if @form_object.nil? && with_obejct.nil?

      if columns.first.is_a?(Array)
        raise Crossbeams::FrameworkError, "#{self.class} columns array has #{columns.length} column sets, which does not match `display_columns` (#{display_columns})." if columns.length != display_columns

        max = columns.map(&:length).max
        cols = []
        max.times { |n| columns.each { |a| cols << a[n] unless a[n].nil? } }
        # cols.each_slice(3) {|a| puts a.join(', ') }
      else
        cols = columns
      end
      row = 0
      cells = {}
      cols.each_with_index do |a, i|
        row += 1 if (i % display_columns).zero?
        cells[row] ||= []
        val = (with_object || @form_object)[a]
        val = val.to_s('F') if val.is_a?(BigDecimal)
        val = <<~HTML if val.is_a?(TrueClass)
          <div class="cbl-input dark-green">
            #{Crossbeams::Layout::Icon.render(:checkon, css_class: 'mr1')}
          </div>
        HTML
        val = <<~HTML if val.is_a?(FalseClass)
          <div class="cbl-input light-red">
            #{Crossbeams::Layout::Icon.render(:checkoff, css_class: 'mr1')}
          </div>
        HTML
        cells[row] << %(<td class="b gray">#{header_captions[a] || make_caption(a)}</td><td>#{val}</td>)
      end

      inner = cells.map do |_, v|
        %(<tr class="hover-row">#{v.join}</tr>)
      end.join

      @rules[:compact_header] = <<~HTML
        <table class="thinbordertable">
          #{inner}
        </table>
      HTML
    end

    def render_icon(icon)
      return '' if icon.nil?

      icon_parts = icon.split(',')
      svg = File.read(File.join(ENV['ROOT'], 'public/app_icons', "#{icon_parts.first}.svg"))
      color = icon_parts[1] || 'gray'
      %(<div class="crossbeams-field"><label>Icon</label><div class="cbl-input"><span class="cbl-icon" style="color:#{color}">#{svg}</span></div></div>)
    end

    def renderer_for_extcol(repo, config, caption)
      field = { caption: caption }
      if config[:masterlist_key]
        field[:renderer] = :select
        field[:prompt] = true
        field[:options] = repo.master_list_values(config[:masterlist_key])
      elsif %i[integer number numeric].include?(config[:type])
        field[:renderer] = config[:type]
      elsif config[:type] == :boolean
        field[:renderer] = :checkbox
      end
      field[:required] = true if config[:required]
      field[:pattern] = config[:pattern] if config[:pattern]
      field
    end

    def apply_extended_column_defaults_to_form_object(table)
      config = Crossbeams::Config::ExtendedColumnDefinitions.config_for(table)
      return if config.nil?

      col_with_default = {}
      config.each do |key, defn|
        next if defn[:default].nil?

        col_with_default[key.to_s] = defn[:default]
      end
      return if col_with_default.empty?

      if @form_object.is_a?(Hash) || @form_object.is_a?(OpenStruct)
        @form_object[:extended_columns] = col_with_default
      else
        hs = @form_object.to_h
        hs[:extended_columns] = col_with_default
        @form_object = OpenStruct(hs)
      end
    end

    def common_values_for_fields(value = nil)
      @rules[:fields] = value.nil? ? {} : value
    end

    def fields
      @rules[:fields]
    end

    def form_name(name)
      @rules[:name] = name
    end

    def behaviours
      behaviour = Behaviour.new
      yield behaviour
      @rules[:behaviours] = behaviour.rules
    end

    def apply_form_values # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      return unless @options && @options[:form_values]

      # We need to apply values to the form object, so make sure it is not immutable first.
      @form_object = OpenStruct.new(@form_object.to_h)

      @options[:form_values].each do |k, v|
        @form_object[k] = if v.is_a?(Hash)
                            v.transform_keys(&:to_s)
                          elsif v.is_a?(String) && v.empty?
                            nil
                          elsif v.is_a?(String) && (@form_object[k].is_a?(TrueClass) || @form_object[k].is_a?(FalseClass))
                            v == 't'
                          else
                            v
                          end
      end
    end

    def form_object_merge!(params)
      ok_type = { NilClass => true, Hash => true, OpenStruct => true }
      raise Crossbeams::FrameworkError, 'Cannot call "form_object_merge!" - @form_object is not mutable' unless ok_type[@form_object.class]

      @form_object ||= OpenStruct.new

      params.to_h.each do |k, v|
        @form_object[k] = v
      end
    end
  end

  class Behaviour
    attr_reader :rules

    def initialize
      @rules = []
    end

    def enable(field_to_enable, conditions = {})
      targets = Array(field_to_enable)
      observer = conditions[:when] || raise(ArgumentError, 'Enable behaviour requires `when`.')
      change_values = conditions[:changes_to]
      @rules << { observer => { change_affects: targets.join(';') } }
      targets.each do |target|
        @rules << { target => { enable_on_change: change_values } }
      end
    end

    def dropdown_change(field_name, conditions = {})
      raise(ArgumentError, 'Dropdown change behaviour requires `notify: url`.') if (conditions[:notify] || []).any? { |c| c[:url].nil? }

      @rules << { field_name => {
        notify: (conditions[:notify] || []).map do |n|
          {
            url: n[:url],
            param_keys: n[:param_keys] || [],
            param_values: n[:param_values] || {}
          }
        end
      } }
    end

    def populate_from_selected(field_name, conditions = {})
      @rules << { field_name => {
        populate_from_selected: (conditions[:populate_from_selected] || []).map do |p|
          {
            sortable: p[:sortable]
          }
        end
      } }
    end

    def keyup(field_name, conditions = {})
      raise(ArgumentError, 'Key up behaviour requires `notify: url`.') if (conditions[:notify] || []).any? { |c| c[:url].nil? }

      @rules << { field_name => {
        keyup: (conditions[:notify] || []).map do |n|
          {
            url: n[:url],
            param_keys: n[:param_keys] || [],
            param_values: n[:param_values] || {}
          }
        end
      } }
    end

    def input_change(field_name, conditions = {})
      raise(ArgumentError, 'Input change behaviour requires `notify: url`.') if (conditions[:notify] || []).any? { |c| c[:url].nil? }

      @rules << { field_name => {
        input_change: (conditions[:notify] || []).map do |n|
          {
            url: n[:url],
            param_keys: n[:param_keys] || [],
            param_values: n[:param_values] || {}
          }
        end
      } }
    end

    def lose_focus(field_name, conditions = {})
      raise(ArgumentError, 'Key up behaviour requires `notify: url`.') if (conditions[:notify] || []).any? { |c| c[:url].nil? }

      @rules << { field_name => {
        lose_focus: (conditions[:notify] || []).map do |n|
          {
            url: n[:url],
            param_keys: n[:param_keys] || [],
            param_values: n[:param_values] || {}
          }
        end
      } }
    end
  end

  class ChangeRenderer
    attr_reader :renderer

    def initialize(rule, router, options = {})
      klass = UiRules.const_get("#{rule.to_s.split('_').map(&:capitalize).join}ChangeRenderer")
      @renderer = klass.new(router, options)
    end

    def self.render_json(rule, router, method, options = {})
      rule = new(rule, router, options)
      rule.renderer.send(method)
    end
  end

  class BaseChangeRenderer
    attr_reader :router, :options, :params

    def initialize(router, options)
      @router = router
      @options = options
      @params = @options.delete(:params)
    end

    def build_actions(actions, message = nil, keep_dialog_open: false)
      args = []
      actions.each { |k, v| args += send(k, v) }
      router.json_actions(args, message, keep_dialog_open: keep_dialog_open)
    end

    private

    def replace_select_options(actions)
      actions.map do |act|
        OpenStruct.new(type: :replace_select_options,
                       dom_id: act[:dom_id],
                       options_array: act[:options])
      end
    end

    def replace_input_value(actions)
      actions.map do |act|
        OpenStruct.new(type: :replace_input_value,
                       dom_id: act[:dom_id],
                       value: act[:value])
      end
    end

    def change_select_value(actions)
      actions.map do |act|
        OpenStruct.new(type: :change_select_value,
                       dom_id: act[:dom_id],
                       value: act[:value])
      end
    end

    def replace_url(actions)
      actions.map do |act|
        OpenStruct.new(type: :replace_url,
                       dom_id: act[:dom_id],
                       value: act[:value])
      end
    end

    def replace_inner_html(actions)
      actions.map do |act|
        OpenStruct.new(type: :replace_inner_html,
                       dom_id: act[:dom_id],
                       value: act[:value])
      end
    end

    def replace_multi_options(actions)
      actions.map do |act|
        OpenStruct.new(type: :replace_multi_options,
                       dom_id: act[:dom_id],
                       options_array: act[:options])
      end
    end

    def replace_list_items(actions)
      actions.map do |act|
        OpenStruct.new(type: :replace_list_items,
                       dom_id: act[:dom_id],
                       items: act[:items])
      end
    end

    def set_readonly(actions) # rubocop:disable Naming/AccessorMethodName
      actions.map do |act|
        OpenStruct.new(type: :set_readonly,
                       dom_id: act[:dom_id],
                       readonly: act[:readonly])
      end
    end

    def set_checked(actions) # rubocop:disable Naming/AccessorMethodName
      actions.map do |act|
        OpenStruct.new(type: :set_checked,
                       dom_id: act[:dom_id],
                       checked: act[:checked])
      end
    end

    def set_required(actions) # rubocop:disable Naming/AccessorMethodName
      actions.map do |act|
        OpenStruct.new(type: :set_required,
                       dom_id: act[:dom_id],
                       required: act[:required])
      end
    end

    def hide_element(actions)
      actions.map do |act|
        OpenStruct.new(type: :hide_element,
                       dom_id: act[:dom_id],
                       reclaim_space: act[:reclaim_space])
      end
    end

    def show_element(actions)
      actions.map do |act|
        OpenStruct.new(type: :show_element,
                       dom_id: act[:dom_id],
                       reclaim_space: act[:reclaim_space])
      end
    end

    def launch_dialog(actions)
      actions.map do |act|
        OpenStruct.new(type: :launch_dialog,
                       content: act[:content])
      end
    end

    def clear_form_validation(actions)
      actions.map do |act|
        OpenStruct.new(type: :clear_form_validation,
                       dom_id: act[:dom_id])
      end
    end

    def add_grid_row(actions)
      actions.map do |act|
        OpenStruct.new(type: :add_grid_row,
                       attrs: act[:attrs],
                       grid_id: act[:grid_id])
      end
    end

    def update_grid_row(actions)
      actions.map do |act|
        OpenStruct.new(type: :update_grid_row,
                       ids: act[:ids],
                       changes: act[:changes],
                       grid_id: act[:grid_id])
      end
    end

    def delete_grid_row(actions)
      actions.map do |act|
        OpenStruct.new(type: :delete_grid_row,
                       id: act[:id],
                       grid_id: act[:grid_id])
      end
    end
  end
end
