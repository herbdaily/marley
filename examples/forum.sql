CREATE TABLE tags (id integer PRIMARY KEY,user_id integer, tag text);
CREATE INDEX tag_user_id on tags(user_id);
CREATE INDEX tag_tag on tags(tag);
CREATE UNIQUE INDEX tag_tag_user_id on tags(user_id,tag);

CREATE TABLE message_tags ( id integer PRIMARY KEY, message_id integer, tag_id integer);
CREATE INDEX msg_tag_id on message_tags(tag_id);
CREATE INDEX tag_msg_id on message_tags(message_id);

CREATE TABLE messages (
    id integer PRIMARY KEY,
    message_type text,
    author_id integer,
    recipients text, 
    thread_id integer,
    parent_id integer,
    date_created datetime,
    date_updated datetime,
    title text,
    message clob
);
CREATE INDEX message on messages(message);
CREATE INDEX message_author on messages(author_id);
CREATE INDEX message_parent on messages(parent_id);
CREATE INDEX message_thread on messages(thread_id);
CREATE INDEX message_title on messages(title);
CREATE INDEX message_type on messages(message_type);
CREATE INDEX thread on messages(thread_id);

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  user_type TEXT,
  date_created datetime,
  name TEXT,
  email TEXT,
  pw_hash TEXT,
  active boolean default true,
  description clob);
CREATE INDEX users_active on users(active);
CREATE UNIQUE INDEX users_email on users(email);
CREATE UNIQUE INDEX users_name on users(name);
CREATE INDEX users_user_type on users(user_type);
