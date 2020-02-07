# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestScrapReasonInteractor < MiniTestWithHooks
    include QualityFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::QualityRepo)
    end

    def test_scrap_reason
      MasterfilesApp::QualityRepo.any_instance.stubs(:find_scrap_reason).returns(fake_scrap_reason)
      entity = interactor.send(:scrap_reason, 1)
      assert entity.is_a?(ScrapReason)
    end

    def test_create_scrap_reason
      attrs = fake_scrap_reason.to_h.reject { |k, _| k == :id }
      res = interactor.create_scrap_reason(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(ScrapReason, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_scrap_reason_fail
      attrs = fake_scrap_reason(scrap_reason: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_scrap_reason(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:scrap_reason]
    end

    def test_update_scrap_reason
      id = create_scrap_reason
      attrs = interactor.send(:repo).find_hash(:scrap_reasons, id).reject { |k, _| k == :id }
      value = attrs[:scrap_reason]
      attrs[:scrap_reason] = 'a_change'
      res = interactor.update_scrap_reason(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(ScrapReason, res.instance)
      assert_equal 'a_change', res.instance.scrap_reason
      refute_equal value, res.instance.scrap_reason
    end

    def test_update_scrap_reason_fail
      id = create_scrap_reason
      attrs = interactor.send(:repo).find_hash(:scrap_reasons, id).reject { |k, _| %i[id scrap_reason].include?(k) }
      res = interactor.update_scrap_reason(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:scrap_reason]
    end

    def test_delete_scrap_reason
      id = create_scrap_reason
      assert_count_changed(:scrap_reasons, -1) do
        res = interactor.delete_scrap_reason(id)
        assert res.success, res.message
      end
    end

    private

    def scrap_reason_attrs
      {
        id: 1,
        scrap_reason: Faker::Lorem.unique.word,
        description: 'ABC',
        active: true,
        applies_to_pallets: true,
        applies_to_bins: true
      }
    end

    def fake_scrap_reason(overrides = {})
      ScrapReason.new(scrap_reason_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= ScrapReasonInteractor.new(current_user, {}, {}, {})
    end
  end
end
