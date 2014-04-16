require 'singleton'
require 'sqlite3'

class QuestionsDatabase < SQLite3::Database
  include Singleton
  def initialize
    super("questions.db")
    self.results_as_hash = true
    self.type_translation = true
  end
end


#--------------------------------------


class User

  attr_accessor :id, :fname, :lname
  def self.all
    results = QuestionsDatabase.instance.execute("SELECT * FROM users")
    results.empty? ? nil : results.map { |result| User.new(result) }
  end

  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      users
    WHERE
      users.id = ?
    SQL
    results.empty? ? nil : User.new(results.first)
  end

  def self.find_by_name(fname, lname)
    results = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
    SELECT
      *
    FROM
      users
    WHERE
      users.fname = ? AND users.lname = ?
    SQL
    results.empty? ? nil : User.new(result.first)
  end

  def initialize(options = {})
    @id = options["id"]
    @fname = options["fname"]
    @lname = options["lname"]
  end

  def save
    if self.id.nil?
      self.create
    else
      self.update
    end
  end

  def create
    raise "Already saved!" unless self.id.nil?

    QuestionsDatabase.instance.execute(<<-SQL, self.fname, self.lname)
    INSERT INTO
      users(fname, lname)
    VALUES
      (?, ?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    QuestionsDatabase.instance.execute(<<-SQL, id: self.id, fname: self.fname, lname: self.lname)
    UPDATE
      users
    SET
      fname = :fname, lname = :lname
    WHERE
      users.id = :id
    SQL
  end

  def average_karma
    results = QuestionsDatabase.instance.execute(<<-SQL, author_id: self.id)
    SELECT
      COUNT(ql.question_id)/CAST(COUNT(DISTINCT(q.id)) AS FLOAT) "Avg Num Likes"
    FROM
      questions q
    LEFT OUTER JOIN
      question_likes ql
    ON
      (ql.question_id = q.id)
    WHERE
      :author_id = q.associated_author_id
    SQL
    results.first
  end

  def followed_questions
    QuestionFollower.followed_questions_for_user_id(@id)
  end

  def authored_questions
    Question.find_by_author_id(@id)
  end

  def liked_questions
    QuestionLike.liked_questions_for_user_id(@id)
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end

end


#--------------------------------------


class Question
  attr_accessor :id, :title, :body, :associated_author_id
  def self.all
    results = QuestionsDatabase.instance.execute("SELECT * FROM questions")
    results.empty? ? nil : results.map { |result| Question.new(result) }
  end

  def self.most_liked(n)
    QuestionLike.most_liked_questions(n)
  end

  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      questions
    WHERE
      questions.id = ?
    SQL
    results.empty? ? nil : Question.new(results.first)
  end

  def self.most_followed(n)
    QuestionFollower.most_followed_questions(n)
  end

  def self.find_by_author_id(associated_author_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, associated_author_id)
    SELECT
      *
    FROM
      questions
    WHERE
      questions.associated_author_id = ?
    SQL
    results.empty? ? nil : results.map { |result| Question.new(result) }
  end

  def initialize(options = {})
    @id = options["id"]
    @title = options["title"]
    @body = options["body"]
    @associated_author_id = options["associated_author_id"]
  end

  def followers
    QuestionFollower.followers_for_question_id(@id)
  end

  def author
    User.find_by_id(@associated_author_id)
  end

  def replies
    Reply.find_by_question_id(@id)
  end

  def create
    raise "Already saved!" unless self.id.nil?

    QuestionsDatabase.instance.execute(<<-SQL, title, body, associated_author_id)
    INSERT INTO
      questions(title, body, associated_author_id)
    VALUES
      (?, ?, ?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def likers
    QuestionLike.likers_for_question_id(@id)
  end

  def num_likes
    QuestionLike.num_likes_for_question_id(@id)
  end

  def followers

  end

end


#--------------------------------------


class Reply
  attr_accessor :id, :subject_question_id, :parent_reply_id, :user_id, :body
  def self.all
    results = QuestionsDatabase.instance.execute("SELECT * FROM replies")
    results.empty? ? nil : results.map { |result| Reply.new(result) }
  end

  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      replies
    WHERE
      replies.id = ?
    SQL
    results.empty? ? nil : Reply.new(results.first)
  end

  def self.find_by_parent_reply_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      replies
    WHERE
      replies.parent_reply_id = ?
    SQL

    results.empty? ? nil : results.map { |result| Reply.new(result) }
  end

  def self.find_by_question_id(subject_question_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, subject_question_id)
    SELECT
      *
    FROM
      replies
    WHERE
      replies.subject_question_id = ?
    SQL

    results.empty? ? nil : results.map { |result| Reply.new(result) }
  end

  def self.find_by_user_id(user_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    SELECT
      *
    FROM
      replies
    WHERE
      replies.user_id = ?
    SQL
    results.empty? ? nil : results.map { |result| Reply.new(result) }
  end

  def initialize(options = {})
    @id = options["id"]
    @subject_question_id = options["subject_question_id"]
    @parent_reply_id = options["parent_reply_id"]
    @user_id = options["user_id"]
    @body = options["body"]
  end

  def create
    raise "Already saved!" unless self.id.nil?

    QuestionsDatabase.instance.execute(<<-SQL, subject_question_id, parent_reply_id, user_id, body)

    INSERT INTO
      users(subject_question_id, parent_reply_id, user_id, body)
    VALUES
      (?, ?, ?, ?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def author
    User.find_by_id(@user_id)
  end

  def question
    Question.find_by_id(@subject_question_id)
  end

  def parent_reply
    Reply.find_by_id(@parent_reply_id)
  end

  def child_replies
    Reply.find_by_parent_reply_id(@id)
  end

end


#--------------------------------------


class QuestionFollower
  attr_accessor :id, :user_id, :question_id

  def self.followers_for_question_id(question_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      u.*
    FROM
      users u
    JOIN
      question_followers q
    ON
      (q.user_id = u.id)
    WHERE
      q.question_id = ?
    SQL
    results.empty? ? nil : results.map { |result| User.new(result) }
  end

  def self.followed_questions_for_user_id(user_id)
    # TODO: Refactor to join to question_follwers
    results = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    SELECT
      q.*
    FROM
      questions q
    JOIN
      question_followers qf
    ON
      (qf.question_id = q.id)
    WHERE
      qf.user_id = ?
    SQL
    results.empty? ? nil : results.map { |result| Question.new(result) }
  end

  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      question_followers
    WHERE
      question_followers.id = ?
    SQL
    results.empty? ? nil : QuestionFollower.new(result.first)
  end

  def self.most_followed_questions(n)
    results = QuestionsDatabase.instance.execute(<<-SQL, n)
    SELECT
      q.*
    FROM
      questions q
    JOIN
      question_followers qf
    ON
      (qf.question_id = q.id)
    GROUP BY
      q.id
    ORDER BY
      COUNT(qf.question_id) DESC LIMIT 0, ?
    SQL
    results.empty? ? nil : results.map { |result| Question.new(result) }
  end

  def initialize(options = {})
    @id = options["id"]
    @user_id = options["user_id"]
    @question_id = options["question_id"]
  end

end


#--------------------------------------


class QuestionLike

  def self.find_by_id(id)
    results = QuestionsDatabase.instance.execute(<<-SQL, id)
    SELECT
      *
    FROM
      question_likes
    WHERE
      question_likes.id = ?
    SQL
    results.empty? ? nil : results.map { |result| QuestionLike.new(result) }
  end

  def self.likers_for_question_id(question_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      u.*
    FROM
      question_likes ql
    JOIN
      users u
    ON
      (u.id = ql.user_id)
    WHERE
      ql.question_id = ?
    SQL
  end

  def self.num_likes_for_question_id(question_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT
      COUNT(*)
    FROM
      question_likes ql
    JOIN
      users u
    ON
      u.id = ql.user_id
    WHERE
      ql.question_id = ?
    SQL
  end

  def self.liked_questions_for_user_id(user_id)
    results = QuestionsDatabase.instance.execute(<<-SQL, user_id)
    SELECT
      q.*
    FROM
      question_likes ql
    JOIN
      questions q
    ON
      q.id = ql.question_id
    WHERE
      ql.user_id = ?
    SQL
    results.empty? ? nil : results.map { |result| Question.new(result) }
  end

  def self.most_liked_questions(n)
    results = QuestionsDatabase.instance.execute(<<-SQL, n)
    SELECT
      q.*
    FROM
      question_likes ql
    JOIN
      questions q
    ON
      q.id = ql.question_id
    GROUP BY
      q.id
    ORDER BY
      COUNT(ql.question_id) DESC LIMIT 0, ?
    SQL
  end

  def initialize(options={})
    @id = options["id"]
    @user_id = options["user_id"]
    @question_id = options["question_id"]
  end
end

