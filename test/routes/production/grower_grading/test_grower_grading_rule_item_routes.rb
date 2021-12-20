# frozen_string_literal: true

require File.join(File.expand_path('./../../../', __dir__), 'test_helper_for_routes')

class TestGrowerGradingRuleItemRoutes < RouteTester

  INTERACTOR = ProductionApp::GrowerGradingRuleItemInteractor

  def test_edit
    authorise_pass! permission_check: ProductionApp::TaskPermissionCheck::GrowerGradingRuleItem
    ensure_exists!(INTERACTOR)
    Production::GrowerGrading::GrowerGradingRuleItem::Edit.stub(:call, bland_page) do
      get 'production/grower_grading/grower_grading_rule_items/1/edit', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_edit_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'production/grower_grading/grower_grading_rule_items/1/edit', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  def test_show
    authorise_pass!
    ensure_exists!(INTERACTOR)
    Production::GrowerGrading::GrowerGradingRuleItem::Show.stub(:call, bland_page) do
      get 'production/grower_grading/grower_grading_rule_items/1', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_show_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'production/grower_grading/grower_grading_rule_items/1', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  def test_update
    authorise_pass!
    ensure_exists!(INTERACTOR)
    row_vals = Hash.new(1)
    INTERACTOR.any_instance.stubs(:update_grower_grading_rule_item).returns(ok_response(instance: row_vals))
    patch_as_fetch 'production/grower_grading/grower_grading_rule_items/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_json_update_grid
  end

  def test_update_fail
    authorise_pass!
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:update_grower_grading_rule_item).returns(bad_response)
    Production::GrowerGrading::GrowerGradingRuleItem::Edit.stub(:call, bland_page) do
      patch_as_fetch 'production/grower_grading/grower_grading_rule_items/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    end
    expect_json_replace_dialog(has_error: true)
  end

  def test_delete
    authorise_pass! permission_check: ProductionApp::TaskPermissionCheck::GrowerGradingRuleItem
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:delete_grower_grading_rule_item).returns(ok_response)
    delete_as_fetch 'production/grower_grading/grower_grading_rule_items/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_json_delete_from_grid
  end

  def test_delete_fail
    authorise_pass! permission_check: ProductionApp::TaskPermissionCheck::GrowerGradingRuleItem
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:delete_grower_grading_rule_item).returns(bad_response)
    delete_as_fetch 'production/grower_grading/grower_grading_rule_items/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_json_error
  end

  def test_new
    authorise_pass!
    ensure_exists!(ProductionApp::GrowerGradingRuleInteractor)
    Production::GrowerGrading::GrowerGradingRuleItem::New.stub(:call, bland_page) do
      get  'production/grower_grading/grower_grading_rules/1/grower_grading_rule_items/new', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_new_fail
    authorise_fail!
    ensure_exists!(ProductionApp::GrowerGradingRuleInteractor)
    get 'production/grower_grading/grower_grading_rules/1/grower_grading_rule_items/new', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  def test_create_remotely
    authorise_pass!
    ensure_exists!(ProductionApp::GrowerGradingRuleInteractor)
    row_vals = Hash.new(1)
    INTERACTOR.any_instance.stubs(:create_grower_grading_rule_item).returns(ok_response(instance: row_vals))
    post_as_fetch 'production/grower_grading/grower_grading_rules/1/grower_grading_rule_items', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_json_add_to_grid(has_notice: true)
  end

  def test_create_remotely_fail
    authorise_pass!
    ensure_exists!(ProductionApp::GrowerGradingRuleInteractor)
    INTERACTOR.any_instance.stubs(:create_grower_grading_rule_item).returns(bad_response)
    Production::GrowerGrading::GrowerGradingRuleItem::New.stub(:call, bland_page) do
      post_as_fetch 'production/grower_grading/grower_grading_rules/1/grower_grading_rule_items', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    end
    expect_json_replace_dialog
  end
end
