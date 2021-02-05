# frozen_string_literal: true

# What this script does:
# ----------------------
# Takes all MesScada robots that are set to do group incentive or individual incentive and creates a job for each one that makes a TCP connection to clear logins on the GUI
#
# Reason for this script:
# -----------------------
# At the end of a shift a job logs all workers out in the database.
# For MesScada ITPCs, they also need to be told that the user has been logged out so that they can update their GUI.
#
# To run:
# -------
# Debug : DEBUG=y RACK_ENV=production ruby scripts/base_script.rb ClearMesScadaLogins
# Live  : RACK_ENV=production ruby scripts/base_script.rb ClearMesScadaLogins
# Dev   : ruby scripts/base_script.rb ClearMesScadaLogins
#
class MesScadaLoginState < BaseScript
  def run
    workers
    groups
    logins
    messcada_group_data
    messcada_people_group_members
    people

    success_response('MesScada login states')
  end

  private

  def workers
    query = <<~SQL
      SELECT c.id, c.first_name, c.surname, c.personnel_number, p.identifier, c.active, c.from_external_system AS ext,
      r.packer_role, r.part_of_group_incentive_target AS tgt_incentive, c.updated_at
      FROM contract_workers c
      LEFT JOIN contract_worker_packer_roles r ON r.id = c.packer_role_id
      LEFT JOIN personnel_identifiers p ON p.id = c.personnel_identifier_id
      ORDER BY c.updated_at DESC LIMIT 3
    SQL
    puts "\nNSpack workers"
    table = UtilityFunctions.make_text_table(DB[query].all, times: [:updated_at], rjust: [:id])
    puts table.join("\n")
  end

  def groups
    query = <<~SQL
      SELECT id, system_resource_id AS sys_res_id, contract_worker_ids, active,
      created_at, from_external_system AS ext, incentive_target_worker_ids AS target_ids, incentive_non_target_worker_ids AS non_target_ids
      FROM group_incentives ORDER BY created_at DESC LIMIT 3
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
      ORDER BY l.updated_at DESC LIMIT 3
    SQL
    puts "\nNSpack logins"
    table = UtilityFunctions.make_text_table(DB[query].all, times: %i[updated_at login_at last_logout_at], rjust: %i[id res_id wkr_id])
    puts table.join("\n")
  end

  def messcada_group_data
    query = <<~SQL
      SELECT id, reader_id AS reader, module_name, group_id, group_date, from_external_system AS ext, created_at, updated_at
      FROM kromco_legacy.messcada_group_data ORDER BY updated_at DESC LIMIT 3
    SQL
    puts "\nMesScada groups"
    table = UtilityFunctions.make_text_table(DB[query].all, times: %i[created_at updated_at], rjust: %i[id])
    puts table.join("\n")
  end

  def messcada_people_group_members
    query = <<~SQL
      SELECT id, reader_id AS rdr, rfid, industry_number, group_id, group_date,
      module_name, last_name, first_name, person_role AS role, from_external_system AS ext,
      updated_at
      FROM kromco_legacy.messcada_people_group_members p ORDER BY p.updated_at DESC LIMIT 3
    SQL
    puts "\nMesScada group members"
    table = UtilityFunctions.make_text_table(DB[query].all, times: %i[updated_at], rjust: %i[id])
    puts table.join("\n")
  end

  def people
    query = <<~SQL
      SELECT p.id, p.first_name, p.last_name, p.industry_number, p.is_logged_on, p.logged_onto_module, p.logged_onoff_time, p.reader_id,
      p.selected_role AS role, p.from_external_system AS ext, p.updated_at
      FROM kromco_legacy.people p ORDER BY p.updated_at DESC LIMIT 30
    SQL
    puts "\nMesScada people"
    table = UtilityFunctions.make_text_table(DB[query].all, times: %i[logged_onoff_time updated_at], rjust: %i[id])
    puts table.join("\n")
  end
end
