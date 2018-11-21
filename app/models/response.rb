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

# Definition of user response class
class Response < ApplicationRecord

  has_paper_trail

  belongs_to :from_user, { class_name: "User", foreign_key: "from_user_id" } # rubocop:disable Rails/InverseOf
  belongs_to :for_user, { class_name: "User", foreign_key: "for_user_id" } # rubocop:disable Rails/InverseOf
  belongs_to :question
  belongs_to :assignment

  validates  :score, { presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 } }

end
