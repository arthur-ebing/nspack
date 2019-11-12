# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/BlockLength

require './app_loader'

class Nspack < Roda
  include CommonHelpers
  include ErrorHelpers
  include MenuHelpers
  include DataminerHelpers
  include RmdHelpers

  use Rack::Session::Cookie, secret: 'some_other_nice_long_random_string_DSKJH4378EYR7EGKUFH', key: '_myapp_session'
  use Rack::MethodOverride # Use with all_verbs plugin to allow 'r.delete' etc.
  use Crossbeams::RackMiddleware::Banner, template: 'views/_page_banner.erb' # , session: request.session

  plugin :data_grid, path: File.dirname(__FILE__),
                     list_url: '/list/%s/grid',
                     list_nested_url: '/list/%s/nested_grid',
                     list_multi_url: '/list/%s/grid_multi',
                     search_url: '/search/%s/grid',
                     filter_url: '/search/%s',
                     run_search_url: '/search/%s/run',
                     run_to_excel_url: '/search/%s/xls'
  plugin :all_verbs
  plugin :render, template_opts: { default_encoding: 'UTF-8' }
  plugin :partials
  plugin :assets, css: 'style.scss', precompiled: 'prestyle.css'  # , js: 'behave.js'
  plugin :public # serve assets from public folder.
  plugin :view_options
  plugin :multi_route
  plugin :content_for, append: true
  plugin :symbolized_params    # - automatically converts all keys of params to symbols.
  plugin :flash
  plugin :csrf, raise: true, # , :skip => ['POST:/report_error'] # FIXME: Remove the +raise+ param when going live!
                csrf_header: 'X-CSRF-Token',
                skip_if: ->(req) do # rubocop:disable Style/Lambda
                  ENV['RACK_ENV'] == 'test' || AppConst::BYPASS_LOGIN_ROUTES.any? do |path|
                    if path.end_with?('*')
                      req.path.match?(/#{path}/)
                    else
                      req.path == path
                    end
                  end
                end
  plugin :json_parser
  plugin :message_bus
  plugin :status_handler
  plugin :cookies, path: '/'
  plugin :rodauth do
    db DB
    enable :login, :logout # , :change_password
    logout_route 'a_dummy_route' # Override 'logout' route so that we have control over it.
    # logout_notice_flash 'Logged out'
    session_key :user_id
    login_param 'login_name'
    login_label 'Login name'
    login_column :login_name
    accounts_table :vw_active_users # Only active users can login.
    account_password_hash_column :password_hash
    template_opts(layout_opts: { path: 'views/layout_auth.erb' })
    after_login do
      # On successful login, see if the user had given a specific path that required the login and redirect to it.
      path = request.cookies['pre_login_path']
      response.delete_cookie('pre_login_path')
      redirect(path) if path && scope.can_login_to_path?(path, account[:id])
    end
  end
  unless ENV['RACK_ENV'] == 'development' && ENV['NO_ERR_HANDLE']
    plugin :error_mail, to: AppConst::ERROR_MAIL_RECIPIENTS,
                        from: AppConst::SYSTEM_MAIL_SENDER,
                        prefix: "[Error #{AppConst::ERROR_MAIL_PREFIX}] "
    plugin :error_handler do |e|
      error_mail(e) unless [Crossbeams::AuthorizationError,
                            Crossbeams::TaskNotPermittedError,
                            Crossbeams::InfoError,
                            Sequel::UniqueConstraintViolation,
                            Sequel::ForeignKeyConstraintViolation].any? { |o| e.is_a? o }
      show_error(e, request.has_header?('HTTP_X_CUSTOM_REQUEST_TYPE'))
      # = if prod and unexpected exception type, just display "something whent wrong" and log
    end
  end
  Dir['./routes/*.rb'].each { |f| require f }

  route do |r|
    r.assets unless ENV['RACK_ENV'] == 'production'
    r.public

    initialize_route_instance_vars

    ### p request.ip
    # Routes that must work without authentication
    # --------------------------------------------
    r.on 'webquery', String do |id|
      # A dummy user
      user = DevelopmentApp::User.new(id: 0, login_name: 'webquery', user_name: 'webquery', password_hash: 'dummy', email: nil, active: true)
      interactor = DataminerApp::PreparedReportInteractor.new(user, {}, { route_url: request.path, request_ip: request.ip }, {})
      interactor.prepared_report_as_html(id)
    end

    # https://support.office.com/en-us/article/import-data-from-database-using-native-database-query-power-query-f4f448ac-70d5-445b-a6ba-302db47a1b00?ui=en-US&rs=en-US&ad=US
    r.on 'xmlreport', String do |id|
      # A dummy user
      user = DevelopmentApp::User.new(id: 0, login_name: 'webquery', user_name: 'webquery', password_hash: 'dummy', email: nil, active: true)
      interactor = DataminerApp::PreparedReportInteractor.new(user, {}, { route_url: request.path, request_ip: request.ip }, {})
      interactor.prepared_report_as_xml(id)
    end
    # Do the same as XML?
    # --------------------------------------------

    r.on 'loading_window' do
      view(inline: 'Loading...', layout: 'layout_loading')
    end

    r.on 'test_jasper' do
      @layout = Crossbeams::Layout::Page.build do |page, _|
        page.section do |section|
          section.add_text('Test a Jasper report', wrapper: :h2)
          section.add_control(control_type: :link, text: 'Load Jasper report', url: '/render_jasper_test', loading_window: true, style: :button)
        end
      end
      view('crossbeams_layout_page')
    end

    r.on 'render_jasper_test' do
      res = CreateJasperReport.call(report_name: 'test_framework',
                                    user: current_user.login_name,
                                    file: 'testj_rpt',
                                    params: { invoice_id: 1,
                                              invoice_type: 'CUSTOMER',
                                              keep_file: true })
      if res.success
        # show_json_notice('Sent to printer')
        change_window_location_via_json(res.instance, request.path)
      else
        show_error(res.message, fetch?(r))
      end
    end

    unless AppConst::BYPASS_LOGIN_ROUTES.any? do |path|
      if path.end_with?('*')
        request.path.match?(/#{path}/)
      else
        request.path == path
      end
    end
      r.rodauth
      # Store this path before login so we can redirect after login. NB. Only a GET request!
      response.set_cookie('pre_login_path', r.fullpath) unless rodauth.logged_in? || r.path == '/login' || !request.get? || fetch?(r)
      rodauth.require_authentication
      r.redirect('/login') if current_user.nil? # Session might have the incorrect user_id
    end

    r.root do
      # TODO: Config this, and maybe set it up per user.
      if @registered_mobile_device && !@hybrid_device
        r.redirect @rmd_start_page || '/rmd/home'
      else
        page = user_homepage
        r.redirect page unless page.nil?
        view(inline: '<p>Welcome<p>')
      end
    end

    r.on 'developer_documentation', String do |file|
      # Docs are in developer_documentation in asciidoc format named file.adoc.
      # Guide to writing docs: http://asciidoctor.org/docs/asciidoc-writers-guide
      content = File.read(File.join(File.dirname(__FILE__), 'developer_documentation', "#{file.chomp('.adoc')}.adoc"))
      @documentation_page = true
      view(inline: <<~HTML)
        <% content_for :late_head do %>
          <link rel="stylesheet" href="/css/asciidoc.css">
        <% end %>
        #{render_asciidoc(content)}
      HTML
    end

    r.on 'search_developer_documentation' do
      search = DocSearch.new(:devdoc)
      content = search.search_for(params[:search_term])
      @documentation_page = true
      view(inline: content)
    end

    r.on 'yarddocthis', String do |file|
      # Reads Yard doc comments for a file and displays them.
      # NB: The file param must have all '/' in the name replaced with '='.
      filename = File.join(File.dirname(__FILE__), file.tr('=', '/'))
      YARD::Registry.clear
      YARD.parse_string(File.read(filename))
      mds = YARD::Registry.all(:method)
      toc = []
      out = []
      mds.sort_by(&:name).each do |m|
        next if m.visibility == :private

        toc << m.name
        parms = m.tags.select { |tag| tag.tag_name == 'param' }.map do |tag|
          opts = m.tags.select { |opt| opt.tag_name == 'option' && opt.name == tag.name }.map do |opt|
            "#{opt.pair.name} (#{opt.pair.types.join(', ')}): #{opt.pair.text}"
          end
          if opts.empty?
            "#{tag.name} (#{tag.types.join(', ')}): #{tag.text}"
          else
            <<~HTML
              #{tag.name} (#{tag.types.join(', ')}): #{tag.text}
              <ul><li>#{opts.join('</li><li>')}
            HTML
          end
        end

        rets = m.tags.select { |t| t.tag_name == 'return' }.map { |t| [t.types.join(','), t.text].compact.join(': ').strip }
        out << <<~HTML
          <a id="#{m.name}"></a><h2>#{m.name}</h2>
          <table>
          <tr><th>Method:</th><td>#{m.signature.sub('def ', '')}</td></tr>
          <tr><th>       </th><td><pre>#{m.docstring}</pre></td></tr>
          <tr><th>Params:</th><td>#{parms.empty? ? '' : "<ul><li>#{parms.join('</li><li>')}</ul>"}</td></tr>
          <tr><th>Return:</th><td>#{rets.empty? ? '' : rets.join(', ')}</td></tr>
          </table>
        HTML
      end

      @documentation_page = true
      view(inline: <<~HTML)
        <% content_for :late_head do %>
          <link rel="stylesheet" href="/css/asciidoc.css">
        <% end %>
        <div id="asciidoc-content">
          <h1>Yard documentation for methods in #{file.tr('=', '/')}</h1>
          #{request.referer.nil? ? '' : "<p><a href='#{request.referer}'>Back</a></p>"}
          <p>NB. This reads the source file to build the docs, so it is always up-to-date.
          Note that this simple code might pick up some extra definitions and also note that
          it uses Yard in a way it was not designed for, so this could all break with an update to Yard.</p>
          <ul>#{toc.map { |t| "<li><a href='##{t}'>#{t}</a></li>" }.join("\n")}</ul>
          #{out.join("\n")}
        </div>
      HTML
    end

    return_json_response if fetch?(r)
    r.multi_route

    r.on 'iframe', Integer do |id|
      repo = SecurityApp::MenuRepo.new
      pf = repo.find_program_function(id)
      view(inline: %(<iframe src="#{pf.url}" title="#{pf.program_function_name}" width="100%" style="height:80vh"></iframe>))
    end

    r.is 'test' do
      # # Need to design a "query-able version of this query (join locn + tree so user can select type, ancestor etc...
      # qry = <<~SQL
      #   SELECT
      #   (SELECT array_agg(cc.location_long_code) as path
      #    FROM (SELECT c.location_long_code
      #    FROM location_tests AS c
      #    JOIN location_tree_paths AS t1 ON t1.ancestor_location_id = c.id
      #    WHERE t1.descendant_location_id = l.id ORDER BY t1.path_length DESC) AS cc) AS path_array,
      #   (SELECT string_agg(cc.location_long_code, ',') as path
      #    FROM (SELECT c.location_long_code
      #    FROM location_tests AS c
      #    JOIN location_tree_paths AS t1 ON t1.ancestor_location_id = c.id
      #    WHERE t1.descendant_location_id = l.id ORDER BY t1.path_length DESC) AS cc) AS path_string,
      #   l.location_long_code, l.location_type, l.has_single_container, l.is_virtual,
      #   (SELECT MAX(path_length) FROM location_tree_paths WHERE descendant_location_id = l.id) + 1 AS level
      #   FROM location_tests l
      # SQL
      # @rows = DB[qry].all.to_json
      # view('test_view')
      # res = PackMaterialApp::TestJob.enqueue(current_user.id, time: Time.now)
      # res = DevelopmentApp::SendMailJob.enqueue(from: 'jamessil@telkomsa.net', to: 'james@nosoft.biz', subject: 'Test mail job', body: "Hi me\n\nTrying to test sending mail.\nThis using the SendMailJob.\n\nReg\nJames", cc: 'jamesmelanie@telkomsa.net')
      res = DevelopmentApp::SendMailJob.enqueue(to: 'james@nosoft.biz',
                                                subject: 'Test mail job',
                                                body: "Hi me\n\nTrying to test sending mail.\nThis using the SendMailJob.\n\nReg\nJames",
                                                cc: 'jamesmelanie@telkomsa.net',
                                                attachments: [{ path: '/home/james/ra/crossbeams/framework/CHANGELOG.md' },
                                                              { filename: 'some_text.txt', content: File.read('tcp_serv.rb') }])
      view(inline: "Added job: #{res.inspect}<p>Que stats: #{Que.job_stats.inspect}</p>")
      # mail = Mail.new do
      #   from    'jamessil@telkomsa.net'
      #   to      'james@nosoft.biz'
      #   subject 'Test Mail from framework'
      #   body    "Hi me\n\nTrying to test sending mail.\nThis using the SendMailJob.\n\nReg\nJames"
      # end
      # res = mail.deliver
      # view(inline: "Sent mail?: #{res}")
    end

    r.is 'logout' do
      if session[:act_as_user_id]
        revert_to_logged_in_user
        r.redirect('/')
      else
        rodauth.logout
        flash[:notice] = 'Logged out'
        r.redirect('/login')
      end
    end

    r.is 'versions' do
      versions = LibraryVersions.new(:layout,
                                     :dataminer,
                                     :label_designer,
                                     :rackmid,
                                     :datagrid,
                                     :ag_grid,
                                     :choices,
                                     :sortable,
                                     :konva,
                                     :lodash,
                                     :multi,
                                     :sweetalert)
      @layout = Crossbeams::Layout::Page.build do |page, _|
        page.section do |section|
          section.add_text('Gem and Javascript library versions', wrapper: :h2)
          section.add_table(versions.to_a, versions.columns, alignment: { version: :right })
        end
      end
      view('crossbeams_layout_page')
    end

    r.is 'not_found' do
      response.status = 404
      view(inline: '<div class="crossbeams-error-note"><strong>Error</strong><br>The requested resource was not found.</div>')
    end

    r.on 'terminus' do
      r.message_bus
      # view(inline: 'Maybe we show all unattended messages for a user here')
    end

    # - :url: "/list/users/multi?key=program_users&id=$:id$/"

    # In-page grids (no last grid_url)
    # 1) list with multi-select - might need last_grid
    # 2) list_section - never use last_grid
    r.on 'list_section' do
      # list_section/users/?user_id=123&multi_select=fredo
      # open users yml & look for fredo multiselect to get rules
      #
      # list_section/users/?user_id=123
      # open users yml & apply user_id param
      #
    end

    # LABEL DESIGNER
    # ----------------------------------------------------------------------

    r.on 'label_designer' do
      interactor = LabelApp::LabelInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.is do
        @label_edit_page = true
        view(inline: interactor.label_designer_page(label_name: params[:label_name],
                                                    label_dimension: params[:label_dimension],
                                                    variable_set: params[:variable_set],
                                                    px_per_mm: params[:px_per_mm]))
      end
    end

    r.on 'save_label' do
      interactor = LabelApp::LabelInteractor.new(current_user, {}, { route_url: request.path, request_ip: request.ip }, {})
      r.on :id do |id|
        r.post do
          repo = LabelApp::LabelRepo.new
          changeset = { label_json: params[:label],
                        variable_xml: params[:XMLString],
                        png_image: Sequel.blob(interactor.image_from_param(params[:imageString])) }
          DB.transaction do
            repo.update_label(id, interactor.include_updated_by_in_changeset(changeset))
            repo.log_action(user_name: current_user.user_name, context: 'update label', route_url: request.path, request_ip: request.ip)
          end

          flash[:notice] = 'Updated'
          redirect_via_json "/labels/labels/labels/#{id}/edit"
        end
      end

      r.post do
        # if session new_label_attr nil? redirect to list with an error message
        repo = LabelApp::LabelRepo.new
        extra_attributes = session[:new_label_attributes] ### WHAT IF THESE nil? (as happened at SRCC at 00:40) <session cleared? problem if cloned? OR double-send? - 1st end has session data and second has it replaced with nil...>
        extcols = interactor.select_extended_columns_params(extra_attributes)
        from_id = extra_attributes[:cloned_from_id]
        changeset = { label_json: params[:label],
                      label_name: params[:labelName],
                      label_dimension: params[:labelDimension],
                      px_per_mm: params[:pixelPerMM],
                      # container_type: extra_attributes[:container_type],
                      # commodity: extra_attributes[:commodity],
                      # market: extra_attributes[:market],
                      # language: extra_attributes[:language],
                      # category: extra_attributes[:category],
                      # sub_category: extra_attributes[:sub_category],
                      variable_set: extra_attributes[:variable_set],
                      variable_xml: params[:XMLString],
                      png_image: Sequel.blob(interactor.image_from_param(params[:imageString])) }

        id = nil
        DB.transaction do
          id = repo.create_label(interactor.include_created_by_in_changeset(interactor.add_extended_columns_to_changeset(changeset, repo, extcols)))
          if from_id.nil?
            repo.log_status('labels', id, 'CREATED', user_name: current_user.user_name)
          else
            from_lbl = repo.find_label(from_id)
            repo.log_status('labels', id, 'CLONED', comment: "from #{from_lbl.label_name}", user_name: current_user.user_name)
          end
          repo.log_action(user_name: current_user.user_name, context: 'create label', route_url: request.path, request_ip: request.ip)
        end
        session[:new_label_attributes] = nil
        flash[:notice] = 'Created'
        redirect_via_json "/labels/labels/labels/#{id}/edit"
      end
    end
  end

  status_handler(404) do
    view(inline: '<div class="crossbeams-error-note"><strong>Error</strong><br>The requested resource was not found.</div>')
  end

  def render_asciidoc(content, image_dir = '/documentation_images')
    <<~HTML
      <div id="asciidoc-content">
        #{Asciidoctor.convert(content, safe: :safe, attributes: { 'source-highlighter' => 'coderay', 'coderay-css' => 'style', 'imagesdir' => image_dir })}
      </div>
    HTML
  end
end
# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/BlockLength
