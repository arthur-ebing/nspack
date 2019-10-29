require File.join(File.expand_path('./../', __FILE__), 'test_helper')

class TestRMDForm < Minitest::Test

  def make_form(details = {}, options = {})
    opts = {
      form_name: :rmd_form,
      action: '/post_me'
    }
    form = Crossbeams::RMDForm.new(details, opts.merge(options))
    form.add_csrf_tag('abc')
    form
  end

  def test_numeric_with_decimals
    form = make_form
    form.add_field('test', 'Test', data_type: 'number', allow_decimals: true)
    assert_match(/type="number" step="any"/, form.render)

    form = make_form
    form.add_field('test', 'Test', data_type: 'number')
    assert_match(/type="number"/, form.render)
    refute_match(/type="number" step="any"/, form.render)
  end

  def test_no_submit
    form = make_form
    form.add_field('test', 'Test', data_type: 'text')
    assert_match(/type="submit"/, form.render)

    form = make_form({}, action: nil, no_submit: true)
    form.add_field('test', 'Test', data_type: 'text')
    refute_match(/type="submit"/, form.render)
  end

  def test_submit_dom_id
    form = make_form
    refute_match(/id="the-submit-button"/, form.render)

    form = make_form({}, action: nil, button_id: 'the-submit-button')
    assert_match(/id="the-submit-button"/, form.render)
  end

  def test_hide_submit
    form = make_form
    assert_match(/data-rmd-btn="Y">/, form.render)

    form = make_form({}, action: nil, button_initially_hidden: true)
    assert_match(/data-rmd-btn="Y" hidden>/, form.render)
  end
end
