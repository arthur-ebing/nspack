# # frozen_string_literal: true
#
# require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')
#
# module ProductionApp
#   class TestReworksRunInteractor < MiniTestWithHooks
#     include ReworksFactory
#     include MasterfilesApp::QualityFactory
#
#     def test_repo
#       repo = interactor.send(:repo)
#       assert repo.is_a?(ProductionApp::ReworksRepo)
#     end
#
#     def test_reworks_run
#       ProductionApp::ReworksRepo.any_instance.stubs(:find_reworks_run).returns(fake_reworks_run)
#       entity = interactor.send(:reworks_run, 1)
#       assert entity.is_a?(ReworksRun)
#     end
#
#     def test_create_reworks_run
#       attrs = fake_reworks_run.to_h.reject { |k, _| k == :id }
#       res = interactor.create_reworks_run(attrs)
#       assert res.success, "#{res.message} : #{res.errors.inspect}"
#       assert_instance_of(ReworksRun, res.instance)
#       assert res.instance.id.nonzero?
#     end
#
#     def test_create_reworks_run_fail
#       attrs = fake_reworks_run(user: nil).to_h.reject { |k, _| k == :id }
#       res = interactor.create_reworks_run(attrs)
#       refute res.success, 'should fail validation'
#       assert_equal ['must be filled'], res.errors[:user]
#     end
#
#     def test_update_reworks_run
#       id = create_reworks_run
#       attrs = interactor.send(:repo).find_hash(:reworks_runs, id).reject { |k, _| k == :id }
#       value = attrs[:user]
#       attrs[:user] = 'a_change'
#       res = interactor.update_reworks_run(id, attrs)
#       assert res.success, "#{res.message} : #{res.errors.inspect}"
#       assert_instance_of(ReworksRun, res.instance)
#       assert_equal 'a_change', res.instance.user
#       refute_equal value, res.instance.user
#     end
#
#     def test_update_reworks_run_fail
#       id = create_reworks_run
#       attrs = interactor.send(:repo).find_hash(:reworks_runs, id).reject { |k, _| %i[id user].include?(k) }
#       res = interactor.update_reworks_run(id, attrs)
#       refute res.success, "#{res.message} : #{res.errors.inspect}"
#       assert_equal ['is missing'], res.errors[:user]
#     end
#
#     def test_delete_reworks_run
#       id = create_reworks_run
#       assert_count_changed(:reworks_runs, -1) do
#         res = interactor.delete_reworks_run(id)
#         assert res.success, res.message
#       end
#     end
#
#     private
#
#     def reworks_run_attrs
#       reworks_run_type_id = create_reworks_run_type
#       scrap_reason_id = create_scrap_reason
#
#       {
#         id: 1,
#         user: Faker::Lorem.unique.word,
#         reworks_run_type_id: reworks_run_type_id,
#         remarks: 'ABC',
#         scrap_reason_id: scrap_reason_id,
#         pallets_selected: %w[A B C],
#         pallets_affected: %w[A B C],
#         changes_made: {},
#         pallets_scrapped: %w[A B C],
#         pallets_unscrapped: %w[A B C]
#       }
#     end
#
#     def fake_reworks_run(overrides = {})
#       ReworksRun.new(reworks_run_attrs.merge(overrides))
#     end
#
#     def interactor
#       @interactor ||= ReworksRunInteractor.new(current_user, {}, {}, {})
#     end
#   end
# end
