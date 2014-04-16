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

  def create
    raise "Already saved!" unless self.id.nil?

    QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
    INSERT INTO
      users(fname, lname)
    VALUES
      (?, ?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def followed_questions
    QuestionFollower.followed_questions_for_user_id(@id)
  end

  def authored_questions
    Question.find_by_author_id(@id)
  end

  def question_likes
    # TODO: Refactor to call QuestionLikes
    # results = QuestionsDatabase.instance.execute(<<-SQL, self.id)
    # SELECT
    #   *
    # FROM
    #   question_likes
    # WHERE
    #   question_likes.user_id = ?
    # SQL
    # results.map { |result| QuestionLike.new(result) }
  end

  def authored_replies
    Reply.find_by_user_id(@id)
  end

  # def follows
  #   results = SchoolDatabase.instance.execute(<<-SQL, self.id)
  #   SELECT
  #     *
  #   FROM
  #     question_followers
  #   WHERE
  #     question_followers.user_id = ?
  #   SQL
  #   results.map { |result| QuestionFollower.new(result) }
  # end

end


#--------------------------------------


class Question
  attr_accessor :id, :title, :body, :associated_author_id
  def self.all
    results = QuestionsDatabase.instance.execute("SELECT * FROM questions")
    results.empty? ? nil : results.map { |result| Question.new(result) }
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

  def initialize
  end
end

