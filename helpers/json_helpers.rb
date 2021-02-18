module JsonHelpers # rubocop:disable Metrics/ModuleLength
  def action_add_grid_row(attrs:, grid_id: nil)
    { addRowToGrid: { changes: attrs.merge(created_at: Time.now.to_s, updated_at: Time.now.to_s), gridId: grid_id } }
  end

  def action_update_grid_row(ids, changes:, grid_id: nil)
    { updateGridInPlace: Array(ids).map { |i| { id: make_id_correct_type(i), changes: changes, gridId: grid_id } } }
  end

  def action_delete_grid_row(id, grid_id: nil)
    { removeGridRowInPlace: { id: make_id_correct_type(id), gridId: grid_id } }
  end

  def json_replace_select_options(dom_id, options_array, message: nil, keep_dialog_open: false)
    json_actions(OpenStruct.new(type: :replace_select_options, dom_id: dom_id, options_array: options_array), message, keep_dialog_open: keep_dialog_open)
  end

  def json_replace_multi_options(dom_id, options_array, message: nil, keep_dialog_open: false)
    json_actions(OpenStruct.new(type: :replace_multi_options, dom_id: dom_id, options_array: options_array), message, keep_dialog_open: keep_dialog_open)
  end

  def json_replace_input_value(dom_id, value, message: nil, keep_dialog_open: false)
    json_actions(OpenStruct.new(type: :replace_input_value, dom_id: dom_id, value: value), message, keep_dialog_open: keep_dialog_open)
  end

  def json_change_select_value(dom_id, value, message: nil, keep_dialog_open: false)
    json_actions(OpenStruct.new(type: :change_select_value, dom_id: dom_id, value: value), message, keep_dialog_open: keep_dialog_open)
  end

  def json_replace_url(dom_id, value, message: nil, keep_dialog_open: false)
    json_actions(OpenStruct.new(type: :replace_url, dom_id: dom_id, value: value), message, keep_dialog_open: keep_dialog_open)
  end

  def json_replace_inner_html(dom_id, value, message: nil, keep_dialog_open: false)
    json_actions(OpenStruct.new(type: :replace_inner_html, dom_id: dom_id, value: value), message, keep_dialog_open: keep_dialog_open)
  end

  def json_replace_list_items(dom_id, items, message: nil, keep_dialog_open: false)
    json_actions(OpenStruct.new(type: :replace_list_items, dom_id: dom_id, items: Array(items)), message, keep_dialog_open: keep_dialog_open)
  end

  def json_set_readonly(dom_id, readonly, message: nil, keep_dialog_open: false)
    json_actions(OpenStruct.new(type: :set_readonly, dom_id: dom_id, readonly: readonly), message, keep_dialog_open: keep_dialog_open)
  end

  def json_hide_element(dom_id, reclaim_space: true, message: nil, keep_dialog_open: false)
    json_actions(OpenStruct.new(type: :hide_element, dom_id: dom_id, reclaim_space: reclaim_space), message, keep_dialog_open: keep_dialog_open)
  end

  def json_show_element(dom_id, reclaim_space: true, message: nil, keep_dialog_open: false)
    json_actions(OpenStruct.new(type: :show_element, dom_id: dom_id, reclaim_space: reclaim_space), message, keep_dialog_open: keep_dialog_open)
  end

  def json_clear_form_validation(dom_id, message: nil, keep_dialog_open: false)
    json_actions(OpenStruct.new(type: :clear_form_validation, dom_id: dom_id), message, keep_dialog_open: keep_dialog_open)
  end

  def json_set_required(dom_id, required, message: nil, keep_dialog_open: false)
    json_actions(OpenStruct.new(type: :set_required, dom_id: dom_id, required: required), message, keep_dialog_open: keep_dialog_open)
  end

  def json_set_checked(dom_id, checked, message: nil, keep_dialog_open: false)
    json_actions(OpenStruct.new(type: :set_checked, dom_id: dom_id, checked: checked), message, keep_dialog_open: keep_dialog_open)
  end

  def json_launch_dialog(content, title: nil, message: nil, keep_dialog_open: true)
    json_actions(OpenStruct.new(type: :launch_dialog, content: content, title: title), message, keep_dialog_open: keep_dialog_open)
  end

  def build_json_action(action) # rubocop:disable Metrics/AbcSize
    # rubocop:disable Layout/HashAlignment
    {
      replace_input_value:    ->(act) { action_replace_input_value(act) },
      change_select_value:    ->(act) { action_change_select_value(act) },
      replace_url:            ->(act) { action_replace_url(act) },
      replace_inner_html:     ->(act) { action_replace_inner_html(act) },
      replace_select_options: ->(act) { action_replace_select_options(act) },
      replace_multi_options:  ->(act) { action_replace_multi_options(act) },
      replace_list_items:     ->(act) { action_replace_list_items(act) },
      set_readonly:           ->(act) { action_set_readonly(act) },
      hide_element:           ->(act) { action_hide_element(act) },
      show_element:           ->(act) { action_show_element(act) },
      add_grid_row:           ->(act) { action_add_grid_row(attrs: act.attrs, grid_id: act.grid_id) },
      update_grid_row:        ->(act) { action_update_grid_row(act.ids, changes: act.changes, grid_id: act.grid_id) },
      delete_grid_row:        ->(act) { action_delete_grid_row(act.id, grid_id: act.grid_id) },
      clear_form_validation:  ->(act) { action_clear_form_validation(act) },
      set_required:           ->(act) { action_set_required(act) },
      set_checked:            ->(act) { action_set_checked(act) },
      # redirect:               ->(act) { action_redirect(act) }       // url
      replace_dialog:         ->(act) { action_replace_dialog(act) },
      launch_dialog:          ->(act) { action_launch_dialog(act) }
    }[action.type].call(action)
    # rubocop:enable Layout/HashAlignment
  end

  def action_replace_select_options(action)
    { replace_options: { id: action.dom_id, options: action.options_array } }
  end

  def action_replace_multi_options(action)
    { replace_multi_options: { id: action.dom_id, options: action.options_array } }
  end

  def action_replace_input_value(action)
    { replace_input_value: { id: action.dom_id, value: action.value } }
  end

  def action_change_select_value(action)
    { change_select_value: { id: action.dom_id, value: action.value } }
  end

  def action_replace_url(action)
    { replace_url: { id: action.dom_id, value: action.value } }
  end

  def action_replace_inner_html(action)
    { replace_inner_html: { id: action.dom_id, value: action.value } }
  end

  def action_replace_dialog(action)
    { replace_dialog: { content: action.content, title: action.title } }
  end

  def action_launch_dialog(action)
    { launch_dialog: { content: action.content, title: action.title } }
  end

  def action_replace_list_items(action)
    { replace_list_items: { id: action.dom_id, items: action.items } }
  end

  def action_set_readonly(action)
    { set_readonly: { id: action.dom_id, readonly: action.readonly } }
  end

  def action_hide_element(action)
    { hide_element: { id: action.dom_id, reclaim_space: action.reclaim_space.nil? ? true : action.reclaim_space } }
  end

  def action_show_element(action)
    { show_element: { id: action.dom_id, reclaim_space: action.reclaim_space.nil? ? true : action.reclaim_space } }
  end

  def action_clear_form_validation(action)
    { clear_form_validation: { form_id: action.dom_id } }
  end

  def action_set_required(action)
    { set_required: { id: action.dom_id, required: action.required } }
  end

  def action_set_checked(action)
    { set_checked: { id: action.dom_id, checked: action.checked } }
  end

  # def action_redirect(action)
  #   { redirect: { url: action.url } }
  # end

  def json_actions(actions, message = nil, keep_dialog_open: false)
    res = { actions: Array(actions).map { |a| build_json_action(a) } }
    res[:flash] = { notice: message } unless message.nil?
    res[:keep_dialog_open] = true if keep_dialog_open
    res.to_json
  end

  def make_id_correct_type(id_in)
    if id_in.is_a?(String)
      id_in.scan(/\D/).empty? ? id_in.to_i : id_in
    else
      id_in
    end
  end
end
