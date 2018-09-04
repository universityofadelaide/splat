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

# Factories for responses from the Canvas API
FactoryBot.define do

  factory :canvas_assignment, { class: OpenStruct } do
    skip_create
    sequence(:id)    { |n| n }
    sequence(:name)  { Faker::Lorem.sentence(3) }
    points_possisble { 5 }
  end

  # https://canvas.instructure.com/doc/api/custom_gradebook_columns.html
  factory :canvas_column_datum, { class: OpenStruct } do
    skip_create
    content { Faker::Lorem.sentence(3) }
    user_id { rand(1000) }
  end

  # https://canvas.instructure.com/doc/api/custom_gradebook_columns.html
  factory :canvas_custom_gradebook_column, { class: OpenStruct } do
    skip_create
    sequence(:id) { |n| n }
    title         { Faker::Lorem.sentence(3) }
    read_only     { [true, false].sample }
  end

  factory :canvas_student, { class: OpenStruct } do
    skip_create
    sequence(:id) { |n| n }
    sortable_name { Faker::Name }
    email         { Faker::Internet.email }
    login_id      { Faker::Number.number(6) }
  end

  factory :canvas_assignment_submission, { class: OpenStruct } do
    skip_create
    sequence(:assignment_id) { |n| n }
    score                    { rand(0..5) } # should be within assignment.points_possisble if assignment exists
    user_id                  { FactoryBot.create(:canvas_student).id }
    late                     { false }
    grade                    { %w[P F].sample }
    sequence(:attempt)       { |n| n }
    workflow_state           { %w[graded submitted].sample }
  end

end
