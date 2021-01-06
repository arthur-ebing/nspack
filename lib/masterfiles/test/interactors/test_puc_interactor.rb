# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPucInteractor < MiniTestWithHooks
    include FarmFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::FarmRepo)
    end

    def test_puc
      MasterfilesApp::FarmRepo.any_instance.stubs(:find_puc).returns(fake_puc)
      entity = interactor.send(:puc, 1)
      assert entity.is_a?(Puc)
    end

    def test_create_puc
      attrs = fake_puc.to_h.reject { |k, _| k == :id }
      res = interactor.create_puc(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Puc, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_puc_fail
      attrs = fake_puc(puc_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_puc(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:puc_code]
    end

    def test_update_puc
      id = create_puc
      attrs = interactor.send(:repo).find_hash(:pucs, id).reject { |k, _| k == :id }
      value = attrs[:puc_code]
      attrs[:puc_code] = 'a_change'
      res = interactor.update_puc(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Puc, res.instance)
      assert_equal 'a_change', res.instance.puc_code
      refute_equal value, res.instance.puc_code
    end

    def test_update_puc_fail
      id = create_puc
      attrs = interactor.send(:repo).find_hash(:pucs, id).reject { |k, _| %i[id puc_code].include?(k) }
      value = attrs[:gap_code]
      attrs[:gap_code] = 'a_change'
      res = interactor.update_puc(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:puc_code]
      after = interactor.send(:repo).find_hash(:pucs, id)
      refute_equal 'a_change', after[:gap_code]
      assert_equal value, after[:gap_code]
    end

    def test_delete_puc
      id = create_puc
      assert_count_changed(:pucs, -1) do
        res = interactor.delete_puc(id)
        assert res.success, res.message
      end
    end

    private

    def puc_attrs
      {
        id: 1,
        puc_code: Faker::Lorem.unique.word,
        gap_code: 'ABC',
        active: true
      }
    end

    def fake_puc(overrides = {})
      Puc.new(puc_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= PucInteractor.new(current_user, {}, {}, {})
    end
  end
end
