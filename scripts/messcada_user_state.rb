# frozen_string_literal: true

# What this script does:
# ----------------------
# Takes a user name and surname and displays all relevant login state for that user.
#
# Reason for this script:
# -----------------------
# Debugging.
#
# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb MesScadaUserState name surname
# Live  : RACK_ENV=production ruby scripts/base_script.rb MesScadaUserState name surname
# Dev   : ruby scripts/base_script.rb MesScadaUserState name, surname
# Optionally add ` y` to the end to also check the old MES system state.
#
class MesScadaUserState < BaseScript # rubocop:disable Metrics/ClassLength
  def run # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    @name = args.first
    @surname = args[1]
    @old_mes = args[2] && args[2] =~ /y/i
    raise ArgumentError, 'First name and surname was not provided' unless @name
    raise ArgumentError, 'Surname was not provided' unless @surname

    old_mes_connection
    prep_ids
    return failed_response("No contract worker for #{@name} #{@surname}") if @contract_worker_id.nil?
    return failed_response("No kromco_legacy person for #{@name} #{@surname}") if @kr_people_id.nil?
    return failed_response("No old MES person for #{@name} #{@surname}") if @old_mes && @old_people_id.nil?

    workers
    groups
    logins
    # messcada_group_data
    messcada_people_group_members
    people

    success_response('MesScada user state')
  end

  private

  def old_mes_connection
    return unless @old_mes

    @old_db = Sequel.connect('postgres://postgres:postgres@172.16.16.15/kromco_mes')
    @old_db.extension :pg_array
    @old_db.extension :pg_json
    # @old_db.extension :pg_hstore
    @old_db.extension :pg_inet
  end

  def prep_ids
    @contract_worker_id = DB[:contract_workers].where(first_name: @name, surname: @surname).get(:id)
    @kr_people_id = DB[Sequel[:kromco_legacy][:people]].where(first_name: @name, last_name: @surname).get(:id)
    @old_people_id = @old_db[:people].where(first_name: @name, last_name: @surname).get(:id) if @old_mes
  end

  def workers
    query = <<~SQL
      SELECT c.id, c.first_name, c.surname, c.personnel_number, p.identifier, c.active, c.from_external_system AS ext,
      r.packer_role, r.part_of_group_incentive_target AS tgt_incentive, c.updated_at
      FROM contract_workers c
      LEFT JOIN contract_worker_packer_roles r ON r.id = c.packer_role_id
      LEFT JOIN personnel_identifiers p ON p.id = c.personnel_identifier_id
      WHERE c.id = ?
    SQL
    puts "\nNSpack worker"
    table = UtilityFunctions.make_text_table(DB[query, @contract_worker_id].all, times: [:updated_at], rjust: [:id])
    puts table.join("\n")
  end

  def groups
    query = <<~SQL
      SELECT id, system_resource_id AS sys_res_id, contract_worker_ids, active,
      created_at, from_external_system AS ext, incentive_target_worker_ids AS target_ids, incentive_non_target_worker_ids AS non_target_ids
      FROM group_incentives
      WHERE #{@contract_worker_id} = ANY(contract_worker_ids)
      ORDER BY created_at DESC LIMIT 10
    SQL
    puts "\nNSpack group incentives"
    table = UtilityFunctions.make_text_table(DB[query].all, times: [:created_at], rjust: %i[id sys_res_id])
    puts table.join("\n")
  end

  def logins
    query = <<~SQL
      SELECT l.id, l.system_resource_id AS res_id, s.system_resource_code AS code, l.card_reader AS reader, l.contract_worker_id AS wkr_id,
      c.first_name, c.surname, l.identifier,
      r.packer_role AS role, r.part_of_group_incentive_target AS tgt,
      l.login_at, l.last_logout_at, l.from_external_system AS ext, l.active, l.updated_at
      FROM system_resource_logins l
      JOIN contract_workers c ON c.id = l.contract_worker_id
      LEFT JOIN contract_worker_packer_roles r ON r.id = c.packer_role_id
      JOIN system_resources s ON s.id = l.system_resource_id
      WHERE l.contract_worker_id = ?
      ORDER BY l.updated_at DESC LIMIT 10
    SQL
    puts "\nNSpack logins"
    table = UtilityFunctions.make_text_table(DB[query, @contract_worker_id].all, times: %i[updated_at login_at last_logout_at], rjust: %i[id res_id wkr_id])
    puts table.join("\n")
  end

  # def messcada_group_data
  #   query = <<~SQL
  #     SELECT id, reader_id AS reader, module_name, group_id, group_date, from_external_system AS ext, created_at, updated_at
  #     FROM kromco_legacy.messcada_group_data ORDER BY updated_at DESC LIMIT 3
  #   SQL
  #   puts "\nMesScada groups"
  #   table = UtilityFunctions.make_text_table(DB[query].all, times: %i[created_at updated_at], rjust: %i[id])
  #   puts table.join("\n")
  # end

  def members_query(prefix = 'kromco_legacy.')
    <<~SQL
      SELECT id, reader_id AS rdr, rfid, industry_number, group_id, group_date,
      module_name, last_name, first_name, person_role AS role, #{prefix.empty? ? '' : 'from_external_system AS ext,'}
      updated_at
      FROM #{prefix}messcada_people_group_members p
      WHERE p.first_name = ?
        AND p.last_name = ?
      ORDER BY p.updated_at DESC LIMIT 10
    SQL
  end

  def messcada_people_group_members
    puts "\nMesScada group members"
    table = UtilityFunctions.make_text_table(DB[members_query, @name, @surname].all, times: %i[updated_at], rjust: %i[id])
    puts table.join("\n")
    return unless @old_mes

    puts "\nOLD MES: MesScada group members"
    table = UtilityFunctions.make_text_table(@old_db[members_query(''), @name, @surname].all, times: %i[updated_at], rjust: %i[id])
    puts table.join("\n")
  end

  def people_query(prefix = 'kromco_legacy.')
    <<~SQL
      SELECT p.id, p.first_name, p.last_name, p.industry_number, p.is_logged_on, p.logged_onto_module, p.logged_onoff_time, p.reader_id,
      p.selected_role AS role, #{prefix.empty? ? '' : 'p.from_external_system AS ext,'} p.updated_at
      FROM #{prefix}people p
      WHERE p.first_name = ?
        AND p.last_name = ?
    SQL
  end

  def people
    puts "\nMesScada people"
    table = UtilityFunctions.make_text_table(DB[people_query, @name, @surname].all, times: %i[logged_onoff_time updated_at], rjust: %i[id])
    puts table.join("\n")
    return unless @old_mes

    puts "\nOLD MES: MesScada people"
    table = UtilityFunctions.make_text_table(@old_db[people_query(''), @name, @surname].all, times: %i[logged_onoff_time updated_at], rjust: %i[id])
    puts table.join("\n")
  end
end
