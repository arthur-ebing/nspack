# frozen_string_literal: true

module DM
  module Admin
    class Debug # rubocop:disable Metrics/ClassLength
      include DataminerHelpers

      def call(id, opts) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        cols = opts[:columnDefs]
        cols.shift
        heads = Set.new
        cols.each { |c| c.each_key { |k| heads << k } }
        heads = %i[headerName field hide enableValue enableRowGroup enablePivot type width pinned cellRenderer cellClass valueFormatter]
        yesblank = ->(c) { c ? 'Y' : '' }
        trimfmt = ->(c) { (c || '').sub('crossbeamsGridFormatters.', '') }
        sqlfmt = ->(c) { "<pre>#{sql_to_highlight(c)}</pre>" }
        caption = opts[:grid_caption] && opts[:grid_caption] != opts[:caption] ? "#{opts[:caption]} (captioned: #{opts[:grid_caption]})" : opts[:caption]
        layout = Crossbeams::Layout::Page.new form_object: {}
        layout.build do |page, _| # rubocop:disable Metrics/BlockLength
          page.fold_up do |fold|
            fold.open!
            fold.caption 'SQL'
            fold.add_text caption, wrapper: :h2
            fold.add_text "File: #{opts[:root]}/#{id}.yml"
            fold.add_text(wrapped_sql(opts[:sql]), syntax: :sql)
          end

          set_cols = %i[setting applied?]
          set_rows = [
            { setting: 'Fit height?', applied?: opts[:fit_heigh] ? 'Y' : 'N' },
            { setting: 'Tree', applied?: opts[:tree] ? 'Y' : 'N' },
            { setting: 'Editable', applied?: opts[:fieldUpdateUrl] ? 'Y' : 'N' },
            { setting: 'Multiselect', applied?: opts[:multiselect_key] ? 'Y' : 'N' },
            { setting: 'Conditions', applied?: opts[:conditions] ? 'Y' : 'N' },
            { setting: 'Controls', applied?: opts[:page_controls] ? 'Y' : 'N' }
          ]
          page.fold_up do |fold|
            fold.caption 'Settings'
            fold.add_table set_rows,
                           set_cols,
                           top_margin: 4,
                           alignment: { applied?: :center }
          end

          if opts[:conditions_key]
            page.fold_up do |fold|
              fold.caption 'Conditions'
              fold.add_text "Key: #{opts[:conditions_key]}"
              fold.add_table opts[:conditions],
                             opts[:conditions].map(&:keys).flatten.uniq,
                             header_captions: { col: 'Column', op: 'Operator', val: 'Value' },
                             top_margin: 4
            end
          end

          if opts[:multiselect_key]
            ms_cols = %i[multiselect_key url preselect section_caption can_be_cleared multiselect_save_method conditions grid_caption]
            ms_rows = [
              { multiselect_key: opts[:multiselect_key],
                url: opts[:multiselect_opts][:url],
                preselect: opts[:multiselect_opts][:preselect],
                section_caption: opts[:multiselect_opts][:section_caption],
                can_be_cleared: opts[:multiselect_opts][:can_be_cleared] ? 'Y' : 'N' }
            ]
            page.fold_up do |fold|
              fold.caption 'Multiselect'
              fold.add_table ms_rows,
                             ms_cols,
                             pivot: true,
                             cell_transformers: { preselect: sqlfmt, section_caption: sqlfmt }
              fold.add_text "Pre-selected ids: #{opts[:multiselect_ids].inspect}" unless opts[:multiselect_ids].empty?
            end
          end

          unless opts[:edit_rules].empty?
            page.fold_up do |fold|
              fold.caption 'Edit rules'
              fold.add_text "Save url: #{opts[:fieldUpdateUrl]}"
              opts[:edit_rules][:editable_fields].each do |editable, config|
                fold.add_text "Editor for: <em>#{editable}</em>", wrapper: :strong
                fold.add_table [config],
                               config.keys,
                               cell_transformers: { value_sql: sqlfmt }
              end
            end
          end

          if opts[:calculated_columns]
            page.fold_up do |fold|
              fold.caption 'Calculated columns'
              fold.add_table opts[:calculated_columns],
                             opts[:calculated_columns].map(&:keys).flatten.uniq,
                             top_margin: 4
            end
          end

          unless opts[:page_controls].empty?
            page.fold_up do |fold|
              fold.caption 'Page controls'
              fold.add_table opts[:page_controls],
                             opts[:page_controls].map(&:keys).flatten.uniq,
                             top_margin: 4
            end
          end

          page.fold_up do |fold|
            fold.caption 'Grid columns'
            fold.add_table cols,
                           heads,
                           top_margin: 4,
                           header_captions: { headerName: 'Header',
                                              cellClass: 'Class',
                                              cellRenderer: 'Renderer',
                                              valueFormatter: 'Formatter',
                                              enableValue: 'Can sum?',
                                              enableRowGroup: 'Can group?',
                                              enablePivot: 'Can pivot?' },
                           alignment: { hide: :center,
                                        width: :right,
                                        enableValue: :center,
                                        enableRowGroup: :center,
                                        enablePivot: :center },
                           cell_transformers: { hide: yesblank,
                                                width: :integer,
                                                enableValue: yesblank,
                                                enableRowGroup: yesblank,
                                                enablePivot: yesblank,
                                                cellRenderer: trimfmt,
                                                valueFormatter: trimfmt }
          end
        end
      end
    end
  end
end
