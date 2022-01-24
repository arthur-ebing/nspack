# frozen_string_literal: true

require File.join(File.expand_path('../../../../test', __dir__), 'test_helper')

module MasterfilesApp
  class TestQaStandardInteractor < MiniTestWithHooks
    include QaStandardFactory

    def test_repo
      repo = interactor.send(:repo)
      assert repo.is_a?(MasterfilesApp::QaStandardRepo)
    end

    def test_qa_standard
      MasterfilesApp::QaStandardRepo.any_instance.stubs(:find_qa_standard).returns(fake_qa_standard)
      entity = interactor.send(:qa_standard, 1)
      assert entity.is_a?(QaStandard)
    end

    def test_create_qa_standard
      attrs = fake_qa_standard.to_h.reject { |k, _| k == :id }
      res = interactor.create_qa_standard(attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(QaStandard, res.instance)
      assert res.instance.id.nonzero?
    end

    def test_create_qa_standard_fail
      attrs = fake_qa_standard(qa_standard_name: nil).to_h.reject { |k, _| k == :id }
      res = interactor.create_qa_standard(attrs)
      refute res.success, 'should fail validation'
      assert_equal ['must be filled'], res.errors[:qa_standard_name]
    end

    def test_update_qa_standard
      id = create_qa_standard
      attrs = interactor.send(:repo).find_hash(:qa_standards, id).reject { |k, _| k == :id }
      value = attrs[:qa_standard_name]
      attrs[:qa_standard_name] = 'a_change'
      res = interactor.update_qa_standard(id, attrs)
      assert res.success, "#{res.message} : #{res.errors.inspect}"
      assert_instance_of(QaStandard, res.instance)
      assert_equal 'a_change', res.instance.qa_standard_name
      refute_equal value, res.instance.qa_standard_name
    end

    def test_update_qa_standard_fail
      id = create_qa_standard
      attrs = interactor.send(:repo).find_hash(:qa_standards, id).reject { |k, _| %i[id qa_standard_name].include?(k) }
      res = interactor.update_qa_standard(id, attrs)
      refute res.success, "#{res.message} : #{res.errors.inspect}"
      assert_equal ['is missing'], res.errors[:qa_standard_name]
    end

    def test_delete_qa_standard
      id = create_qa_standard(force_create: true)
      assert_count_changed(:qa_standards, -1) do
        res = interactor.delete_qa_standard(id)
        assert res.success, res.message
      end
    end

    private

    def qa_standard_attrs
      season_id = create_season
      qa_standard_type_id = create_qa_standard_type

      {
        id: 1,
        qa_standard_name: Faker::Lorem.unique.word,
        description: 'ABC',
        season_id: season_id,
        qa_standard_type_id: qa_standard_type_id,
        target_market_ids: [1, 2, 3],
        packed_tm_group_ids: [1, 2, 3],
        internal_standard: false,
        applies_to_all_markets: false,
        active: true
      }
    end

    def fake_qa_standard(overrides = {})
      QaStandard.new(qa_standard_attrs.merge(overrides))
    end

    def interactor
      @interactor ||= QaStandardInteractor.new(current_user, {}, {}, {})
    end
  end
end
