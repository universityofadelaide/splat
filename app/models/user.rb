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

# model which represents the users which are imported from CSV
class User < ApplicationRecord

  cattr_accessor :current_user_id

  has_many :group_users, { class_name: "GroupUser" } # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :groups, { through: :group_users }
  has_many :assignments, { through: :assignment_users }

  validates :lms_id, { uniqueness: true, presence: true }

  scope :sorted, -> { includes(:group_users).order("lms_id") }

  # This method will return all the peers of the loggned in user's group for that assignment
  def assignment_group(assignment)
    return nil if assignment.blank?

    user_group = self.groups.merge(assignment.groups)
    return nil if user_group.count.zero?
    raise "User is in multiple groups on assignment #{ assignment.name } id #{ assignment.id }" unless user_group.count == 1

    return user_group.first
  end

end
