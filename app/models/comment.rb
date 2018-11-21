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

# Definition of user comments class
class Comment < ApplicationRecord

  has_paper_trail

  belongs_to :from_user, { class_name: "User", foreign_key: "user_id" } # rubocop:disable Rails/InverseOf
  belongs_to :assignment
  validates  :comments, { length: { maximum: 3000, too_long: "3000 characters is the maximum allowed" } }

end
