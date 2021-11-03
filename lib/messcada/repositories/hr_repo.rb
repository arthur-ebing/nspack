# frozen_string_literal: true

module MesscadaApp
  class HrRepo < BaseRepo # rubocop:disable Metrics/ClassLength
    def create_personnel_identifier(res)
      hw_type = if res[:card_reader]
                  'rfid-rdr'
                else
                  'rfid-usb'
                end
      DB[:personnel_identifiers].insert_conflict
                                .insert(identifier: res[:value],
                                        hardware_type: hw_type)
    end

    def contract_worker_name(personnel_identifier)
      personnel_identifier_id = DB[:personnel_identifiers].where(identifier: personnel_identifier).get(:id)
      return nil if personnel_identifier_id.nil?

      id = DB[:contract_workers].where(personnel_identifier_id: personnel_identifier_id).get(:id)
      DB.get(Sequel.function(:fn_contract_worker_name, id))
    end

    def contract_worker_name_by_no(personnel_number)
      id = DB[:contract_workers].where(personnel_number: personnel_number).get(:id)
      DB.get(Sequel.function(:fn_contract_worker_name, id))
    end

    def contract_worker_id_and_identifier_id(personnel_identifier)
      DB[:personnel_identifiers]
        .join(:contract_workers, personnel_identifier_id: :id)
        .where(identifier: personnel_identifier)
        .select(Sequel[:contract_workers][:id].as(:contract_worker_id), :personnel_identifier_id, :personnel_number)
        .first
    end

    def personnel_identifier_id_from_device_identifier(identifier)
      DB[:personnel_identifiers].where(identifier: identifier).get(:id)
    end

    def identifier_from_contract_worker_id(id)
      DB[:contract_workers]
        .join(:personnel_identifiers, id: :personnel_identifier_id)
        .where(Sequel[:contract_workers][:id] => id)
        .get(:identifier)
    end

    def contract_worker_id_from_personnel_id(personnel_identifier_id)
      DB[:contract_workers].where(personnel_identifier_id: personnel_identifier_id).get(:id)
    end

    def contract_worker_id_from_personnel_number(personnel_number)
      DB[:contract_workers].where(personnel_number: personnel_number).get(:id)
    end

    def logged_in_worker_for_device(device, card_reader)
      id = get_id(:system_resources, system_resource_code: device)
      get_value(:system_resource_logins, :contract_worker_id, system_resource_id: id, card_reader: card_reader || '1')
    end

    # Record login event to system resource logins
    def login_worker(name, params) # rubocop:disable Metrics/AbcSize
      system_resource = params[:system_resource]
      res_repo = ProductionApp::ResourceRepo.new
      plant_type = res_repo.plant_resource_type_code_for_system_resource(system_resource.id)
      logout_worker(system_resource[:contract_worker_id]) unless plant_type == Crossbeams::Config::ResourceDefinitions::PALLETIZING_ROBOT
      # Logout_from_group if applicable
      remove_login_from_group(system_resource[:contract_worker_id])

      # The sysresource identifier can be null if the worker logged-in via personnel number instead of identifier,
      # so lookup the identifier and return it...
      identifier = system_resource[:identifier] || identifier_from_contract_worker_id(system_resource[:contract_worker_id])
      raise Crossbeams::InfoError, "No identifier for #{name}" if identifier.nil?

      if exists?(:system_resource_logins, system_resource_id: system_resource[:id], card_reader: system_resource[:card_reader])
        DB[:system_resource_logins]
          .where(system_resource_id: system_resource[:id], card_reader: system_resource[:card_reader])
          .update(contract_worker_id: system_resource[:contract_worker_id],
                  active: true,
                  from_external_system: false,
                  login_at: Time.now,
                  identifier: identifier)
      else
        DB[:system_resource_logins]
          .insert(system_resource_id: system_resource[:id],
                  card_reader: system_resource[:card_reader],
                  contract_worker_id: system_resource[:contract_worker_id],
                  active: true,
                  from_external_system: false,
                  login_at: Time.now,
                  identifier: identifier)
      end

      success_response('Logged on', contract_worker: name, identifier: identifier)
    end

    def logout_worker(contract_worker_id)
      # 1. find the resource
      system_resource_id = DB[:system_resource_logins].where(contract_worker_id: contract_worker_id, active: true).get(:system_resource_id)

      # 2. Logout
      DB[:system_resource_logins]
        .where(contract_worker_id: contract_worker_id, active: true)
        .update(last_logout_at: Time.now,
                from_external_system: false,
                active: false)

      logout_from_messcada(system_resource_id, contract_worker_id) # unless system_resource_id.nil?

      ok_response
    end

    def logout_device(device)
      # 1. find the logged-in worker idS
      system_resource_id = DB[:system_resources].where(system_resource_code: device).get(:id)
      contract_worker_ids = DB[:system_resource_logins].where(system_resource_id: system_resource_id, active: true).select_map(:contract_worker_id)

      # 2. Logout
      DB[:system_resource_logins]
        .where(system_resource_id: system_resource_id)
        .update(last_logout_at: Time.now,
                from_external_system: false,
                active: false)

      contract_worker_ids.each do |contract_worker_id|
        logout_from_messcada(system_resource_id, contract_worker_id) # unless system_resource_id.nil?
      end

      ok_response
    end

    def logout_from_messcada(system_resource_id, contract_worker_id)
      # First queue a logout for individual
      puts ">>> Logout INDIV - RES: #{system_resource_id} WRK: #{contract_worker_id}"
      enqueue_logout_job(system_resource_id, contract_worker_id)

      # Get the group id if the contract worker belongs to a group
      group_id = contract_worker_active_group_incentive_id(contract_worker_id)
      return if group_id.nil?

      # Logout from the group if applicable
      group_resource_id = DB[:group_incentives].where(id: group_id).get(:system_resource_id)
      puts ">>> Logout GROUP - RES: #{group_resource_id} WRK: #{contract_worker_id}"
      enqueue_logout_job(group_resource_id, contract_worker_id)
    end

    def enqueue_logout_job(system_resource_id, contract_worker_id)
      return if system_resource_id.nil?

      puts '>>> getting system resource data'
      opts = DB[:system_resources].where(id: system_resource_id).select(:system_resource_code, :ip_address, :legacy_messcada).first
      puts '>>> not legacy messcada' unless opts[:legacy_messcada]
      return unless opts[:legacy_messcada]

      puts '>>> enqueuing job to logoff messcada'
      Job::LogoutFromMesScadaRobot.enqueue(system_resource_id, opts[:system_resource_code], opts[:ip_address], contract_worker_id)
    end

    def active_system_resource_group_exists?(system_resource_id)
      exists?(:group_incentives, { system_resource_id: system_resource_id, active: true })
    end

    def active_group_incentive_id(system_resource_id)
      DB[:group_incentives]
        .where(system_resource_id: system_resource_id, active: true)
        .get(:id)
    end

    def group_has_incentive_workers?(group_incentive_id)
      ar = DB[:group_incentives]
           .where(id: group_incentive_id, active: true)
           .get(:incentive_target_worker_ids) || []
      ar.length.positive?
    end

    def packer_belongs_to_incentive_group?(group_incentive_id, contract_worker_id)
      query = <<~SQL
        SELECT EXISTS(
          SELECT id
          FROM group_incentives
          WHERE id = #{group_incentive_id}
           AND contract_worker_ids @> ARRAY[#{contract_worker_id}]
           AND active)
      SQL
      DB[query].single_value
    end

    def packer_belongs_to_active_incentive_group?(contract_worker_id)
      query = <<~SQL
        SELECT EXISTS(
          SELECT id
          FROM group_incentives
          WHERE contract_worker_ids @> ARRAY[#{contract_worker_id}]
           AND active)
      SQL
      DB[query].single_value
    end

    def contract_worker_active_group_incentive_id(contract_worker_id)
      query = <<~SQL
        SELECT id
        FROM group_incentives
        WHERE contract_worker_ids @> ARRAY[#{contract_worker_id}]
         AND active
      SQL
      DB[query].single_value
    end

    def create_group_incentive(params)
      attrs = params.to_h
      append_worker_targets(attrs)

      create(:group_incentives, attrs)
    end

    def update_group_incentive(group_incentive_id, params)
      attrs = params.to_h
      # calculate targets if active, but ignore if a group is just being made inactive.
      append_worker_targets(attrs) if attrs.key?(:active) && !attrs[:active]

      attrs[:from_external_system] = false
      update(:group_incentives, group_incentive_id, attrs)
    end

    def append_worker_targets(attrs)
      return unless attrs.key?(:contract_worker_ids)
      return unless AppConst::CR_PROD.group_incentive_has_packer_roles?

      # partition ids based on contract_worker_packer_roles.part_of_group_incentive_target
      ar = DB[:contract_workers]
           .join(:contract_worker_packer_roles, id: :packer_role_id)
           .where(Sequel[:contract_workers][:id] => attrs[:contract_worker_ids].to_a)
           .select_map([Sequel[:contract_workers][:id], :part_of_group_incentive_target])
      yes, no = ar.partition(&:last)
      attrs[:incentive_target_worker_ids] = yes.map(&:first)
      attrs[:incentive_non_target_worker_ids] = no.map(&:first)
    end

    def add_packer_to_incentive_group(params)
      # 1. Disable incentive_group
      # 2. Clone incentive_group and Add contract_worker
      contract_worker_ids = add_contract_worker_to_group(params)
      update_group_incentive(params[:group_incentive_id], { active: false })
      create_group_incentive({ system_resource_id: params[:id], contract_worker_ids: contract_worker_ids })
    end

    def add_contract_worker_to_group(params)
      arr = Array(group_incentive_contract_worker_ids(params[:group_incentive_id]))
      arr.push(params[:contract_worker_id])
    end

    def apply_changed_role_to_group(contract_worker_id)
      return unless packer_belongs_to_active_incentive_group?(contract_worker_id)

      group_id = contract_worker_active_group_incentive_id(contract_worker_id)
      attrs = find_hash(:group_incentives, group_id).reject { |k, _| k == :id }
      update(:group_incentives, group_id, active: false, from_external_system: false)
      attrs[:from_external_system] = false
      create_group_incentive(attrs)
      # RefreshMesScadaGroupDisplay.call(attrs[:system_resource_id])
      attrs[:system_resource_id]
    end

    def group_incentive_contract_worker_ids(group_incentive_id)
      DB[:group_incentives].where(id: group_incentive_id).get(:contract_worker_ids)
    end

    def contract_worker_id_from_personnel_identifier(identifier)
      DB[:contract_workers]
        .where(personnel_identifier_id: DB[:personnel_identifiers].where(identifier: identifier).get(:id))
        .get(:id)
    end

    # If a worker logs on as an individual, adjust the group they belong to (if they do belong to one)
    def remove_login_from_group(contract_worker_id)
      prev_group_incentive_id = contract_worker_active_group_incentive_id(contract_worker_id)
      return if prev_group_incentive_id.nil?

      remove_packer_from_incentive_group(prev_group_incentive_id, contract_worker_id)
    end

    def remove_packer_from_incentive_group(group_incentive_id, contract_worker_id)
      # 1. Disable incentive_group
      # 2. Clone incentive_group and remove contract_worker
      rec = find_hash(:group_incentives, group_incentive_id)
      contract_worker_ids = Array(rec[:contract_worker_ids])
      contract_worker_ids -= [contract_worker_id]
      update_group_incentive(group_incentive_id, active: false)
      create_group_incentive({ system_resource_id: rec[:system_resource_id], contract_worker_ids: contract_worker_ids }) unless contract_worker_ids.empty?
    end

    def contract_worker_personnel_number(contract_worker_id)
      DB[:contract_workers].where(id: contract_worker_id).get(:personnel_number)
    end

    def production_line_system_resource_ids(production_line_id)
      DB[:plant_resources]
        .join(:system_resources, id: :system_resource_id)
        .where(Sequel[:plant_resources][:id] => production_line_id)
        .select_map(:system_resource_id)
    end
  end
end
