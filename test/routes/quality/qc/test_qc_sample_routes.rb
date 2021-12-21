# frozen_string_literal: true

require File.join(File.expand_path('./../../../', __dir__), 'test_helper_for_routes')

class TestQcSampleRoutes < RouteTester

  INTERACTOR = QualityApp::QcSampleInteractor

  def test_edit
    authorise_pass! permission_check: QualityApp::TaskPermissionCheck::QcSample
    ensure_exists!(INTERACTOR)
    Quality::Qc::QcSample::Edit.stub(:call, bland_page) do
      get 'quality/qc/qc_samples/1/edit', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_edit_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'quality/qc/qc_samples/1/edit', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  def test_show
    authorise_pass!
    ensure_exists!(INTERACTOR)
    Quality::Qc::QcSample::Show.stub(:call, bland_page) do
      get 'quality/qc/qc_samples/1', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_show_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'quality/qc/qc_samples/1', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  # def test_update
  #   authorise_pass!
  #   ensure_exists!(INTERACTOR)
  #   row_vals = Hash.new(1)
  #   INTERACTOR.any_instance.stubs(:update_qc_sample).returns(ok_response(instance: row_vals))
  #   patch_as_fetch 'quality/qc/qc_samples/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
  #   expect_json_update_grid
  # end

  def test_update_fail
    authorise_pass!
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:update_qc_sample).returns(bad_response)
    Quality::Qc::QcSample::Edit.stub(:call, bland_page) do
      patch_as_fetch 'quality/qc/qc_samples/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    end
    expect_json_replace_dialog(has_error: true)
  end

  def test_delete
    authorise_pass! permission_check: QualityApp::TaskPermissionCheck::QcSample
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:delete_qc_sample).returns(ok_response)
    delete_as_fetch 'quality/qc/qc_samples/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_json_delete_from_grid
  end

  def test_delete_fail
    authorise_pass! permission_check: QualityApp::TaskPermissionCheck::QcSample
    ensure_exists!(INTERACTOR)
    INTERACTOR.any_instance.stubs(:delete_qc_sample).returns(bad_response)
    delete_as_fetch 'quality/qc/qc_samples/1', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
    expect_json_error
  end

  # def test_new
  #   authorise_pass!
  #   ensure_exists!(INTERACTOR)
  #   Quality::Qc::QcSample::New.stub(:call, bland_page) do
  #     get  'quality/qc/qc_samples/new', {}, 'rack.session' => { user_id: 1 }
  #   end
  #   expect_bland_page
  # end

  # def test_new_fail
  #   authorise_fail!
  #   ensure_exists!(INTERACTOR)
  #   get 'quality/qc/qc_samples/new', {}, 'rack.session' => { user_id: 1 }
  #   expect_permission_error
  # end

  # def test_create_remotely
  #   authorise_pass!
  #   ensure_exists!(INTERACTOR)
  #   row_vals = Hash.new(1)
  #   INTERACTOR.any_instance.stubs(:create_qc_sample).returns(ok_response(instance: row_vals))
  #   post_as_fetch 'quality/qc/qc_samples', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
  #   expect_json_add_to_grid(has_notice: true)
  # end

  # def test_create_remotely_fail
  #   authorise_pass!
  #   ensure_exists!(INTERACTOR)
  #   INTERACTOR.any_instance.stubs(:create_qc_sample).returns(bad_response)
  #   Quality::Qc::QcSample::New.stub(:call, bland_page) do
  #     post_as_fetch 'quality/qc/qc_samples', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
  #   end
  #   expect_json_replace_dialog
  # end
  
  # def test_create
  #   authorise_pass!
  #   ensure_exists!(INTERACTOR)
  #   INTERACTOR.any_instance.stubs(:create_qc_sample).returns(ok_response)
  #   post 'quality/qc/qc_samples', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
  #   expect_ok_redirect
  # end
  
  # def test_create_fail
  #   authorise_pass!
  #   ensure_exists!(INTERACTOR)
  #   INTERACTOR.any_instance.stubs(:create_qc_sample).returns(bad_response)
  #   Quality::Qc::QcSample::New.stub(:call, bland_page) do
  #     post_as_fetch 'quality/qc/qc_samples', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
  #   end
  #   expect_bad_page
  #
  #   Quality::Qc::QcSample::New.stub(:call, bland_page) do
  #     post 'quality/qc/qc_samples', {}, 'rack.session' => { user_id: 1, last_grid_url: DEFAULT_LAST_GRID_URL }
  #   end
  #   expect_bad_redirect(url: '/quality/qc/qc_samples/new')
  # end
end
