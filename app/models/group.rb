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

# model which represents the groups which are imported from CSV
class Group < ApplicationRecord

  has_many :group_users, { class_name: "GroupUser" } # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :users, { through: :group_users }
  has_one  :assignment_groups, { class_name: "AssignmentGroup" } # rubocop:disable Rails/HasManyOrHasOneDependent
  has_one  :assignment, { through: :assignment_groups }

  validates :name, :group_set_name, :lms_id, { presence: true }

end
