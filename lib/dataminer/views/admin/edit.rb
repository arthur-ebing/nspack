# frozen_string_literal: true

module DM
  module Admin
    class Edit
      extend DataminerHelpers

      def self.call(details, form_errors: nil, form_values: nil)
        ui_rule = UiRules::Compiler.new(:dataminer_report, :edit, details: details, form_values: form_values)
        rules   = ui_rule.compile

        Crossbeams::Layout::Page.build(rules) do |page|
          page.add_text "Report: #{details.report.caption}", wrapper: :h1
          page.form_object ui_rule.form_object
          page.section do |section|
            section.show_border!
            section.form do |form|
              form.form_values form_values
              form.form_errors form_errors
              form.action "/dataminer/admin/#{details.id}/save"
              form.add_field :filename
              form.add_field :caption
              form.add_field :limit
              form.add_field :offset
              form.add_field :render_url
              form.submit_captions 'Update report header', 'Updating'
            end
          end
          page.section do |section|
            section.show_border!
            section.add_text "<pre>#{sql_to_highlight(details.report.runnable_sql)}</pre>", toggle_button: true, toggle_caption: 'Toggle SQL view'
            section.add_control(control_type: :link,
                                text: 'Change SQL',
                                icon: :edit,
                                url: "/dataminer/admin/#{details.id}/change_sql",
                                style: :button)
            section.add_control(control_type: :link,
                                text: 'Re-order columns',
                                icon: :sort,
                                url: "/dataminer/admin/#{details.id}/reorder_columns",
                                style: :button)
            unless details.has_id_col
              section.add_notice('Queries should preferably include a column named "id" with unique values.',
                                 notice_type: :warning, within_field: false,
                                 caption: 'There is no column named "id".')
            end
          end

          if details.report.columns['colour_rule']
            page.section do |section|
              cols = Crossbeams::DataGrid::ColumnDefiner.new.make_columns do |mk|
                mk.col 'id', nil, hide: true
                mk.col 'description', nil, editable: true, width: 500
                mk.col 'colour_rule'
              end
              rows = []
              details.report.external_settings[:colour_key].each do |k, v|
                rows << { id: k, description: v, colour_rule: k }
              end
              section.add_grid('grd0',
                               nil,
                               height: 10,
                               extra_context: { keyColumn: 'id' },
                               bookmark_row_on_action: false,
                               field_update_url: "/dataminer/admin/#{details.id}/save_colour_key_desc",
                               col_defs: cols,
                               row_defs: rows,
                               caption: 'Fill in Colour Key descriptions')
            end
          end
          page.section do |section|
            section.add_grid('grd1',
                             nil,
                             height: 20,
                             bookmark_row_on_action: false,
                             extra_context: { keyColumn: 'name' },
                             # multiselect_ids: [],
                             field_update_url: details.save_url,
                             col_defs: details.col_defs,
                             row_defs: details.row_defs,
                             caption: 'Columns')
          end
          page.section do |section|
            section.add_control control_type: :link, text: 'Add a parameter', url: "/dataminer/admin/#{details.id}/parameter/new", style: :button, icon: :plus, css_class: 'bg-blue'
          end
          page.section do |section|
            section.add_grid('grd2',
                             nil, # "/dataminer/admin/#{details.id}/edit/columns_grid",
                             height: 20,
                             field_update_url: details.save_url,
                             col_defs: details.col_defs_params,
                             row_defs: details.row_defs_params,
                             caption: 'Parameters')
          end
          # # page.form_object ui_rule.form_object
          # page.form_object obj
          # page.form_values form_values
          # page.form_errors form_errors
          # page.form do |form|
          #   form.action "/dataminer/admin/#{id}/save_new_sql"
          #   # form.remote!
          #   form.method :update
          #   form.row do |row|
          #     row.column do |col|
          #       # col.relative_width = 2-3
          #       col.add_field :id
          #       col.add_field :sql
          #     end
          #     row.column do |col|
          #       # col.relative_width = 1-3
          #       col.fold_up do |fold|
          #         fold.caption 'A few useful SQL snippets'
          #         fold.add_text <<~SQL, syntax: :sql
          #           -- Use row number as id
          #           ROW_NUMBER() OVER() AS id
          #
          #           -- Collect several strings into one column
          #           (SELECT string_agg(code, '; ')
          #           FROM (SELECT code
          #                 FROM table_two
          #                 WHERE table_two.id = table_one.table_two_id) sub) AS all_codes
          #
          #           -- Status column
          #           fn_current_status('tablename', tablename.id) AS status
          #         SQL
          #       end
          #     end
          #   end
          # end
        end
      end
    end
  end
end
