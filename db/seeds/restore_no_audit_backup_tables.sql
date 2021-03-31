-- Table: audit.logged_actions

-- DROP TABLE audit.logged_actions;

CREATE TABLE audit.logged_actions
(
    event_id bigserial NOT NULL, -- Unique identifier for each auditable event
    schema_name text NOT NULL, -- Database schema audited table for this event is in
    table_name text NOT NULL, -- Non-schema-qualified table name of table event occured in
    relid oid NOT NULL, -- Table OID. Changes with drop/create. Get with 'tablename'::regclass
    session_user_name text, -- Login / session user whose statement caused the audited event
    action_tstamp_tx timestamp with time zone NOT NULL, -- Transaction start timestamp for tx in which audited event occurred
    action_tstamp_stm timestamp with time zone NOT NULL, -- Statement start timestamp for tx in which audited event occurred
    action_tstamp_clk timestamp with time zone NOT NULL, -- Wall clock time at which audited event's trigger call occurred
    transaction_id bigint, -- Identifier of transaction that made the change. May wrap, but unique paired with action_tstamp_tx.
    application_name text, -- Application name set when this audit event occurred. Can be changed in-session by client.
    client_addr inet, -- IP address of client that issued query. Null for unix domain socket.
    client_port integer, -- Remote peer IP port address of client that issued query. Undefined for unix socket.
    client_query text, -- Top-level query that caused this auditable event. May be more than one statement.
    action text NOT NULL, -- Action type; I = insert, D = delete, U = update, T = truncate
    row_data hstore, -- Record value. Null for statement-level trigger. For INSERT this is the new tuple. For DELETE and UPDATE it is the old tuple.
    changed_fields hstore, -- New values of fields changed by UPDATE. Null except for row-level UPDATE events.
    statement_only boolean NOT NULL, -- 't' if audit event is from an FOR EACH STATEMENT trigger, 'f' for FOR EACH ROW
    row_data_id integer, -- CUSTOM: Stores the id of the data row if present
    CONSTRAINT logged_actions_pkey PRIMARY KEY (event_id),
    CONSTRAINT logged_actions_action_check CHECK (action = ANY (ARRAY['I'::text, 'D'::text, 'U'::text, 'T'::text]))
)
    WITH (
        OIDS=FALSE
    );
ALTER TABLE audit.logged_actions
    OWNER TO postgres;
GRANT ALL ON TABLE audit.logged_actions TO postgres;
COMMENT ON TABLE audit.logged_actions
    IS 'History of auditable actions on audited tables, from audit.if_modified_func()';
COMMENT ON COLUMN audit.logged_actions.event_id IS 'Unique identifier for each auditable event';
COMMENT ON COLUMN audit.logged_actions.schema_name IS 'Database schema audited table for this event is in';
COMMENT ON COLUMN audit.logged_actions.table_name IS 'Non-schema-qualified table name of table event occured in';
COMMENT ON COLUMN audit.logged_actions.relid IS 'Table OID. Changes with drop/create. Get with ''tablename''::regclass';
COMMENT ON COLUMN audit.logged_actions.session_user_name IS 'Login / session user whose statement caused the audited event';
COMMENT ON COLUMN audit.logged_actions.action_tstamp_tx IS 'Transaction start timestamp for tx in which audited event occurred';
COMMENT ON COLUMN audit.logged_actions.action_tstamp_stm IS 'Statement start timestamp for tx in which audited event occurred';
COMMENT ON COLUMN audit.logged_actions.action_tstamp_clk IS 'Wall clock time at which audited event''s trigger call occurred';
COMMENT ON COLUMN audit.logged_actions.transaction_id IS 'Identifier of transaction that made the change. May wrap, but unique paired with action_tstamp_tx.';
COMMENT ON COLUMN audit.logged_actions.application_name IS 'Application name set when this audit event occurred. Can be changed in-session by client.';
COMMENT ON COLUMN audit.logged_actions.client_addr IS 'IP address of client that issued query. Null for unix domain socket.';
COMMENT ON COLUMN audit.logged_actions.client_port IS 'Remote peer IP port address of client that issued query. Undefined for unix socket.';
COMMENT ON COLUMN audit.logged_actions.client_query IS 'Top-level query that caused this auditable event. May be more than one statement.';
COMMENT ON COLUMN audit.logged_actions.action IS 'Action type; I = insert, D = delete, U = update, T = truncate';
COMMENT ON COLUMN audit.logged_actions.row_data IS 'Record value. Null for statement-level trigger. For INSERT this is the new tuple. For DELETE and UPDATE it is the old tuple.';
COMMENT ON COLUMN audit.logged_actions.changed_fields IS 'New values of fields changed by UPDATE. Null except for row-level UPDATE events.';
COMMENT ON COLUMN audit.logged_actions.statement_only IS '''t'' if audit event is from an FOR EACH STATEMENT trigger, ''f'' for FOR EACH ROW';
COMMENT ON COLUMN audit.logged_actions.row_data_id IS 'CUSTOM: Stores the id of the data row if present';


-- Index: audit.logged_actions_action_idx

-- DROP INDEX audit.logged_actions_action_idx;

CREATE INDEX logged_actions_action_idx
    ON audit.logged_actions
        USING btree
        (action COLLATE pg_catalog."default");

-- Index: audit.logged_actions_action_tstamp_tx_stm_idx

-- DROP INDEX audit.logged_actions_action_tstamp_tx_stm_idx;

CREATE INDEX logged_actions_action_tstamp_tx_stm_idx
    ON audit.logged_actions
        USING btree
        (action_tstamp_stm);

-- Index: audit.logged_actions_relid_idx

-- DROP INDEX audit.logged_actions_relid_idx;

CREATE INDEX logged_actions_relid_idx
    ON audit.logged_actions
        USING btree
        (relid);

-- Index: audit.logged_actions_row_data_id_idx

-- DROP INDEX audit.logged_actions_row_data_id_idx;

CREATE INDEX logged_actions_row_data_id_idx
    ON audit.logged_actions
        USING btree
        (row_data_id);


-- Table: audit.logged_action_details

-- DROP TABLE audit.logged_action_details;

CREATE TABLE audit.logged_action_details
(
    id bigserial NOT NULL,
    transaction_id bigint DEFAULT txid_current(),
    action_tstamp_tx timestamp with time zone DEFAULT now(),
    user_name text,
    context text,
    route_url text,
    request_ip text,
    CONSTRAINT logged_action_details_pkey PRIMARY KEY (id)
)
    WITH (
        OIDS=FALSE
    );
ALTER TABLE audit.logged_action_details
    OWNER TO postgres;


-- Table: audit.status_logs

-- DROP TABLE audit.status_logs;

CREATE TABLE audit.status_logs
(
    id bigserial NOT NULL,
    transaction_id bigint DEFAULT txid_current(),
    action_tstamp_tx timestamp with time zone DEFAULT now(),
    table_name text,
    row_data_id integer,
    status text,
    comment text,
    user_name text,
    CONSTRAINT status_logs_pkey PRIMARY KEY (id)
)
    WITH (
        OIDS=FALSE
    );
ALTER TABLE audit.status_logs
    OWNER TO postgres;

-- Index: audit.audit_status_logs_table_name_row_data_id_index

-- DROP INDEX audit.audit_status_logs_table_name_row_data_id_index;

CREATE INDEX audit_status_logs_table_name_row_data_id_index
    ON audit.status_logs
        USING btree
        (table_name COLLATE pg_catalog."default", row_data_id);