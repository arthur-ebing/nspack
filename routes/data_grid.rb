# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

# TODO: Check that user has permission.
# - get pf.id and restricted_access values for url (could be more than one menu item and with/without restriction)
# Check if user has access
# SELECT -- NB this logic not right - restricted takes precedence
# EXISTS(SELECT pf.id FROM program_functions pf JOIN programs_users pu ON pu.program_id = pf.program_id
#                            WHERE pf.url = '/list/target_markets' AND pu.user_id = 33)
#                            OR
#                            EXISTS(SELECT pf.id
#                            FROM program_functions pf
#                            JOIN program_functions_users pfu ON pfu.program_function_id = pf.id
#                            WHERE pf.url = '/dataminer/admin/reports'
#                              AND pf.restricted_user_access
#                                AND pfu.user_id = 33) AS has_permission
#
# - url might not be a program function.
#   = then ok to continue.
#   = unless url was entered in browser (is there a difference in the referer?)
class Nspack < Roda # rubocop:disable Metrics/ClassLength
  # Generic grid lists.
  route('list') do |r|
    r.on :id do |id|
      r.is do
        session[:last_grid_url] = "/list/#{id}"
        opts = { fit_height: true, bookmark_row_on_action: !fetch?(r) }
        opts[:query_string] = request.query_string if request.query_string
        opts[:client_rule_check] = ->(args) { Crossbeams::Config::ClientRuleChecker.rule_passed?(*args) }
        show_page { render_data_grid_page(id, opts) }
      end

      r.on 'debug' do
        # Perhaps move this to a roda-data_grid method.... (include params in SQL etc.)
        context = { for_grid_queries: true, route_url: request.path, request_ip: request.ip }
        interactor = DataminerApp::DataminerInteractor.new(current_user, {}, context, {})
        res = interactor.show_debug_query("grid-definitions_#{id}")
        xtra = case r.remaining_path
               when '/with_params'
                 "<p>Parameterised list: #{params.inspect}</p>"
               when '/multi'
                 "<p>Multiselect list: #{params.inspect}</p>"
               else
                 ''
               end
        view(inline: <<~HTML)
          <h2>Debug list: #{res.instance[:caption]}</h2>
          <p>#{res.instance[:file]}</p>
          #{xtra}
          <div>#{sql_to_highlight(res.instance[:sql])}</div>
        HTML
      end

      r.on 'with_params' do
        # Pass query_string rather than params as it is passed through directly
        # to the grid div's url.
        if fetch?(r)
          show_partial do
            render_data_grid_page(id,
                                  query_string: request.query_string,
                                  client_rule_check: ->(args) { Crossbeams::Config::ClientRuleChecker.rule_passed?(*args) })
          end
        else
          session[:last_grid_url] = "/list/#{id}/with_params?#{request.query_string}"
          show_page do
            render_data_grid_page(id,
                                  query_string: request.query_string,
                                  fit_height: true,
                                  bookmark_row_on_action: true,
                                  client_rule_check: ->(args) { Crossbeams::Config::ClientRuleChecker.rule_passed?(*args) })
          end
        end
      end

      r.on 'multi' do
        if fetch?(r)
          show_partial do
            render_data_grid_page_multiselect(id,
                                              params.merge(client_rule_check: ->(args) { Crossbeams::Config::ClientRuleChecker.rule_passed?(*args) }))
          end
        else
          show_page do
            render_data_grid_page_multiselect(id,
                                              params.merge(fit_height: true,
                                                           client_rule_check: ->(args) { Crossbeams::Config::ClientRuleChecker.rule_passed?(*args) }))
          end
        end
      end

      r.on 'grid' do
        if params && !params.empty?
          render_data_grid_rows(id,
                                ->(function, program, permission) { auth_blocked?(function, program.split(','), permission) },
                                ->(args) { Crossbeams::Config::UserPermissions.can_user?(current_user, *args) },
                                ->(args) { Crossbeams::Config::ClientRuleChecker.rule_passed?(*args) },
                                params)
        else
          render_data_grid_rows(id,
                                ->(function, program, permission) { auth_blocked?(function, program.split(','), permission) },
                                ->(args) { Crossbeams::Config::UserPermissions.can_user?(current_user, *args) },
                                ->(args) { Crossbeams::Config::ClientRuleChecker.rule_passed?(*args) })
        end
      rescue StandardError => e
        ErrorMailer.send_exception_email(e,
                                         subject: "Grid error at #{request.path}",
                                         message: "Route  : data_grid\nPath   : #{request.path}\nParams : #{params&.inspect}")
        show_json_exception(e)
      end

      r.on 'grid_multi', String do |key|
        render_data_grid_multiselect_rows(id,
                                          ->(function, program, permission) { auth_blocked?(function, program.split(','), permission) },
                                          ->(*args) { Crossbeams::Config::UserPermissions.can_user?(current_user, *args) },
                                          ->(args) { Crossbeams::Config::ClientRuleChecker.rule_passed?(*args) },
                                          key,
                                          params)
      rescue StandardError => e
        ErrorMailer.send_exception_email(e,
                                         subject: "Grid error at #{request.path}",
                                         message: "Route  : data_grid_multi\nPath   : #{request.path}\nParams : #{params&.inspect}")
        show_json_exception(e)
      end

      r.on 'nested_grid' do
        render_data_grid_nested_rows(id)
      rescue StandardError => e
        ErrorMailer.send_exception_email(e,
                                         subject: "Grid error at #{request.path}",
                                         message: "Route  : data_grid_nested\nPath   : #{request.path}\nParams : #{params&.inspect}")
        show_json_exception(e)
      end
    end
  end

  # Lookup grids
  route('lookups') do |r|
    r.on String, String do |id, key|
      r.is do
        show_partial { render_data_grid_page_lookup(id, key, params) }
      end

      r.on 'grid' do
        render_data_grid_lookup_rows(id,
                                     ->(function, program, permission) { auth_blocked?(function, program.split(','), permission) },
                                     ->(*args) { Crossbeams::Config::UserPermissions.can_user?(current_user, *args) },
                                     ->(args) { Crossbeams::Config::ClientRuleChecker.rule_passed?(*args) },
                                     key,
                                     params)
      rescue StandardError => e
        ErrorMailer.send_exception_email(e,
                                         subject: "Grid error at #{request.path}",
                                         message: "Route  : data_grid_lookups\nPath   : #{request.path}\nParams : #{params&.inspect}")
        show_json_exception(e)
      end
    end
  end

  route('print_grid') do
    @layout = Crossbeams::Layout::Page.build(grid_url: params[:grid_url]) do |page, _|
      page.add_grid('crossbeamsPrintGrid', params[:grid_url], caption: 'Print', for_print: true)
    end
    view('crossbeams_layout_page', layout: 'print_layout')
  end

  # Generic code for grid searches.
  route('search') do |r|
    r.on :id do |id|
      r.is do
        render_search_filter(id, params)
      end

      r.on 'run' do
        session[:last_grid_url] = "/search/#{id}?rerun=y"
        show_page { render_search_grid_page(id, params.merge(fit_height: true)) }
      end

      r.on 'grid' do
        render_search_grid_rows(id,
                                params,
                                ->(args) { Crossbeams::Config::ClientRuleChecker.rule_passed?(*args) },
                                ->(function, program, permission) { auth_blocked?(function, program.split(','), permission) })
      rescue StandardError => e
        ErrorMailer.send_exception_email(e,
                                         subject: "Grid error at #{request.path}",
                                         message: "Route  : data_grid_search\nPath   : #{request.path}\nParams : #{params&.inspect}")
        show_json_exception(e)
      end

      r.on 'xls' do
        caption, xls = render_excel_rows(id, params)
        response.headers['content_type'] = 'application/vnd.ms-excel'
        response.headers['Content-Disposition'] = "attachment; filename=\"#{caption.strip.gsub(%r{[/:*?"\\<>\|\r\n]}i, '-') + '.xls'}\""
        response.write(xls) # NOTE: could this use streaming to start downloading quicker?
      end
    end
  end
end

# rubocop:enable Metrics/BlockLength
