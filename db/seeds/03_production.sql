-- PRODUCTION RUN CONTROL
INSERT INTO security_permissions (security_permission)
VALUES ('execute');


INSERT INTO security_groups (security_group_name)
VALUES ('production_run_control');

INSERT INTO security_groups_security_permissions (security_group_id, security_permission_id)
SELECT g.id,
(SELECT id FROM security_permissions WHERE security_permission = 'read')
FROM security_groups g WHERE g.security_group_name = 'production_run_control';
INSERT INTO security_groups_security_permissions (security_group_id, security_permission_id)
SELECT g.id,
(SELECT id FROM security_permissions WHERE security_permission = 'new')
FROM security_groups g WHERE g.security_group_name = 'production_run_control';
INSERT INTO security_groups_security_permissions (security_group_id, security_permission_id)
SELECT g.id,
(SELECT id FROM security_permissions WHERE security_permission = 'edit')
FROM security_groups g WHERE g.security_group_name = 'production_run_control';
INSERT INTO security_groups_security_permissions (security_group_id, security_permission_id)
SELECT g.id,
(SELECT id FROM security_permissions WHERE security_permission = 'delete')
FROM security_groups g WHERE g.security_group_name = 'production_run_control';
INSERT INTO security_groups_security_permissions (security_group_id, security_permission_id)
SELECT g.id,
(SELECT id FROM security_permissions WHERE security_permission = 'execute')
FROM security_groups g WHERE g.security_group_name = 'production_run_control';
