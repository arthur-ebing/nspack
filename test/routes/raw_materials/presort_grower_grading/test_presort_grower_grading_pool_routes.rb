# frozen_string_literal: true

require File.join(File.expand_path('./../../../', __dir__), 'test_helper_for_routes')

class TestPresortGrowerGradingPoolRoutes < RouteTester

  INTERACTOR = RawMaterialsApp::PresortGrowerGradingPoolInteractor

  def test_edit
    authorise_pass! permission_check: RawMaterialsApp::TaskPermissionCheck::PresortGrowerGradingPool
    ensure_exists!(INTERACTOR)
    RawMaterials::PresortGrowerGrading::PresortGrowerGradingPool::Edit.stub(:call, bland_page) do
      get 'raw_materials/presort_grower_grading/presort_grower_grading_pools/1/edit', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_edit_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'raw_materials/presort_grower_grading/presort_grower_grading_pools/1/edit', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  def test_show
    authorise_pass!
    ensure_exists!(INTERACTOR)
    RawMaterials::PresortGrowerGrading::PresortGrowerGradingPool::Show.stub(:call, bland_page) do
      get 'raw_materials/presort_grower_grading/presort_grower_grading_pools/1', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_show_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'raw_materials/presort_grower_grading/presort_grower_grading_pools/1', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  def test_update
    authorise_pass!
    ensure_exists!(INTERACTOR)
    row_vals = Hash.new(1)
    INTERACTOR.any_instance.stubs(:update_presort_grower_grading_pool).returns(ok_response(instance: row_vals))
    patch_as_fetch 'raw_materials/presort_grower_grading/presort_grower_grading_pools/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_json_update_grid
  end

  def test_update_fail
    authorise_pass!
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:update_presort_grower_grading_pool).returns(bad_response)
    RawMaterials::PresortGrowerGrading::PresortGrowerGradingPool::Edit.stub(:call, bland_page) do
      patch_as_fetch 'raw_materials/presort_grower_grading/presort_grower_grading_pools/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    end
    expect_json_replace_dialog(has_error: true)
  end

  def test_delete
    authorise_pass! permission_check: RawMaterialsApp::TaskPermissionCheck::PresortGrowerGradingPool
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:delete_presort_grower_grading_pool).returns(ok_response)
    delete_as_fetch 'raw_materials/presort_grower_grading/presort_grower_grading_pools/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_json_delete_from_grid
  end

  def test_delete_fail
    authorise_pass! permission_check: RawMaterialsApp::TaskPermissionCheck::PresortGrowerGradingPool
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:delete_presort_grower_grading_pool).returns(bad_response)
    delete_as_fetch 'raw_materials/presort_grower_grading/presort_grower_grading_pools/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_json_error
  end

  def test_new
    authorise_pass!
    ensure_exists!(INTERACTOR)
    RawMaterials::PresortGrowerGrading::PresortGrowerGradingPool::New.stub(:call, bland_page) do
      get  'raw_materials/presort_grower_grading/presort_grower_grading_pools/new', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_new_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'raw_materials/presort_grower_grading/presort_grower_grading_pools/new', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  def test_create_remotely
    authorise_pass!
    ensure_exists!(INTERACTOR)
    row_vals = Hash.new(1)
    INTERACTOR.any_instance.stubs(:create_presort_grower_grading_pool).returns(ok_response(instance: row_vals))
    post_as_fetch 'raw_materials/presort_grower_grading/presort_grower_grading_pools', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_json_add_to_grid(has_notice: true)
  end

  def test_create_remotely_fail
    authorise_pass!
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:create_presort_grower_grading_pool).returns(bad_response)
    RawMaterials::PresortGrowerGrading::PresortGrowerGradingPool::New.stub(:call, bland_page) do
      post_as_fetch 'raw_materials/presort_grower_grading/presort_grower_grading_pools', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    end
    expect_json_replace_dialog
  end
end
