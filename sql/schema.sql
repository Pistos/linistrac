CREATE TABLE users (
    id SERIAL,
    username VARCHAR( 32 ) NOT NULL UNIQUE,
    realname VARCHAR( 64 ),
    encrypted_password VARCHAR( 128 ) NOT NULL,
    PRIMARY KEY( id )
);

CREATE TABLE flags (
    id SERIAL,
    name VARCHAR( 64 ) NOT NULL UNIQUE,
    description VARCHAR( 256 ),
    PRIMARY KEY( id )
);

CREATE TABLE user_groups (
    id SERIAL,
    name VARCHAR( 64 ) NOT NULL UNIQUE,
    description VARCHAR( 256 ),
    PRIMARY KEY( id )
);

CREATE TABLE user_groups_flags (
    user_group_id INTEGER NOT NULL REFERENCES user_groups( id ),
    flag_id INTEGER NOT NULL REFERENCES flags( id ),
    PRIMARY KEY( user_group_id, flag_id )
);

CREATE TABLE users_groups (
    user_id INTEGER NOT NULL REFERENCES users( id ),
    user_group_id INTEGER NOT NULL REFERENCES user_groups( id ),
    PRIMARY KEY( user_id, user_group_id )
);

-- -----------------

CREATE TABLE severities (
    id SERIAL,
    name VARCHAR( 128 ) NOT NULL UNIQUE,
    ordinal INTEGER NOT NULL UNIQUE,
    PRIMARY KEY( id )
);
CREATE TABLE statuses (
    id SERIAL,
    name VARCHAR( 128 ) NOT NULL UNIQUE,
    description VARCHAR( 1024 ),
    PRIMARY KEY( id )
);
CREATE TABLE resolutions (
    id SERIAL,
    name VARCHAR( 128 ) NOT NULL UNIQUE,
    description VARCHAR( 1024 ),
    PRIMARY KEY( id )
);

CREATE TABLE ticket_groups (
    id SERIAL,
    name VARCHAR( 256 ) NOT NULL,
    description VARCHAR( 4096 ) NOT NULL,
    PRIMARY KEY( id )
);

CREATE TABLE tickets (
    id SERIAL,
    time_created TIMESTAMP NOT NULL DEFAULT NOW(),
    time_updated TIMESTAMP NOT NULL DEFAULT NOW(),
    severity_id INTEGER REFERENCES severities( id ),
    priority INTEGER NOT NULL DEFAULT 0,
    creator_id INTEGER REFERENCES users( id ),
    group_id INTEGER NOT NULL REFERENCES ticket_groups( id ),
    status_id INTEGER NOT NULL REFERENCES statuses( id ),
    resolution_id INTEGER REFERENCES resolutions( id ),
    title VARCHAR( 256 ) NOT NULL CONSTRAINT title_length CHECK ( LENGTH( title ) > 3 ),
    description VARCHAR( 8192 ) NOT NULL CONSTRAINT description_length CHECK ( LENGTH( description ) > 3 ),
    tags VARCHAR( 1024 ),
    PRIMARY KEY( id )
);