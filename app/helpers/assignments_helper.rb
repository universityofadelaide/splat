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

# Assignment Helper
module AssignmentsHelper

  # This method generates a list of categories from the current assignment
  def list_categories
    QuestionCategory.all.map do |category|
      "category_#{ category.id }: \"#{ category.name }\""
    end.join(",\n")
  end

  # This method generates a list of questions from the current assignment grouped by category
  def list_questions
    "{" +
      QuestionCategory.all.map do |category|
        "category_#{ category.id }:[" +
          @assignment.questions.where({ question_category_id: category.id }).order(:position).map do |question|
            # JSON can't handle \n -> replace it with \\n
            "{question_text: \"#{ question.question_text.gsub(/\n/, "\\n") }\", predefined: #{ question.predefined }, id: #{ question.id }, enabled: #{ question.enabled } }"
          end.join(",\n") +
          "]"
      end.join(",\n") +
      "}"
  end

end
