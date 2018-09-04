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
  factory :group, { class: Group } do |f|
    f.group_set_name	  { Faker::Hipster.sentence(3) }
    f.name	            { Faker::Hipster.sentence(2) }
    f.sequence(:lms_id) { |n| FactoryBot.create(:lms_id) + n.to_s } # when we make an API calls from LTI to LMS this would be used.

    trait :with_users do
      after(:create) do |group|
        3.times { FactoryBot.create(:group_user, { group: group }) }
      end
    end

  end
end
