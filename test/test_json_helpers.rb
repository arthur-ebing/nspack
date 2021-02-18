require File.join(File.expand_path('./../', __FILE__), 'test_helper')

class TestJsonHelpers < Minitest::Test
  include JsonHelpers

  def test_build_json_action
    res = build_json_action(OpenStruct.new(type: :replace_input_value, dom_id: 'html_dom_tag_id', value: 'TEST'))
    expect = { replace_input_value: { id: 'html_dom_tag_id', value: 'TEST' } }
    assert_equal expect, res

    res = build_json_action(OpenStruct.new(type: :change_select_value, dom_id: 'html_dom_tag_id', value: 'TEST'))
    expect = { change_select_value: { id: 'html_dom_tag_id', value: 'TEST' } }
    assert_equal expect, res

    res = build_json_action(OpenStruct.new(type: :replace_inner_html, dom_id: 'html_dom_tag_id', value: 'TEST'))
    expect = { replace_inner_html: { id: 'html_dom_tag_id', value: 'TEST' } }
    assert_equal expect, res

    res = build_json_action(OpenStruct.new(type: :replace_select_options, dom_id: 'html_dom_tag_id', options_array: ['1', '2']))
    expect = { replace_options: { id: 'html_dom_tag_id', options: ['1', '2'] } }
    assert_equal expect, res

    res = build_json_action(OpenStruct.new(type: :replace_multi_options, dom_id: 'html_dom_tag_id', options_array: ['1', '2']))
    expect = { replace_multi_options: { id: 'html_dom_tag_id', options: ['1', '2'] } }
    assert_equal expect, res

    res = build_json_action(OpenStruct.new(type: :replace_list_items, dom_id: 'html_dom_tag_id', items: ['1', '2']))
    expect = { replace_list_items: { id: 'html_dom_tag_id', items: ['1', '2'] } }
    assert_equal expect, res

    res = build_json_action(OpenStruct.new(type: :hide_element, dom_id: 'html_dom_tag_id'))
    expect = { hide_element: { id: 'html_dom_tag_id', reclaim_space: true } }
    assert_equal expect, res

    res = build_json_action(OpenStruct.new(type: :hide_element, dom_id: 'html_dom_tag_id', reclaim_space: false))
    expect = { hide_element: { id: 'html_dom_tag_id', reclaim_space: false } }
    assert_equal expect, res

    res = build_json_action(OpenStruct.new(type: :show_element, dom_id: 'html_dom_tag_id'))
    expect = { show_element: { id: 'html_dom_tag_id', reclaim_space: true } }
    assert_equal expect, res

    res = build_json_action(OpenStruct.new(type: :show_element, dom_id: 'html_dom_tag_id', reclaim_space: false))
    expect = { show_element: { id: 'html_dom_tag_id', reclaim_space: false } }
    assert_equal expect, res

    res = build_json_action(OpenStruct.new(type: :clear_form_validation, dom_id: 'html_dom_tag_id'))
    expect = { clear_form_validation: { form_id: 'html_dom_tag_id' } }
    assert_equal expect, res

    res = build_json_action(OpenStruct.new(type: :launch_dialog, content: 'html_for_dlg'))
    expect = { launch_dialog: { content: 'html_for_dlg', title: nil } }
    assert_equal expect, res

    res = build_json_action(OpenStruct.new(type: :launch_dialog, content: 'html_for_dlg', title: 'text'))
    expect = { launch_dialog: { content: 'html_for_dlg', title: 'text' } }
    assert_equal expect, res
  end

  def test_json_actions
    res = json_actions([OpenStruct.new(type: :clear_form_validation, dom_id: 'html_dom_tag_id')], 'TEST', keep_dialog_open: true)
    expect = { actions: [{ clear_form_validation: { form_id: 'html_dom_tag_id' } }], flash: { notice: 'TEST' }, keep_dialog_open: true }.to_json
    assert_equal expect, res

    res = json_actions([OpenStruct.new(type: :clear_form_validation, dom_id: 'html_dom_tag_id')])
    expect = { actions: [{ clear_form_validation: { form_id: 'html_dom_tag_id' } }] }.to_json
    assert_equal expect, res

    res = json_actions([
      OpenStruct.new(type: :replace_input_value, dom_id: 'html_dom_tag_id', value: 'TEST'),
      OpenStruct.new(type: :clear_form_validation, dom_id: 'html_dom_tag_id'),
      OpenStruct.new(type: :hide_element, dom_id: 'html_dom_tag_id')
    ])
    expect = { actions: [{ replace_input_value: { id: 'html_dom_tag_id', value: 'TEST' } },
                         { clear_form_validation: { form_id: 'html_dom_tag_id' } },
                         { hide_element: { id: 'html_dom_tag_id', reclaim_space: true } }] }.to_json
    assert_equal expect, res
  end
end
