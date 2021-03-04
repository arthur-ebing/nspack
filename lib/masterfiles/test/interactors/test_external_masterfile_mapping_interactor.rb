# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestExternalMasterfileMappingInteractor < MiniTestWithHooks
    include GeneralFactory
    include FarmFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::GeneralRepo)
    end

    def test_external_masterfile_mapping
      MasterfilesApp::GeneralRepo.any_instance.stubs(:find_external_masterfile_mapping).returns(fake_external_masterfile_mapping)
      entity = interactor.send(:external_masterfile_mapping, 1)
      assert entity.is_a?(ExternalMasterfileMapping)
    end

    def test_create_external_masterfile_mapping
      attrs = fake_external_masterfile_mapping.to_h.reject { |k, _| k == :id }
      res = interactor.create_external_masterfile_mapping(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(ExternalMasterfileMapping, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_external_masterfile_mapping_fail
      attrs = fake_external_masterfile_mapping(masterfile_table: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_external_masterfile_mapping(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:masterfile_table]
    end

    def test_update_external_masterfile_mapping
      id = create_external_masterfile_mapping
      attrs = interactor.send(:repo).find_hash(:external_masterfile_mappings, id).reject { |k, _| k == :id }
      value = attrs[:external_code]
      attrs[:external_code] = 'a_change'
      res = interactor.update_external_masterfile_mapping(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(ExternalMasterfileMapping, res.instance)
      assert_equal 'a_change', res.instance.external_code
      refute_equal value, res.instance.masterfile_table
    end

    def test_update_external_masterfile_mapping_fail
      id = create_external_masterfile_mapping
      attrs = interactor.send(:repo).find_hash(:external_masterfile_mappings, id).reject { |k, _| %i[id masterfile_table].include?(k) }
      res = interactor.update_external_masterfile_mapping(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:masterfile_table]
    end

    def test_delete_external_masterfile_mapping
      id = create_external_masterfile_mapping
      assert_count_changed(:external_masterfile_mappings, -1) do
        res = interactor.delete_external_masterfile_mapping(id)
        assert res.success, res.message
      end
    end

    private

    def external_masterfile_mapping_attrs
      {
        id: 1,
        masterfile_table: 'pucs',
        masterfile_column: 'puc_code',
        masterfile_code: 'ABC',
        mapping: 'ABC',
        external_system: 'ABC',
        external_code: 'ABC',
        masterfile_id: 1,
        created_at: '2012-12-01',
        updated_at: '2012-12-01'
      }
    end

    def fake_external_masterfile_mapping(overrides = {})
      ExternalMasterfileMapping.new(external_masterfile_mapping_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= ExternalMasterfileMappingInteractor.new(current_user, {}, {}, {})
    end
  end
end
