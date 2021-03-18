# frozen_string_literal: true

require File.join(File.expand_path('./../../../', __dir__), 'test_helper_for_routes')

class TestPackingSpecificationItemRoutes < RouteTester

  INTERACTOR = ProductionApp::PackingSpecificationItemInteractor

  def test_edit
    authorise_pass! permission_check: ProductionApp::TaskPermissionCheck::PackingSpecificationItem
    ensure_exists!(INTERACTOR)
    Production::PackingSpecifications::PackingSpecificationItem::Edit.stub(:call, bland_page) do
      get 'production/packing_specifications/packing_specification_items/1/edit', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_edit_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'production/packing_specifications/packing_specification_items/1/edit', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  def test_show
    authorise_pass!
    ensure_exists!(INTERACTOR)
    Production::PackingSpecifications::PackingSpecificationItem::Show.stub(:call, bland_page) do
      get 'production/packing_specifications/packing_specification_items/1', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_show_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'production/packing_specifications/packing_specification_items/1', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  def test_update
    authorise_pass!
    ensure_exists!(INTERACTOR)
    row_vals = Hash.new(1)
    INTERACTOR.any_instance.stubs(:update_packing_specification_item).returns(ok_response(instance: row_vals))
    patch_as_fetch 'production/packing_specifications/packing_specification_items/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_json_update_grid
  end

  def test_update_fail
    authorise_pass!
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:update_packing_specification_item).returns(bad_response)
    Production::PackingSpecifications::PackingSpecificationItem::Edit.stub(:call, bland_page) do
      patch_as_fetch 'production/packing_specifications/packing_specification_items/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    end
    expect_json_replace_dialog(has_error: true)
  end

  def test_delete
    authorise_pass! permission_check: ProductionApp::TaskPermissionCheck::PackingSpecificationItem
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:delete_packing_specification_item).returns(ok_response)
    delete_as_fetch 'production/packing_specifications/packing_specification_items/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_json_delete_from_grid
  end

  def test_delete_fail
    authorise_pass! permission_check: ProductionApp::TaskPermissionCheck::PackingSpecificationItem
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:delete_packing_specification_item).returns(bad_response)
    delete_as_fetch 'production/packing_specifications/packing_specification_items/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_json_error
  end

  def test_new
    authorise_pass!
    ensure_exists!(INTERACTOR)
    Production::PackingSpecifications::PackingSpecificationItem::New.stub(:call, bland_page) do
      get  'production/packing_specifications/packing_specification_items/new', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_new_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'production/packing_specifications/packing_specification_items/new', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  def test_create_remotely
    authorise_pass!
    ensure_exists!(INTERACTOR)
    row_vals = Hash.new(1)
    INTERACTOR.any_instance.stubs(:create_packing_specification_item).returns(ok_response(instance: row_vals))
    post_as_fetch 'production/packing_specifications/packing_specification_items', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_ok_json_redirect
  end

  def test_create_remotely_fail
    authorise_pass!
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:create_packing_specification_item).returns(bad_response)
    Production::PackingSpecifications::PackingSpecificationItem::New.stub(:call, bland_page) do
      post_as_fetch 'production/packing_specifications/packing_specification_items', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    end
    expect_json_replace_dialog
  end
end
