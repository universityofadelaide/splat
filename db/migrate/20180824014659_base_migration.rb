# Copyright (C) 2018 The University of Adelaide
#
# This file is part of SPLAT - Self & Peer Learning Assessment Tool.
#
# SPLAT - Self & Peer Learning Assessment Tool is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SPLAT - Self & Peer Learning Assessment Tool is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with SPLAT - Self & Peer Learning Assessment Tool.  If not, see <http://www.gnu.org/licenses/>.
#

class BaseMigration < ActiveRecord::Migration[5.1]

  # The largest text column available in all supported RDBMS is
  # 1024^3 - 1 bytes, roughly one gibibyte.  We specify a size
  # so that MySQL will use `longtext` instead of `text`.  Otherwise,
  # when serializing very large objects, `text` might not be big enough.
  TEXT_BYTES = 1_073_741_823

  def self.up # rubocop:disable  Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    # Table creation
    unless table_exists?(:assignment_groups)
      create_table "assignment_groups", { force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" } do |t|
        t.integer "assignment_id"
        t.integer "group_id"
        t.string "created_by"
        t.string "updated_by"
        t.datetime "created_at", { null: false }
        t.datetime "updated_at", { null: false }
        t.index ["assignment_id"], { name: "index_assignment_groups_on_assignment_id" }
        t.index ["group_id"], { name: "index_assignment_groups_on_group_id" }
      end
    end

    unless table_exists?(:assignment_questions)
      create_table "assignment_questions", { force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" } do |t|
        t.integer "assignment_id"
        t.integer "question_id"
        t.string "created_by"
        t.string "updated_by"
        t.datetime "created_at", { null: false }
        t.datetime "updated_at", { null: false }
        t.index ["assignment_id"], { name: "index_assignment_questions_on_assignment_id" }
        t.index ["question_id"], { name: "index_assignment_questions_on_question_id" }
      end
    end

    unless table_exists?(:assignment_users)
      create_table "assignment_users", { force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" } do |t|
        t.integer "assignment_id"
        t.integer "user_id"
        t.string "created_by"
        t.string "updated_by"
        t.datetime "created_at", { null: false }
        t.datetime "updated_at", { null: false }
        t.index %w[assignment_id user_id], { name: "index_assignment_users_on_assignment_id_and_user_id", unique: true }
      end
    end

    unless table_exists?(:assignments)
      create_table "assignments", { force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" } do |t|
        t.string "name"
        t.text "instructions"
        t.datetime "start_date"
        t.datetime "end_date"
        t.string "lms_id"
        t.string "lms_assignment_id"
        t.string "course_name"
        t.string "created_by"
        t.datetime "created_at", { null: false }
        t.string "updated_by"
        t.datetime "updated_at", { null: false }
        t.text "lti_launch_params"
        t.string "source_assignment_id"
      end
    end

    unless table_exists?(:comments)
      create_table "comments", { force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" } do |t|
        t.text "comments"
        t.integer "assignment_id"
        t.integer "user_id"
        t.string "created_by"
        t.string "updated_by"
        t.datetime "created_at", { null: false }
        t.datetime "updated_at", { null: false }
      end
    end

    unless table_exists?(:group_users)
      create_table "group_users", { force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" } do |t|
        t.integer "user_id"
        t.integer "group_id"
        t.string "created_by"
        t.string "updated_by"
        t.datetime "created_at", { null: false }
        t.datetime "updated_at", { null: false }
        t.index ["group_id"], { name: "index_group_users_on_group_id" }
        t.index ["user_id"], { name: "index_group_users_on_user_id" }
      end
    end

    unless table_exists?(:groups)
      create_table "groups", { force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" } do |t|
        t.string "group_set_name"
        t.string "name"
        t.string "lms_id"
        t.datetime "created_at", { null: false }
        t.datetime "updated_at", { null: false }
        t.string "created_by"
        t.string "updated_by"
      end
    end

    unless table_exists?(:question_categories)
      create_table "question_categories", { force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" } do |t|
        t.string "name"
        t.string "created_by"
        t.string "updated_by"
        t.datetime "created_at", { null: false }
        t.datetime "updated_at", { null: false }
        t.integer "position"
      end
    end

    unless table_exists?(:question_templates)
      create_table "question_templates", { force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" } do |t| # rubocop:disable Rails/CreateTableWithTimestamps
        t.integer "question_category_id"
        t.string "question_text"
        t.integer "position"
        t.string "created_by"
        t.string "updated_by"
        t.index ["question_category_id"], { name: "index_question_templates_on_question_category_id" }
      end
    end

    unless table_exists?(:questions)
      create_table "questions", { force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" } do |t|
        t.text "question_text"
        t.integer "position"
        t.string "created_by"
        t.string "updated_by"
        t.integer "question_category_id"
        t.datetime "created_at", { null: false }
        t.datetime "updated_at", { null: false }
        t.integer "assignment_id"
        t.boolean "predefined"
        t.boolean "enabled"
      end
    end

    unless table_exists?(:responses)
      create_table "responses", { force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" } do |t|
        t.integer "question_id"
        t.string "created_by"
        t.string "updated_by"
        t.integer "from_user_id"
        t.integer "for_user_id"
        t.integer "score"
        t.boolean "score_used", { default: true }
        t.datetime "created_at", { null: false }
        t.datetime "updated_at", { null: false }
        t.integer "assignment_id"
        t.text "comments"
      end
    end

    unless table_exists?(:sessions)
      create_table "sessions", { force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" } do |t|
        t.string "session_id", { null: false }
        t.text "data"
        t.datetime "created_at", { null: false }
        t.datetime "updated_at", { null: false }
        t.index ["session_id"], { name: "index_sessions_on_session_id", unique: true }
        t.index ["updated_at"], { name: "index_sessions_on_updated_at" }
      end
    end

    unless table_exists?(:users)
      create_table "users", { force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" } do |t|
        t.string "lms_id"
        t.string "login_id"
        t.string "last_name"
        t.string "first_name"
        t.datetime "created_at", { null: false }
        t.datetime "updated_at", { null: false }
        t.string "created_by"
        t.string "updated_by"
      end
    end

    unless table_exists?(:versions)
      create_table :versions, { options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci" } do |t|
        t.string   :item_type, { null: false, limit: 191 }
        t.integer  :item_id,   { null: false }
        t.string   :event,     { null: false }
        t.string   :whodunnit
        t.text     :object, { limit: TEXT_BYTES }

        # Known issue in MySQL: fractional second precision
        # -------------------------------------------------
        #
        # MySQL timestamp columns do not support fractional seconds unless
        # defined with "fractional seconds precision". MySQL users should manually
        # add fractional seconds precision to this migration, specifically, to
        # the `created_at` column.
        # (https://dev.mysql.com/doc/refman/5.6/en/fractional-seconds.html)
        #
        # MySQL users should also upgrade to rails 4.2, which is the first
        # version of ActiveRecord with support for fractional seconds in MySQL.
        # (https://github.com/rails/rails/pull/14359)
        #
        if ActiveRecord::Base.connection.adapter_name == "Mysql2"
          t.datetime :created_at, { limit: 6 }
        else
          t.datetime :created_at
        end
      end
      add_index :versions, %i[item_type item_id]
    end

    unless table_exists?(:notifications)
      create_table :notifications do |t|
        t.integer :message_id
        t.integer :user_id
        t.string  :created_by
        t.string  :updated_by
        t.timestamps
      end
    end

    unless table_exists?(:messages)
      create_table :messages do |t|
        t.string  :subject
        t.text    :body
        t.integer :assignment_id
        t.string  :created_by
        t.string  :updated_by
        t.timestamps
      end
    end

    User.current_user_id = "Admin"

    # Question category creation
    teamwork_category = QuestionCategory.find_or_create_by({ name: "Teamwork and Communication Skills", position: 1, created_by: "Admin", updated_by: "Admin" })
    career_category = QuestionCategory.find_or_create_by({ name: "Career and Leadership Readiness", position: 2, created_by: "Admin", updated_by: "Admin" })
    self_awareness_category = QuestionCategory.find_or_create_by({ name: "Self Awareness and Emotional Intelligence", position: 3, created_by: "Admin", updated_by: "Admin" })

    # Question creation
    QuestionTemplate.find_or_create_by(
      {
        question_text: "The group member communicated effectively with other members in the group.",
        position: 1, question_category_id: teamwork_category.id
      }
    )
    QuestionTemplate.find_or_create_by(
      {
        question_text: "The group member completed their fair share of the group's work in a timely manner.",
        position: 2, question_category_id: teamwork_category.id
      }
    )

    QuestionTemplate.find_or_create_by(
      {
        question_text: "The group member was punctual and regularly attended meetings and other group activities.",
        position: 1, question_category_id: career_category.id
      }
    )
    QuestionTemplate.find_or_create_by(
      {
        question_text: "The group member was well prepared for group activities.",
        position: 2, question_category_id: career_category.id
      }
    )

    QuestionTemplate.find_or_create_by(
      {
        question_text: "The group member genuinely considered and (where relevant) took on board other member's perspectives.",
        position: 1, question_category_id: self_awareness_category.id
      }
    )
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration, "Can't roll back base migration"
  end

end
