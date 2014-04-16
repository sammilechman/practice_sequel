CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  fname VARCHAR(255) NOT NULL,
  lname VARCHAR(255) NOT NULL
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  body VARCHAR(255) NOT NULL,
  associated_author_id INTEGER NOT NULL,
  FOREIGN KEY (associated_author_id) REFERENCES users(id)
);

CREATE TABLE question_followers (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL
);

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  subject_question_id INTEGER NOT NULL,
  parent_reply_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  body TEXT NOT NULL,
  FOREIGN KEY (subject_question_id) REFERENCES questions(id),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (parent_reply_id) REFERENCES replies(id)
);

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES user(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO
  users (fname, lname)
VALUES
  ('Albert', 'Einstein'),
  ('Kurt', 'Godel'),
  ('Chris', 'Cowell'),
  ('Sam', 'Milechman');

INSERT INTO
  questions (title, body, associated_author_id)
VALUES
("How do I type with two hands?", "I'm having trouble typing with two hands, how do I do it?", 4),
("What's your favorite pie?", "I love pumpkin pies, what is your favorite?", 3);

INSERT INTO
  question_followers (user_id, question_id)
VALUES
  (1,2), (1,2), (3,1), (4,1), (4,2);

INSERT INTO
  replies (subject_question_id, parent_reply_id, user_id, body)
VALUES
  (1, 1, 1, "What a stupid question.");