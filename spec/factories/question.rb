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

FactoryBot.define do
  factory :question, { class: Question } do |f|
    f.question_text 	  { Faker::Hipster.sentence(3) }
    f.position        	{ Faker::Number.number(4) }
    f.question_category { FactoryBot.create(:question_category) }
    f.assignment        { FactoryBot.create(:assignment) }
    f.predefined        { true }
    f.enabled           { true }

    after(:create) do |question|
    end

    trait :with_response do
      after(:create) do |question|
        FactoryBot.create(:response, { question: question })
      end
    end

  end
end
