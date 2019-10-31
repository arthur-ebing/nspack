# frozen_string_literal: true

require File.join(File.expand_path('./../../../', __dir__), 'test_helper_for_routes')

class TestMesModuleRoutes < RouteTester

  INTERACTOR = LabelApp::MesModuleInteractor

  def test_show
    authorise_pass!
    ensure_exists!(INTERACTOR)
    Labels::Designs::MesModule::Show.stub(:call, bland_page) do
      get 'labels/mes_modules/mes_modules/1', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_show_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'labels/mes_modules/mes_modules/1', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end

  def test_refresh
    skip 'todo'
  end
end
