-- Generate a mobilesetup user that can configure mobile devices.

-- USER
INSERT INTO users (login_name, user_name, password_hash, permission_tree) VALUES('mobilesetup', 'MobileSetup', '$2a$12$D1BcIba34KKffy8B/3gSOeUFns9ziQCJO5XiMB9CcfD/orELUQSZ.', '{"Nspack": {"password": {"can_be_changed_by_user": false}}}');

-- USER ACCESS TO RMD UTILITIES MENU
INSERT INTO programs_users (user_id, program_id, security_group_id)
VALUES ((SELECT id FROM users WHERE login_name = 'mobilesetup'),
  (SELECT id FROM programs WHERE program_name = 'Utilities' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'RMD')),
  (SELECT id FROM security_groups g WHERE g.security_group_name = 'basic'));

-- USER PERMISSION TO ACCESS RMD SETUP
INSERT INTO program_functions_users (user_id, program_function_id)
VALUES ((SELECT id FROM users WHERE login_name = 'mobilesetup'),
  (SELECT id FROM program_functions WHERE program_function_name = 'Setup Device' AND program_id = (SELECT id FROM programs WHERE program_name = 'Utilities' AND functional_area_id = (SELECT id FROM functional_areas WHERE functional_area_name = 'RMD'))));
