# frozen_string_literal: true

# ========================================================= #
# NB. Scaffolds for test factories should be combined       #
#     - Otherwise you'll have methods for the same table in #
#       several factories.                                  #
#     - Rather create a factory for several related tables  #
# ========================================================= #

module MasterfilesApp
  module MrlRequirementFactory
    def create_mrl_requirement(opts = {})
      id = get_available_factory_record(:mrl_requirements, opts)
      return id unless id.nil?

      # season_id = create_season
      opts[:season_id] ||= create_season
      # qa_standard_id = create_qa_standard
      opts[:qa_standard_id] ||= create_qa_standard
      # target_market_group_id = create_target_market_group
      opts[:target_market_group_id] ||= create_target_market_group unless opts.key?(:target_market_group_id)
      # target_market_id = create_target_market
      opts[:target_market_id] ||= create_target_market unless opts.key?(:target_market_id)
      # party_role_id = create_party_role
      opts[:party_role_id] ||= create_party_role unless opts.key?(:party_role_id)
      # cultivar_group_id = create_cultivar_group
      opts[:cultivar_group_id] ||= create_cultivar_group unless opts.key?(:cultivar_group_id)
      # cultivar_id = create_cultivar
      opts[:cultivar_id] ||= create_cultivar unless opts.key?(:cultivar_id)

      default = {
        # season_id: season_id,
        # qa_standard_id: qa_standard_id,
        # packed_tm_group_id: target_market_group_id,
        # target_market_id: target_market_id,
        # target_customer_id: party_role_id,
        # cultivar_group_id: cultivar_group_id,
        # cultivar_id: cultivar_id,
        max_num_chemicals_allowed: Faker::Number.number(digits: 4),
        require_orchard_level_results: false,
        no_results_equal_failure: false,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:mrl_requirements].insert(default.merge(opts))
    end

    def create_season(opts = {})
      id = get_available_factory_record(:seasons, opts)
      return id unless id.nil?

      # season_group_id = create_season_group
      opts[:season_group_id] ||= create_season_group
      # commodity_id = create_commodity
      opts[:commodity_id] ||= create_commodity

      default = {
        # season_group_id: season_group_id,
        # commodity_id: commodity_id,
        season_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        season_year: Faker::Number.number(digits: 4),
        start_date: '2010-01-01',
        end_date: '2010-01-01',
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:seasons].insert(default.merge(opts))
    end

    def create_season_group(opts = {})
      id = get_available_factory_record(:season_groups, opts)
      return id unless id.nil?

      default = {
        season_group_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        season_group_year: Faker::Number.number(digits: 4),
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:season_groups].insert(default.merge(opts))
    end

    def create_commodity(opts = {})
      id = get_available_factory_record(:commodities, opts)
      return id unless id.nil?

      # commodity_group_id = create_commodity_group
      opts[:commodity_group_id] ||= create_commodity_group

      default = {
        # commodity_group_id: commodity_group_id,
        code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        hs_code: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        requires_standard_counts: false,
        use_size_ref_for_edi: false,
        colour_applies: false,
        allocate_sample_rmt_bins: false
      }
      DB[:commodities].insert(default.merge(opts))
    end

    def create_commodity_group(opts = {})
      id = get_available_factory_record(:commodity_groups, opts)
      return id unless id.nil?

      default = {
        code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:commodity_groups].insert(default.merge(opts))
    end

    def create_qa_standard(opts = {})
      id = get_available_factory_record(:qa_standards, opts)
      return id unless id.nil?

      # qa_standard_type_id = create_qa_standard_type
      opts[:qa_standard_type_id] ||= create_qa_standard_type

      default = {
        qa_standard_name: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        season_id: season_id,
        # qa_standard_type_id: qa_standard_type_id,
        target_market_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        packed_tm_group_ids: BaseRepo.new.array_for_db_col([1, 2, 3]),
        internal_standard: false,
        applies_to_all_markets: false,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:qa_standards].insert(default.merge(opts))
    end

    def create_qa_standard_type(opts = {})
      id = get_available_factory_record(:qa_standard_types, opts)
      return id unless id.nil?

      default = {
        qa_standard_type_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:qa_standard_types].insert(default.merge(opts))
    end

    def create_target_market_group(opts = {})
      id = get_available_factory_record(:target_market_groups, opts)
      return id unless id.nil?

      # target_market_group_type_id = create_target_market_group_type
      opts[:target_market_group_type_id] ||= create_target_market_group_type

      default = {
        # target_market_group_type_id: target_market_group_type_id,
        target_market_group_name: Faker::Lorem.unique.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        description: Faker::Lorem.word,
        local_tm_group: false
      }
      DB[:target_market_groups].insert(default.merge(opts))
    end

    def create_target_market_group_type(opts = {})
      id = get_available_factory_record(:target_market_group_types, opts)
      return id unless id.nil?

      default = {
        target_market_group_type_code: Faker::Lorem.unique.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:target_market_group_types].insert(default.merge(opts))
    end

    def create_target_market(opts = {})
      id = get_available_factory_record(:target_markets, opts)
      return id unless id.nil?

      default = {
        target_market_name: Faker::Lorem.unique.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        description: Faker::Lorem.word,
        inspection_tm: false
      }
      DB[:target_markets].insert(default.merge(opts))
    end

    def create_party_role(opts = {})
      id = get_available_factory_record(:party_roles, opts)
      return id unless id.nil?

      # party_id = create_party
      opts[:party_id] ||= create_party
      # role_id = create_role
      opts[:role_id] ||= create_role
      # organization_id = create_organization
      opts[:organization_id] ||= create_organization unless opts.key?(:organization_id)
      # person_id = create_person
      opts[:person_id] ||= create_person unless opts.key?(:person_id)

      default = {
        # party_id: party_id,
        # role_id: role_id,
        # organization_id: organization_id,
        # person_id: person_id,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:party_roles].insert(default.merge(opts))
    end

    def create_party(opts = {})
      id = get_available_factory_record(:parties, opts)
      return id unless id.nil?

      default = {
        party_type: Faker::Lorem.unique.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:parties].insert(default.merge(opts))
    end

    def create_role(opts = {})
      id = get_available_factory_record(:roles, opts)
      return id unless id.nil?

      default = {
        name: Faker::Lorem.unique.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        specialised: false
      }
      DB[:roles].insert(default.merge(opts))
    end

    def create_organization(opts = {})
      id = get_available_factory_record(:organizations, opts)
      return id unless id.nil?

      default = {
        party_id: party_id,
        parent_id: organization_id,
        short_description: Faker::Lorem.unique.word,
        medium_description: Faker::Lorem.word,
        long_description: Faker::Lorem.word,
        vat_number: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        edi_hub_address: Faker::Lorem.word,
        company_reg_no: Faker::Lorem.word
      }
      DB[:organizations].insert(default.merge(opts))
    end

    def create_person(opts = {})
      id = get_available_factory_record(:people, opts)
      return id unless id.nil?

      default = {
        party_id: party_id,
        surname: Faker::Lorem.unique.word,
        first_name: Faker::Lorem.word,
        title: Faker::Lorem.word,
        vat_number: Faker::Lorem.word,
        active: true,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00'
      }
      DB[:people].insert(default.merge(opts))
    end

    def create_cultivar_group(opts = {})
      id = get_available_factory_record(:cultivar_groups, opts)
      return id unless id.nil?

      default = {
        cultivar_group_code: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        active: true,
        commodity_id: commodity_id
      }
      DB[:cultivar_groups].insert(default.merge(opts))
    end

    def create_cultivar(opts = {})
      id = get_available_factory_record(:cultivars, opts)
      return id unless id.nil?

      default = {
        cultivar_group_id: cultivar_group_id,
        cultivar_name: Faker::Lorem.unique.word,
        description: Faker::Lorem.word,
        created_at: '2010-01-01 12:00',
        updated_at: '2010-01-01 12:00',
        active: true,
        cultivar_code: Faker::Lorem.word
      }
      DB[:cultivars].insert(default.merge(opts))
    end
  end
end
