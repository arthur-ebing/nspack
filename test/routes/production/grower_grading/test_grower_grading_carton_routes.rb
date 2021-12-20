# frozen_string_literal: true

require File.join(File.expand_path('./../../../', __dir__), 'test_helper_for_routes')

class TestGrowerGradingCartonRoutes < RouteTester

  INTERACTOR = ProductionApp::GrowerGradingCartonInteractor

  def test_show
    authorise_pass!
    ensure_exists!(INTERACTOR)
    Production::GrowerGrading::GrowerGradingCarton::Show.stub(:call, bland_page) do
      get 'production/grower_grading/grower_grading_cartons/1', {}, 'rack.session' => { user_id: 1 }
    end
    expect_bland_page
  end

  def test_show_fail
    authorise_fail!
    ensure_exists!(INTERACTOR)
    get 'production/grower_grading/grower_grading_cartons/1', {}, 'rack.session' => { user_id: 1 }
    expect_permission_error
  end
end
