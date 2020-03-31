# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestEcertAgreementInteractor < MiniTestWithHooks
    include EcertAgreementFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(FinishedGoodsApp::EcertRepo)
    end

    def test_ecert_agreement
      FinishedGoodsApp::EcertRepo.any_instance.stubs(:find_ecert_agreement).returns(fake_ecert_agreement)
      entity = interactor.send(:ecert_agreement, 1)
      assert entity.is_a?(EcertAgreement)
    end

    private

    def ecert_agreement_attrs
      {
        id: 1,
        code: Faker::Lorem.unique.word,
        name: 'ABC',
        description: 'ABC',
        start_date: '2010-01-01',
        end_date: '2010-01-01',
        active: true
      }
    end

    def fake_ecert_agreement(overrides = {})
      EcertAgreement.new(ecert_agreement_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= EcertAgreementInteractor.new(current_user, {}, {}, {})
    end
  end
end
