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

    def contract_worker_id_from_personnel_id(personnel_identifier_id)
      DB[:contract_workers].where(personnel_identifier_id: personnel_identifier_id).get(:id)
    end

    def contract_worker_id_from_personnel_number(personnel_number)
      DB[:contract_workers].where(personnel_number: personnel_number).get(:id)
    end

    # Record login event to system resource logins
    def login_worker(name, params) # rubocop:disable Metrics/AbcSize
      system_resource = params[:system_resource]
      logout_worker(system_resource[:contract_worker_id])
      # Logout_from_group if applicable
      remove_login_from_group(system_resource[:contract_worker_id])

      if exists?(:system_resource_logins, system_resource_id: system_resource[:id], card_reader: system_resource[:card_reader])
        DB[:system_resource_logins]
          .where(system_resource_id: system_resource[:id], card_reader: system_resource[:card_reader])
          .update(contract_worker_id: system_resource[:contract_worker_id],
                  active: true,
                  from_external_system: false,
                  login_at: Time.now,
                  identifier: system_resource[:identifier])
      else
        DB[:system_resource_logins]
          .insert(system_resource_id: system_resource[:id],
                  card_reader: system_resource[:card_reader],
                  contract_worker_id: system_resource[:contract_worker_id],
                  active: true,
                  from_external_system: false,
                  login_at: Time.now,
                  identifier: system_resource[:identifier])
      end

      success_response('Logged on', contract_worker: name)
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

      logout_from_messcada(system_resource_id, contract_worker_id)

      ok_response
    end

    def logout_device(device)
      # 1. find the logged-in worker idS
      contract_worker_ids = DB[:system_resource_logins].where(system_resource_id: system_resource_id, active: true).select_map(:contract_worker_id)

      # 2. Logout
      system_resource_id = DB[:system_resources].where(system_resource_code: device).get(:id)
      DB[:system_resource_logins]
        .where(system_resource_id: system_resource_id)
        .update(last_logout_at: Time.now,
                from_external_system: false,
                active: false)

      contract_worker_ids.each do |contract_worker_id|
        logout_from_messcada(system_resource_id, contract_worker_id)
      end

      ok_response
    end

    def logout_from_messcada(system_resource_id, contract_worker_id)
      opts = DB[:system_resources].where(id: system_resource_id).select(:system_resource_code, :ip_address, :legacy_messcada).first
      return unless opts[:legacy_messcada]

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
      attrs[:contract_worker_ids] = array_for_db_col(attrs[:contract_worker_ids]) if attrs.key?(:contract_worker_ids)
      append_worker_targets(attrs)
      DB[:group_incentives].insert(attrs)
    end

    def update_group_incentive(group_incentive_id, params)
      attrs = params.to_h
      attrs[:contract_worker_ids] = array_for_db_col(attrs[:contract_worker_ids]) if attrs.key?(:contract_worker_ids)
      # calculate targets if active, but ignore if a group is just being made inactive.
      append_worker_targets(attrs) if attrs.key?(:active) && !attrs[:active]

      attrs[:from_external_system] = false
      DB[:group_incentives].where(id: group_incentive_id).update(attrs)
    end

    def append_worker_targets(attrs) # rubocop:disable Metrics/AbcSize
      return unless attrs.key?(:contract_worker_ids)
      return unless AppConst::CR_PROD.group_incentive_has_packer_roles?

      # partition ids based on contract_worker_packer_roles.part_of_group_incentive_target
      ar = DB[:contract_workers]
           .join(:contract_worker_packer_roles, id: :packer_role_id)
           .where(Sequel[:contract_workers][:id] => contract_worker_ids)
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
