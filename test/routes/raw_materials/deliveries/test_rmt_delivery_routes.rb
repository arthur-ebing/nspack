# frozen_string_literal: true

require File.join(File.expand_path('./../../../', __dir__), 'test_helper_for_routes')

class TestRmtDeliveryRoutes < RouteTester

  INTERACTOR = RawMaterialsApp::RmtDeliveryInteractor

  def test_edit
    authorise_pass! permission_check: RawMaterialsApp::TaskPermissionCheck::RmtDelivery
    ensure_exists!(INTERACTOR)
    RawMaterials::Deliveries::RmtDelivery::Edit.stub(:call, bland_page) do
      get 'raw_materials/deliveries/rmt_deliveries/1/edit', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_edit_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'raw_materials/deliveries/rmt_deliveries/1/edit', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  def test_show
    authorise_pass!
    ensure_exists!(INTERACTOR)
    RawMaterials::Deliveries::RmtDelivery::Show.stub(:call, bland_page) do
      get 'raw_materials/deliveries/rmt_deliveries/1', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_show_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'raw_materials/deliveries/rmt_deliveries/1', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  # def test_update
  #   authorise_pass!
  #   ensure_exists!(INTERACTOR)
  #   row_vals = Hash.new(1)
  #   INTERACTOR.any_instance.stubs(:update_rmt_delivery).returns(ok_response(instance: row_vals))
  #   patch_as_fetch 'raw_materials/deliveries/rmt_deliveries/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
  #   expect_json_update_grid
  # end

  def test_update_fail
    authorise_pass!
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:update_rmt_delivery).returns(bad_response)
    RawMaterials::Deliveries::RmtDelivery::Edit.stub(:call, bland_page) do
      patch_as_fetch 'raw_materials/deliveries/rmt_deliveries/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    end
    expect_json_replace_dialog(has_error: true)
  end

  def test_delete
    authorise_pass! permission_check: RawMaterialsApp::TaskPermissionCheck::RmtDelivery
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:delete_rmt_delivery).returns(ok_response)
    delete_as_fetch 'raw_materials/deliveries/rmt_deliveries/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_json_delete_from_grid
  end

  def test_delete_fail
    authorise_pass! permission_check: RawMaterialsApp::TaskPermissionCheck::RmtDelivery
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:delete_rmt_delivery).returns(bad_response)
    delete_as_fetch 'raw_materials/deliveries/rmt_deliveries/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_json_error
  end

  def test_new
    authorise_pass!
    ensure_exists!(INTERACTOR)
    RawMaterials::Deliveries::RmtDelivery::New.stub(:call, bland_page) do
      get  'raw_materials/deliveries/rmt_deliveries/new', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_new_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'raw_materials/deliveries/rmt_deliveries/new', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  def test_create_remotely
    authorise_pass!
    ensure_exists!(INTERACTOR)
    row_vals = Hash.new(1)
    row_vals[:id] = 1
    INTERACTOR.any_instance.stubs(:create_rmt_delivery).returns(ok_response(instance: row_vals))
    RawMaterialsApp::RmtDeliveryRepo.any_instance.stubs(:default_farm_puc).returns({ farm_id: 123, puc_id: nil })
    post_as_fetch 'raw_materials/deliveries/rmt_deliveries', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_ok_redirect url: "/raw_materials/deliveries/rmt_deliveries/1/edit", follow_redirect: false
  end

  def test_create_remotely_fail
    authorise_pass!
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:create_rmt_delivery).returns(bad_response)
    RawMaterials::Deliveries::RmtDelivery::New.stub(:call, bland_page) do
      post_as_fetch 'raw_materials/deliveries/rmt_deliveries', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    end
    expect_json_replace_dialog
  end
end
