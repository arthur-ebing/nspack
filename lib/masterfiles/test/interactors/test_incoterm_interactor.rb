# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestIncotermInteractor < MiniTestWithHooks
    include FinanceFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::FinanceRepo)
    end

    def test_incoterm
      MasterfilesApp::FinanceRepo.any_instance.stubs(:find_incoterm).returns(fake_incoterm)
      entity = interactor.send(:incoterm, 1)
      assert entity.is_a?(Incoterm)
    end

    def test_create_incoterm
      attrs = fake_incoterm.to_h.reject { |k, _| k == :id }
      res = interactor.create_incoterm(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Incoterm, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_incoterm_fail
      attrs = fake_incoterm(incoterm: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_incoterm(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:incoterm]
    end

    def test_update_incoterm
      id = create_incoterm
      attrs = interactor.send(:repo).find_hash(:incoterms, id).reject { |k, _| k == :id }
      value = attrs[:incoterm]
      attrs[:incoterm] = 'a_change'
      res = interactor.update_incoterm(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Incoterm, res.instance)
      assert_equal 'a_change', res.instance.incoterm
      refute_equal value, res.instance.incoterm
    end

    def test_update_incoterm_fail
      id = create_incoterm
      attrs = interactor.send(:repo).find_hash(:incoterms, id).reject { |k, _| %i[id incoterm].include?(k) }
      res = interactor.update_incoterm(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:incoterm]
    end

    def test_delete_incoterm
      id = create_incoterm
      assert_count_changed(:incoterms, -1) do
        res = interactor.delete_incoterm(id)
        assert res.success, res.message
      end
    end

    private

    def incoterm_attrs
      {
        id: 1,
        incoterm: Faker::Lorem.unique.word,
        active: true
      }
    end

    def fake_incoterm(overrides = {})
      Incoterm.new(incoterm_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= IncotermInteractor.new(current_user, {}, {}, {})
    end
  end
end
