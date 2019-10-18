# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module FinishedGoodsApp
  class TestVoyagePortInteractor < MiniTestWithHooks
    include VoyagePortFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(FinishedGoodsApp::VoyagePortRepo)
    end

    def test_voyage_port
      FinishedGoodsApp::VoyagePortRepo.any_instance.stubs(:find_voyage_port_flat).returns(fake_voyage_port)
      entity = interactor.send(:voyage_port, 1)
      assert entity.is_a?(VoyagePort)
    end

    def test_create_voyage_port
      attrs = fake_voyage_port.to_h.reject { |k, _| k == :id }
      voyage_id = attrs[:voyage_id]
      res = interactor.create_voyage_port(voyage_id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(VoyagePortFlat, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_voyage_port_fail
      attrs = fake_voyage_port(id: nil).to_h.reject { |k, _| k == :voyage_id }
      voyage_id = attrs[:voyage_id]
      res = interactor.create_voyage_port(voyage_id, attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:id]
    end

    def test_update_voyage_port
      id = create_voyage_port
      attrs = interactor.send(:repo).find_hash(:voyage_ports, id).reject { |k, _| k == :id }
      value = attrs[:port_id]
      updated_port_id = create_port
      attrs[:port_id] = updated_port_id
      res = interactor.update_voyage_port(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(VoyagePortFlat, res.instance)
      assert_equal updated_port_id, res.instance.port_id
      refute_equal value, res.instance.port_id
    end

    def test_update_voyage_port_fail
      id = create_voyage_port
      attrs = interactor.send(:repo).find_hash(:voyage_ports, id).reject { |k, _| %i[id voyage_id].include?(k) }
      res = interactor.update_voyage_port(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:voyage_id]
    end

    def test_delete_voyage_port
      id = create_voyage_port
      assert_count_changed(:voyage_ports, -1) do
        res = interactor.delete_voyage_port(id)
        assert res.success, res.message
      end
    end

    private

    def voyage_port_attrs
      voyage_id = create_voyage
      port_id = create_port
      vessel_id = create_vessel

      {
        id: 1,
        voyage_id: voyage_id,
        port_id: port_id,
        trans_shipment_vessel_id: vessel_id,
        ata: '2010-01-01 12:00',
        atd: '2010-01-01 12:00',
        eta: '2010-01-01 12:00',
        etd: '2010-01-01 12:00',
        active: true
      }
    end

    def fake_voyage_port(overrides = {})
      VoyagePort.new(voyage_port_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= VoyagePortInteractor.new(current_user, {}, {}, {})
    end
  end
end
