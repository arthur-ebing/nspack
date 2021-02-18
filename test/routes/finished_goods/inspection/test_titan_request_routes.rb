# frozen_string_literal: true

require File.join(File.expand_path('./../../../', __dir__), 'test_helper_for_routes')

class TestTitanRequestRoutes < RouteTester

  INTERACTOR = FinishedGoodsApp::TitanRequestInteractor

  def test_show
    authorise_pass!
    ensure_exists!(INTERACTOR)
    FinishedGoods::Inspection::TitanRequest::Show.stub(:call, bland_page) do
      get 'finished_goods/inspection/titan_requests/1', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_show_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'finished_goods/inspection/titan_requests/1', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  def test_delete
    authorise_pass! permission_check: FinishedGoodsApp::TaskPermissionCheck::TitanRequest
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:delete_titan_request).returns(ok_response)
    delete_as_fetch 'finished_goods/inspection/titan_requests/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_json_delete_from_grid
  end

  def test_delete_fail
    authorise_pass! permission_check: FinishedGoodsApp::TaskPermissionCheck::TitanRequest
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:delete_titan_request).returns(bad_response)
    delete_as_fetch 'finished_goods/inspection/titan_requests/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_json_error
  end
end
