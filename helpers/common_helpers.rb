module CommonHelpers # rubocop:disable Metrics/ModuleLength
  # Show a Crossbeams::Layout page
  # - The block must return a Crossbeams::Layout::Page
  def show_page(&block)
    @layout = block.yield
    @layout.add_csrf_tag(csrf_tag)
    view('crossbeams_layout_page')
  end

  # Show a Crossbeams::Layout page rendered in a particular page layout
  # - The block must return a Crossbeams::Layout::Page
  def show_page_in_layout(layout, &block)
    @layout = block.yield
    @layout.add_csrf_tag(csrf_tag)
    view('crossbeams_layout_page', layout: layout)
  end

  # RMD pages always render in layout_rmd.
  def show_rmd_page(&block)
    show_page_in_layout('layout_rmd', &block)
  end

  # Display the last lines of a log file in the browser
  # @param name [string] - the title for the log file
  # @param file [string] - the file path
  # @param lines [integer] - the number of lines to show
  def view_log_file(name, file, lines)
    view(inline: <<~HTML)
      <h1>#{name}</h1>
      <p>Showing last #{lines} lines<br>(add <em>?lines=nn</em> to the URL to change no of lines shown)<p>
      <pre>
      #{`tail -n#{lines} #{file}`}
      </pre>
    HTML
  end

  # Render a block of Crossbeams::Layout DSL as string.
  #
  # @return [String] HTML layout and content string.
  def render_partial(&block)
    @layout = block.yield
    @layout.add_csrf_tag(csrf_tag)
    @layout.render
  end

  def show_partial(notice: nil, error: nil, &block)
    content = render_partial(&block)
    update_dialog_content(content: content, notice: notice, error: error)
  end

  def show_partial_or_page(route, &block)
    page = stashed_page
    if page
      show_page { page }
    elsif fetch?(route)
      show_partial(&block)
    else
      show_page(&block)
    end
  end

  def re_show_form(route, res, url: nil, &block)
    form = block.yield
    if fetch?(route)
      content = render_partial { form }
      update_dialog_content(content: content, error: res.message)
    else
      flash[:error] = res.message&.tr("\n", ' ')
      stash_page(form)
      route.redirect url || '/'
    end
  end

  def show_page_or_update_dialog(route, res, &block)
    if fetch?(route)
      content = render_partial(&block)
      update_dialog_content(content: content, notice: res.message)
    else
      flash[:notice] = res.message
      show_page(&block)
    end
  end

  # Display content in a Crossbeams::Layout::CallbackSection.
  #
  # @param content [nil, string] the content. Ignored if a block is provided.
  # @param content_style [nil, symbol] optional styling for content [:info, :success, :warning, :error]
  # @param notice [nil, string] an optional flash notice.
  # @param error [nil, string] an optional flash error.
  # @param block [block] a block that yields ERB string to be passed to render_partial.
  # @return [JSON] formatted to be interpreted by javascript to replace a callback section.
  def show_in_callback(content: nil, content_style: nil, notice: nil, error: nil, &block)
    raise ArgumentError, 'Invalid content style' unless [nil, :info, :success, :warning, :error].include?(content_style)

    res = {}
    res[:content] = if block_given?
                      render_partial(&block)
                    else
                      # content
                      wrap_content_in_style(content, content_style)
                    end
    res[:flash] = { notice: notice } if notice
    res[:flash] = { error: error } if error
    res.to_json
  end

  CONTENT_STYLE_HEAD = {
    info: 'Note:',
    success: 'Success:',
    warning: 'Warning:',
    error: 'Error:'
  }.freeze

  # Wrap content in styling (a heading div and content).
  # Example
  #   wrap_content_in_style('A note', :info) #=>
  #   "< div class="crossbeams-info-note" >
  #     < p >< strong >Note:< /strong>< /p >
  #     < p >A note< /p >
  #   < /div >"
  #
  # @param content [string] the content to be rendered.
  # @param content_style [symbol] if nil, the content is returned unwrapped. [:info, :success, :warning, :error] are styled appropriately.
  # @param caption [string] optional caption to override the default which is based on the style.
  # @return [HTML]
  def wrap_content_in_style(content, content_style, caption: nil)
    return content if content_style.nil?

    css = "crossbeams-#{content_style}-note"
    head = CONTENT_STYLE_HEAD[content_style]
    "<div class='#{css}'><p><strong>#{caption || head}</strong></p><p>#{content}</p></div>"
  end

  # Add validation errors that are not linked to a field in a form.
  #
  # @param messages [Hash] the current hash of validation messages.
  # @param base_messages [String, Array] the new messages to be added to the base of the form.
  # @return [Hash] the expanded validation messages.
  def add_base_validation_errors(messages, base_messages)
    if messages && messages[:base]
      interim = messages
      interim[:base] += Array(base_messages)
      interim
    else
      (messages || {}).merge(base: Array(base_messages))
    end
  end

  # Add validation errors that are not linked to a field in a form.
  # At the same time highlight one or more fields in error
  #
  # @param messages [Hash] the current hash of validation messages.
  # @param base_messages [String, Array] the new messages to be added to the base of the form.
  # @param fields [Array] the fields in the form to be highlighted.
  # @return [Hash] the expanded validation messages.
  def add_base_validation_errors_with_highlights(messages, base_messages, fields)
    if messages && messages[:base_with_highlights]
      interim = messages
      interim[:base_with_highlights][:messages] += Array(base_messages)
      curr = Array(interim[:base_with_highlights][:highlights])
      interim[:base_with_highlights][:highlights] = curr + Array(fields)
      interim
    else
      (messages || {}).merge(base_with_highlights: { messages: Array(base_messages), highlights: fields })
    end
  end

  # Move validation errors that are linked to a specific key up to base.
  # Optionally also  highlight one or more fields in error.
  #
  # @param messages [Hash] the current hash of validation messages.
  # @param keys [String, Array] the existing message keys to be moved to the base of the form.
  # @param highlights [Hash] the fields in the form to be highlighted. Specifiy as a Hash of key: [fields].
  # @return [Hash] the expanded validation messages.
  def move_validation_errors_to_base(messages, keys, highlights: {}) # rubocop:disable Metrics/AbcSize
    interim = messages || {}
    Array(keys).each do |key|
      next unless interim.key?(key) # Note: It only needs to move error message to base if it exists in the first place

      if highlights.key?(key)
        interim[:base_with_highlights] ||= { messages: [], highlights: [] }
        interim[:base_with_highlights][:messages] +=  Array(interim.delete(key))
        interim[:base_with_highlights][:highlights] = Array(interim[:base_with_highlights][:highlights]) + Array(highlights.delete(key))
      else
        interim[:base] ||= []
        # interim[:base] += Array(interim.delete(key))
        interim[:base] += Array(interim.delete(key)).map { |msg| "#{key.to_s.gsub('_', ' ').capitalize} #{msg}" }
      end
    end
    interim
  end

  # Selection from a multiselect grid.
  # Returns an array of values.
  def multiselect_grid_choices(params, treat_as_integers: true)
    list = if params.key?(:selection)
             params[:selection][:list]
           else
             params[:list]
           end
    if treat_as_integers
      list.split(',').map(&:to_i)
    else
      list.split(',')
    end
  end

  # Make option tags for a select tag.
  #
  # @param items [Array] the option items.
  # @return [String] the HTML +option+ tags.
  def make_options(items)
    items.map do |item|
      if item.is_a?(Array)
        "<option value=\"#{item.last}\">#{item.first}</option>"
      else
        "<option value=\"#{item}\">#{item}</option>"
      end
    end.join("\n")
  end

  # Is this a fetch request?
  #
  # @param route [Roda.route] the route.
  # @return [Boolean] true if this is a FETCH request.
  def fetch?(route)
    route.has_header?('HTTP_X_CUSTOM_REQUEST_TYPE')
  end

  # The logged-in user.
  # If the logged-in user is acting as another user, that user will be returned.
  # If not logged-in, returns nil.
  #
  # @return [User, nil] the logged-in user or the acts-as user.
  def current_user
    return nil unless session[:user_id]

    @current_user ||= DevelopmentApp::UserRepo.new.find(:users, DevelopmentApp::User, session[:act_as_user_id] || session[:user_id])
  end

  def does_user_have_rmd_menu_items?
    return false unless current_user

    SecurityApp::MenuRepo.new.does_user_have_rmd_menu_items?(current_user, self.class.name)
  end

  def user_homepage
    return nil unless current_user&.profile
    return nil if current_user.profile['homepage_id'].nil_or_empty?

    SecurityApp::MenuRepo.new.find_program_function(current_user.profile['homepage_id']).url
  end

  # A fixed user to be used for logging activities not initiated by users.
  # e.g. when set in a route that does not require login.
  #
  # @return [User] the system user.
  def system_user
    DevelopmentApp::User.new(id: nil, login_name: 'system', user_name: 'System', password_hash: nil, email: nil, active: true)
  end

  # The user acting as another user.
  #
  # @return [User, nil] the logged-in user acting as another user.
  def actor_user
    return nil unless session[:act_as_user_id]

    @actor_user ||= DevelopmentApp::UserRepo.new.find(:users, DevelopmentApp::User, session[:user_id])
  end

  # Act as if logged-in as another user.
  #
  # @param id [integer] the id of the user to act-as.
  # @return [void]
  def act_as_user(id)
    session[:act_as_user_id] = id
  end

  # Clear the act-as user.
  #
  # @return [void]
  def revert_to_logged_in_user
    session[:act_as_user_id] = nil
    @current_user = nil
  end

  # Get the id of a functional area and store as instance valiable
  #
  # @param functional_area_name [string] the functional area
  # @return [integer]
  def store_current_functional_area(functional_area_name)
    @functional_area_id = SecurityApp::MenuRepo.new.functional_area_id_for_name(functional_area_name)
  end

  # Return the functional_area_id instance variable
  #
  # @return [integer] functional area id.
  def current_functional_area
    @functional_area_id
  end

  # Is the current user authorised for a particular menu access permission?
  # Always returns false is there is no logged-on user.
  #
  # @param programs [string, array] the program name(s)
  # @param sought_permission [string] the security permission
  # @param functional_area_id [nil,integer] the functional area. Optional, typically set by the route
  # @return [boolean] true if authorised
  def authorised?(programs, sought_permission, functional_area_id = nil)
    return false unless current_user

    functional_area_id ||= current_functional_area
    prog_repo = SecurityApp::MenuRepo.new
    prog_repo.authorise?(current_user, Array(programs), sought_permission, functional_area_id)
  end

  # Using functional area name, is the current user authorised for a particular menu access permission?
  # Always returns false is there is no logged-on user.
  #
  # @param functional_area_name [string] the functional area.
  # @param programs [string, array] the program name(s)
  # @param sought_permission [string] the security permission
  # @return [boolean] true if authorised
  def auth_blocked?(functional_area_name, programs, sought_permission)
    store_current_functional_area(functional_area_name)
    !authorised?(programs, sought_permission)
  end

  # Raise an authorization exception if the current user is not
  # authorised for a particular menu access permission.
  #
  # @param programs [string, array] the program name(s)
  # @param sought_permission [string] the security permission
  # @param functional_area_id [nil,integer] the functional area. Optional, typically set by the route
  # @return [void]
  def check_auth!(programs, sought_permission, functional_area_id = nil)
    return if authorised?(programs, sought_permission, functional_area_id)

    puts <<~STR unless AppConst.test?
      ----
        Authorization error for user "#{current_user.login_name}".
        User does not have permission "#{sought_permission}" for program(s) "#{Array(programs).join(', ')}".
        The functional area id is "#{functional_area_id || current_functional_area}".
      ----
    STR
    raise Crossbeams::AuthorizationError
  end

  # Raises an authorization exception if not running in development mode.
  #
  # @return [void]
  def check_dev_only!
    raise Crossbeams::AuthorizationError unless AppConst.development?
  end

  # Called by RodAuth after successful login to check if user
  # has access to the program that the path belongs to.
  def can_login_to_path?(path, user_id)
    prog_repo = SecurityApp::MenuRepo.new
    prog_repo.can_login_to_path?(user_id, path)
  end

  # URL for use in a back button link (using the request's referer).
  # If the referer is the result of a search query, the back button goes to the
  # parameters page.
  #
  # @return [string] - the URL
  def back_button_url
    url = request.referer
    return '/' if url.nil?

    url = url.sub(%r{/run$}, '?back=y') if url.include?('/search/') && url.end_with?('/run')
    url
  end

  def set_last_grid_url(url, route = nil)
    session[:last_grid_url] = url unless route && fetch?(route)
  end

  def redirect_to_last_grid(route)
    if fetch?(route)
      redirect_via_json(session[:last_grid_url])
    else
      route.redirect session[:last_grid_url]
    end
  end

  # Store the referer URL so it can be redirected to using redirect_to_stored_referer later.
  # The URL is stored in LocalStorage.
  #
  # @param key [symbol] a key to identify the stored url.
  # @return [void]
  def store_last_referer_url(key)
    store_locally("last_referer_url_#{key}".to_sym, request.referer)
  end

  # Redirect to the last_referer_url in local storage.
  #
  # @param route [Roda.route] the current route.
  # @param key [symbol] a key to identify the stored url.
  # @return [void]
  def redirect_to_stored_referer(route, key)
    url = retrieve_from_local_store("last_referer_url_#{key}".to_sym)
    route.redirect url
  end

  # Redirect via JSON to the last_referer_url in local storage.
  #
  # @param route [Roda.route] the current route.
  # @param key [symbol] a key to identify the stored url.
  # @return [void]
  def redirect_via_json_to_stored_referer(key)
    url = retrieve_from_local_store("last_referer_url_#{key}".to_sym)
    redirect_via_json(url)
  end

  def redirect_via_json_to_last_grid
    redirect_via_json(session[:last_grid_url])
  end

  def redirect_via_json(url)
    { redirect: url }.to_json
  end

  def reload_previous_dialog_via_json(url, notice: nil)
    res = { reloadPreviousDialog: url }
    res[:flash] = { notice: notice } if notice
    res.to_json
  end

  def load_via_json(url, notice: nil)
    res = { loadNewUrl: url }
    res[:flash] = { notice: notice } if notice
    res.to_json
  end

  # Return a JSON response to change the window location to a new URL.
  #
  # Optionally provide a log_url to log to console.
  # - this is useful if urlA builds a report and then the window location
  # is changed to display the output file. The console can be checked to see
  # which url did the work when debugging.
  #
  # @param new_location [string] - the new url.
  # @param log_url [string] - the url to log in the console.
  # @param download [boolean] - is this report to be downloaded? (set true for XLS, CSV, RTF). Defaults to false.
  # @return [JSON] a JSON response.
  def change_window_location_via_json(new_location, log_url = nil, download: false)
    res = { location: new_location }
    res[:log_url] = log_url unless log_url.nil?
    res[:download] = true if download
    res.to_json
  end

  # Update columns in a particular row (or rows) in the grid.
  # If more than one id is provided, all matching rows will
  # receive the same changed values.
  #
  # @param ids [Integer/Array] the id or ids of the row(s) to update.
  # @param changes [Hash] the changed columns and their values.
  # @param notice [String/Nil] the flash message to show.
  # @return [JSON] the changes to be applied.
  def update_grid_row(ids, changes:, notice: nil, grid_id: nil)
    res = action_update_grid_row(ids, changes: changes, grid_id: grid_id)
    res[:flash] = { notice: notice } if notice
    res.to_json
  end

  # Add a row to a grid. created_at and updated_at values are provided automatically.
  #
  # @param attrs [Hash] the columns and their values.
  # @param notice [String/Nil] the flash message to show.
  # @return [JSON] the changes to be applied.
  def add_grid_row(attrs:, grid_id: nil, notice: nil)
    res = action_add_grid_row(attrs: attrs, grid_id: grid_id)
    res[:flash] = { notice: notice } if notice
    res.to_json
  end

  # Create a list of attributes for passing to the +update_grid_row+ and +add_grid_row+ methods.
  #
  # @param instance [Hash/Dry-type] the instance.
  # @param row_keys [Array] the keys to attributes of the instance.
  # @param extras [Hash] extra key/value combinations to add/replace attributes.
  # @return [Hash] the chosen attributes.
  def select_attributes(instance, row_keys, extras = {})
    mods = if instance.to_h[:extended_columns]
             extras.merge(instance.to_h[:extended_columns].transform_keys(&:to_sym))
           else
             extras
           end
    Hash[row_keys.map { |k| [k, instance[k]] }].merge(mods)
  end

  def delete_grid_row(id, grid_id: nil, notice: nil)
    res = action_delete_grid_row(id, grid_id: grid_id)
    res[:flash] = { notice: notice } if notice
    res.to_json
  end

  # Change the contents of a currently-displayed dialog.
  #
  # @param content [string] the HTML content to be rendered.
  # @param notice [nil, string] an optional notice to flash in the page.
  # @param error [nil, string] an optional error message to flash in the page.
  # @return [JSON] the commands for the front end to apply.
  def update_dialog_content(content:, notice: nil, error: nil)
    res = { replaceDialog: { content: content } }
    res[:flash] = { notice: notice } if notice
    res[:flash] = { error: error } if error
    res.to_json
  end

  # Display an error message in a dialog.
  #
  # @param content [string] the error message.
  # @param notice [nil, string] an optional notice to flash in the page.
  # @param error [nil, string] an optional error message to flash in the page.
  # @param hide_caption [boolean] hide the "Error" caption. Default is false.
  # @return [JSON] the commands for the front end to apply.
  def dialog_error(content, notice: nil, error: nil, hide_caption: false)
    if hide_caption
      update_dialog_content(content: wrap_content_in_style(content, :error, caption: ''), notice: notice, error: error)
    else
      update_dialog_content(content: wrap_content_in_style(content, :error), notice: notice, error: error)
    end
  end

  # Display a warning message in a dialog.
  #
  # @param content [string] the warning message.
  # @param notice [nil, string] an optional notice to flash in the page.
  # @param error [nil, string] an optional error message to flash in the page.
  # @param hide_caption [boolean] hide the "Warning" caption. Default is false.
  # @return [JSON] the commands for the front end to apply.
  def dialog_warning(content, notice: nil, error: nil, hide_caption: false)
    if hide_caption
      update_dialog_content(content: wrap_content_in_style(content, :warning, caption: ''), notice: notice, error: error)
    else
      update_dialog_content(content: wrap_content_in_style(content, :warning), notice: notice, error: error)
    end
  end

  def handle_ui_change(rule, mode, params, options = {})
    ui_rule = UiRules::Compiler.new(rule, mode, options)
    ui_rule.respond_to_behaviour(params)
  end

  # Undo an inline-edit from a grid. Optionally display a message.
  #
  # @param message [string] an optional message to display.
  # @param message_type [symbol] the message style : :info, :error, :warning or :notice
  # @return [json] the JSON command to undo the edit.
  def undo_grid_inline_edit(message: nil, message_type: :warning)
    res = { undoEdit: true }
    res[:flash] = { message_type => message } unless message.nil?
    res.to_json
  end

  # Redirect to "Not found" page or return 404 status.
  #
  # @param route [Roda.route] the route.
  # @return [void]
  def handle_not_found(route)
    if fetch?(route)
      response.status = 404
      response.write({}.to_json)
      route.halt
    else
      route.redirect '/not_found'
    end
  end

  # Store a value in local storage for fetching later.
  # Used for storing something per user in one action and retrieving in another action.
  #
  # @param key [Symbol] the key to be used for later retrieval.
  # @param value [Object] the value to stash (use simple Objects)
  # @param ip_address [string] the ip address of the client (defaults to the ip address from the request)
  # @return [void]
  def store_locally(key, value, ip_address = nil)
    raise ArgumentError, 'store_locally: key must be a Symbol' unless key.is_a? Symbol

    store = LocalStore.new(current_user.id, ip_address || request.ip)
    store.write(key, value)
  end

  # Return a stored value for the current user from local storage (and remove it - read once).
  #
  # @param key [Symbol] the key that was used when stored.
  # @param ip_address [string] the ip address of the client (defaults to the ip address from the request)
  # @return [Object] the retrieved value.
  def retrieve_from_local_store(key, ip_address = nil)
    raise ArgumentError, 'store_locally: key must be a Symbol' unless key.is_a? Symbol

    store = LocalStore.new(current_user.id, ip_address || request.ip)
    store.read_once(key)
  end

  # Stash a page in local storage for fetching later.
  # Only one page per user can be stashed at a time.
  # Used for storing a page after it has failed validation.
  #
  # @param value [String] the page HTML.
  # @return [void]
  def stash_page(value)
    store_locally(:stashed_page, value)
  end

  # Return the stashed page from local storage.
  # Used to display a page with invalid state instead of the usual new/edit etc. page after a redirect.
  #
  # @return [String] the HTML page.
  def stashed_page
    retrieve_from_local_store(:stashed_page)
  end

  # Create a URL for a report so that it can be called
  # from a spreadsheet app's webquery.
  #
  # @param report_id [Integer] the id of the prepared report.
  # @return [String] the URL.
  def webquery_url_for(report_id)
    port = request.port == '80' || request.port.nil? ? '' : ":#{request.port}"
    "http://#{request.host}#{port}/webquery/#{report_id}"
  end

  # Take a Crossbeams::Response and present it as an error message.
  # For a validation error, the errors are listed in the returned message.
  #
  # @param res [Crossbeams::Response] the response object.
  # @return [String] the formatted message.
  def unwrap_failed_response(res) # rubocop:disable Metrics/AbcSize
    if res.errors.empty?
      CGI.escapeHTML(res.message)
    elsif res.message == 'Validation error'
      res.errors.map { |fld, errs| "#{fld == :base ? '' : "#{fld} "}#{errs.map { |e| CGI.escapeHTML(e.to_s) }.join(', ')}" }.join('; ')
    else
      "#{CGI.escapeHTML(res.message)} - #{res.errors.map { |fld, errs| "#{fld} #{errs.map { |e| CGI.escapeHTML(e.to_s) }.join(', ')}" }.join('; ')}"
    end
  end

  AVATAR_COLOURS = %w[#f2b736 #c5523f #499255 #1875e5 #E7040F #FF4136 #5E2CA5 #D5008F #001B44 #137752 #19A974].freeze

  # Generate an SVG based on the initials of the name and surname passed in.
  #
  # @param first_name [string] the first letter (or a space) is used as the initial.
  # @param surname [string] the first letter (or a space) is used as the initial.
  # @param size [symbol] image size, can be :small, :medium or :large. Default is :small.
  # @return [string] the SVG code.
  def initials_avatar(first_name, surname, size: :medium)
    init1 = (first_name || ' ')[0].upcase
    init2 = (surname || ' ')[0].upcase
    bg = AVATAR_COLOURS[(init1.ord + init2.ord) % AVATAR_COLOURS.length]
    opts = { small: 50, medium: 100, large: 150 }
    <<~SVG
      <?xml version="1.0" encoding="UTF-8"?>
      <svg version="1.1" xmlns="http://www.w3.org/2000/svg" width="#{opts[size]}" height="#{opts[size]}" viewBox="0 0 50 50">
        <rect width="100%" height="100%" fill="#{bg}"/>
        <text fill="#fff" font-family="Helvetica,Arial,sans-serif" font-size="26" font-weight="500" x="50%" y="55%" dominant-baseline="middle" text-anchor="middle">
          #{init1}#{init2}
        </text>
      </svg>
    SVG
  end
end
