# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestLoadContainerInteractor < MiniTestWithHooks
    include LoadContainerFactory
    include LoadFactory
    include MasterfilesApp::PartyFactory
    include MasterfilesApp::DepotFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(FinishedGoodsApp::LoadContainerRepo)
    end

    def test_load_container
      FinishedGoodsApp::LoadContainerRepo.any_instance.stubs(:find_load_container).returns(fake_load_container)
      entity = interactor.send(:load_container, 1)
      assert entity.is_a?(LoadContainer)
    end

    def test_create_load_container
      attrs = fake_load_container.to_h.reject { |k, _| k == :id }
      res = interactor.create_load_container(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(LoadContainer, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_load_container_fail
      attrs = fake_load_container(container_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_load_container(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:container_code]
    end

    def test_update_load_container
      id = create_load_container
      attrs = interactor.send(:repo).find_hash(:load_containers, id).reject { |k, _| k == :id }
      value = attrs[:container_code]
      attrs[:container_code] = 'a_change'
      res = interactor.update_load_container(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(LoadContainer, res.instance)
      assert_equal 'a_change', res.instance.container_code
      refute_equal value, res.instance.container_code
    end

    def test_update_load_container_fail
      id = create_load_container
      attrs = interactor.send(:repo).find_hash(:load_containers, id).reject { |k, _| %i[id container_code].include?(k) }
      res = interactor.update_load_container(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:container_code]
    end

    def test_delete_load_container
      id = create_load_container
      assert_count_changed(:load_containers, -1) do
        res = interactor.delete_load_container(id)
        assert res.success, res.message
      end
    end

    private

    def load_container_attrs
      load_id = create_load
      cargo_temperature_id = create_cargo_temperature
      container_stack_type_id = create_container_stack_type

      {
        id: 1,
        load_id: load_id,
        container_code: Faker::Lorem.unique.word,
        container_vents: 'ABC',
        container_seal_code: 'ABC',
        container_temperature_rhine: '234',
        container_temperature_rhine2: '234',
        internal_container_code: 'ABC',
        max_gross_weight: 1.0,
        tare_weight: 1.0,
        max_payload: 1.0,
        actual_payload: 1.0,
        verified_gross_weight: 1.0,
        verified_gross_weight_date: '2010-01-01 12:00',
        cargo_temperature_id: cargo_temperature_id,
        stack_type_id: container_stack_type_id,
        active: true
      }
    end

    def fake_load_container(overrides = {})
      LoadContainer.new(load_container_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= LoadContainerInteractor.new(current_user, {}, {}, {})
    end
  end
end
