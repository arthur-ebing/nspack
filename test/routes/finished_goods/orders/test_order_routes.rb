# frozen_string_literal: true

require File.join(File.expand_path('./../../../', __dir__), 'test_helper_for_routes')

class TestOrderRoutes < RouteTester

  INTERACTOR = FinishedGoodsApp::OrderInteractor

  def test_edit
    authorise_pass! permission_check: FinishedGoodsApp::TaskPermissionCheck::Order
    ensure_exists!(INTERACTOR)
    FinishedGoods::Orders::Order::Edit.stub(:call, bland_page) do
      get 'finished_goods/orders/orders/1/edit', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_edit_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'finished_goods/orders/orders/1/edit', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  def test_show
    authorise_pass!
    ensure_exists!(INTERACTOR)
    FinishedGoods::Orders::Order::Show.stub(:call, bland_page) do
      get 'finished_goods/orders/orders/1', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_show_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'finished_goods/orders/orders/1', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  def test_update
    authorise_pass!
    ensure_exists!(INTERACTOR)
    row_vals = Hash.new(1)
    INTERACTOR.any_instance.stubs(:update_order).returns(ok_response(instance: row_vals))
    patch_as_fetch 'finished_goods/orders/orders/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_ok_json_redirect
  end

  def test_update_fail
    authorise_pass!
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:update_order).returns(bad_response)
    FinishedGoods::Orders::Order::Edit.stub(:call, bland_page) do
      patch_as_fetch 'finished_goods/orders/orders/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    end
    expect_json_replace_dialog(has_error: true)
  end

  def test_delete
    authorise_pass! permission_check: FinishedGoodsApp::TaskPermissionCheck::Order
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:delete_order).returns(ok_response)
    patch_as_fetch 'finished_goods/orders/orders/1/delete', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_ok_redirect(url:"/list/orders")
  end

  def test_delete_fail
    authorise_pass! permission_check: FinishedGoodsApp::TaskPermissionCheck::Order
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:delete_order).returns(bad_response)
    patch_as_fetch 'finished_goods/orders/orders/1/delete', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_flash_error
  end

  def test_new
    authorise_pass!
    ensure_exists!(INTERACTOR)
    FinishedGoods::Orders::Order::New.stub(:call, bland_page) do
      get  'finished_goods/orders/orders/new', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_new_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'finished_goods/orders/orders/new', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  def test_create_remotely
    authorise_pass!
    ensure_exists!(INTERACTOR)
    row_vals = Hash.new(1)
    INTERACTOR.any_instance.stubs(:create_order).returns(ok_response(instance: row_vals))
    post_as_fetch 'finished_goods/orders/orders', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_ok_json_redirect
  end

  def test_create_remotely_fail
    authorise_pass!
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:create_order).returns(bad_response)
    FinishedGoods::Orders::Order::New.stub(:call, bland_page) do
      post_as_fetch 'finished_goods/orders/orders', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    end
    expect_json_replace_dialog
  end
end
