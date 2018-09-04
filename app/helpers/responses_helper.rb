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

# Response Helper
module ResponsesHelper

  def response_question_list
    response_questions = []
    students = []

    @user.assignment_group(@assignment).users.each do |user|
      student = { id: user.id, first_name: user.first_name, last_name: user.last_name, score: "" }
      students << student
    end

    @questions.select(:question_category_id).distinct.map do |assignment_question|
      question_with_students = []
      questions = @questions.where({ question_category_id: assignment_question.question_category_id })

      questions.each do |question|
        question_with_student = { question: question, students: students }
        question_with_students << question_with_student
      end
      response_question = { category_name: assignment_question.question_category.name, student_questions: question_with_students }
      response_questions << response_question
    end

    return response_questions
  end

end
