INSERT INTO users (
    username, encrypted_password
) VALUES (
    'admin', 'd033e22ae348aeb5660fc2140aec35850c4da997' -- 'admin'
);

INSERT INTO flags (
    name, description
) VALUES (
    'admin', 'Access to administration areas and functions.'
);

INSERT INTO user_groups (
    name, description
) VALUES (
    'admins', 'Administrators'
);
INSERT INTO user_groups (
    name, description
) VALUES (
    'moderators', 'Moderators'
);
INSERT INTO user_groups (
    name, description
) VALUES (
    'members', 'Regular Members'
);
INSERT INTO user_groups (
    name, description
) VALUES (
    'guests', 'Guests'
);

INSERT INTO user_groups_flags (
    user_group_id,
    flag_id
) SELECT
    ( SELECT id FROM user_groups WHERE name = 'admins' ),
    id
FROM
    flags
;

INSERT INTO users_groups (
    user_id, user_group_id
) VALUES (
    ( SELECT id FROM users WHERE username = 'admin' ),
    ( SELECT id FROM user_groups WHERE name = 'admins' )
);


INSERT INTO severities ( name, ordinal ) VALUES ( 'Low', 1 );
INSERT INTO severities ( name, ordinal ) VALUES ( 'Normal', 2 );
INSERT INTO severities ( name, ordinal ) VALUES ( 'High', 3 );
INSERT INTO severities ( name, ordinal ) VALUES ( 'Critical', 4 );

INSERT INTO statuses ( name ) VALUES ( 'New' );
INSERT INTO statuses ( name ) VALUES ( 'Acknowledged' );
INSERT INTO statuses ( name ) VALUES ( 'Assigned' );
INSERT INTO statuses ( name ) VALUES ( 'Closed' );

INSERT INTO resolutions ( name ) VALUES ( 'Unresolved' );
INSERT INTO resolutions ( name ) VALUES ( 'Fixed' );
INSERT INTO resolutions ( name ) VALUES ( 'Invalid' );
INSERT INTO resolutions ( name ) VALUES ( 'Dismissed' );
INSERT INTO resolutions ( name ) VALUES ( 'Duplicate' );
INSERT INTO resolutions ( name ) VALUES ( 'Unreproducible' );

INSERT INTO ticket_groups ( name, description ) VALUES ( 'Uncategorized', 'Uncategorized tickets.' );

INSERT INTO configuration ( key, value ) VALUES ( 'akismet_key', '' );
INSERT INTO configuration ( key, value ) VALUES ( 'initial_status', 'New' );
INSERT INTO configuration ( key, value ) VALUES ( 'initial_resolution', 'Unresolved' );
