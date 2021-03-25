# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestPersonInteractor < MiniTestWithHooks
    include PartyFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::PartyRepo)
    end

    def test_person
      MasterfilesApp::PartyRepo.any_instance.stubs(:find_person).returns(fake_person)
      entity = interactor.send(:person, 1)
      assert entity.is_a?(Person)
    end

    def test_create_person
      attrs = fake_person.to_h.reject { |k, _| k == :id }
      res = interactor.create_person(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Person, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_person_fail
      attrs = fake_person(surname: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_person(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:surname]
    end

    def test_update_person
      id = create_person
      attrs = interactor.send(:repo).find_person(id).to_h.reject { |k, _| k == :id }
      value = attrs[:surname]
      attrs[:surname] = 'a_change'
      res = interactor.update_person(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(Person, res.instance)
      assert_equal 'a_change', res.instance.surname
      refute_equal value, res.instance.surname
    end

    def test_update_person_fail
      id = create_person
      attrs = interactor.send(:repo).find_person(id).to_h.reject { |k, _| %i[id surname].include?(k) }
      res = interactor.update_person(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:surname]
    end

    def test_delete_person
      id = create_person
      assert_count_changed(:people, -1) do
        res = interactor.delete_person(id)
        assert res.success, res.message
      end
    end

    private

    def person_attrs
      party_id = create_party(party_type: 'P')
      id = create_person(party_id: party_id)
      role_ids = party_role_ids(party_id)
      address_ids = party_address_ids(party_id)
      contact_method_ids = party_contact_method_ids(party_id)
      {
        id: id,
        party_id: party_id,
        party_name: 'Title First Name Surname',
        surname: 'Surname',
        first_name: 'First Name',
        title: 'Title',
        vat_number: '789456',
        role_ids: role_ids,
        role_names: %w[A B C],
        specialised_role_names: ['ABC'],
        address_ids: address_ids,
        contact_method_ids: contact_method_ids,
        active: true,
        target_market_ids: []
      }
    end

    def fake_person(overrides = {})
      Person.new(person_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= PersonInteractor.new(current_user, {}, {}, {})
    end
  end
end
