# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestCultivarInteractor < MiniTestWithHooks
    include CultivarFactory
    include CommodityFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::CultivarRepo)
    end

    def test_cultivar
      MasterfilesApp::CultivarRepo.any_instance.stubs(:find_cultivar).returns(fake_cultivar)
      entity = interactor.send(:cultivar, 1)
      assert entity.is_a?(Cultivar)
    end

    def test_create_cultivar
      attrs = fake_cultivar.to_h.reject { |k, _| k == :id }
      res = interactor.create_cultivar(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Cultivar, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_cultivar_fail
      attrs = fake_cultivar(cultivar_name: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_cultivar(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:cultivar_name]
    end

    def test_update_cultivar
      id = create_cultivar
      attrs = interactor.send(:repo).find_hash(:cultivars, id).reject { |k, _| k == :id }
      value = attrs[:cultivar_name]
      attrs[:cultivar_name] = 'a_change'
      res = interactor.update_cultivar(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Cultivar, res.instance)
      assert_equal 'a_change', res.instance.cultivar_name
      refute_equal value, res.instance.cultivar_name
    end

    def test_update_cultivar_fail
      id = create_cultivar
      attrs = interactor.send(:repo).find_hash(:cultivars, id).reject { |k, _| %i[id cultivar_name].include?(k) }
      value = attrs[:description]
      attrs[:description] = 'a_change'
      res = interactor.update_cultivar(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:cultivar_name]
      after = interactor.send(:repo).find_hash(:cultivars, id)
      refute_equal 'a_change', after[:description]
      assert_equal value, after[:description]
    end

    def test_delete_cultivar
      id = create_cultivar
      assert_count_changed(:cultivars, -1) do
        res = interactor.delete_cultivar(id)
        assert res.success, res.message
      end
    end

    private

    def cultivar_attrs
      commodity_id = create_commodity
      cultivar_group_id = create_cultivar_group

      {
        id: 1,
        commodity_id: commodity_id,
        cultivar_group_id: cultivar_group_id,
        cultivar_name: Faker::Lorem.unique.word,
        description: 'ABC',
        cultivar_code: 'ABC',
        cultivar_group_code: Faker::Lorem.unique.word,
        active: true
      }
    end

    def fake_cultivar(overrides = {})
      Cultivar.new(cultivar_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= CultivarInteractor.new(current_user, {}, {}, {})
    end
  end
end
