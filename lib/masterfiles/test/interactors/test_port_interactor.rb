# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPortInteractor < MiniTestWithHooks
    include PortFactory
    include PortTypeFactory
    include VoyageTypeFactory
    include DepotFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::PortRepo)
    end

    def test_port
      MasterfilesApp::PortRepo.any_instance.stubs(:find_port_flat).returns(fake_port)
      entity = interactor.send(:port, 1)
      assert entity.is_a?(Port)
    end

    def test_create_port
      attrs = fake_port.to_h.reject { |k, _| k == :id }
      res = interactor.create_port(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PortFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_port_fail
      attrs = fake_port(port_code: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_port(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:port_code]
    end

    def test_update_port
      id = create_port
      attrs = interactor.send(:repo).find_hash(:ports, id).reject { |k, _| %i[id].include?(k) }
      attrs[:port_type_ids] = attrs[:port_type_ids].to_a
      attrs[:voyage_type_ids] = attrs[:voyage_type_ids].to_a
      value = attrs[:port_code]

      attrs[:port_code] = 'a_change'
      res = interactor.update_port(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(PortFlat, res.instance)
      assert_equal 'a_change', res.instance.port_code
      refute_equal value, res.instance.port_code
    end

    def test_update_port_fail
      id = create_port
      attrs = interactor.send(:repo).find_hash(:ports, id).reject { |k, _| %i[id port_code].include?(k) }
      res = interactor.update_port(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:port_code]
    end

    def test_delete_port
      id = create_port
      assert_count_changed(:ports, -1) do
        res = interactor.delete_port(id)
        assert res.success, res.message
      end
    end

    private

    def port_attrs
      port_type_id = create_port_type
      voyage_type_id = create_voyage_type
      destination_city_id = create_destination_city
      {
        id: 1,
        city_id: destination_city_id,
        port_code: Faker::Lorem.unique.word,
        description: 'ABC',
        port_type_ids: BaseRepo.new.array_for_db_col([port_type_id]),
        voyage_type_ids: BaseRepo.new.array_for_db_col([voyage_type_id]),
        active: true
      }
    end

    def fake_port(overrides = {})
      Port.new(port_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= PortInteractor.new(current_user, {}, {}, {})
    end
  end
end
