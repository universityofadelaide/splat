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

# Definition of Question
class Question < ApplicationRecord

  belongs_to :question_category
  belongs_to :assignment
  has_many :responses

  validates :question_text, { length: { minimum: 10, maximum: 1000 } }
  validates :position, { presence: true, uniqueness: { scope: %i[assignment question_category] }, allow_nil: true }

  scope :sorted, ->() { order("questions.assignment_id ASC, questions.position ASC") }
  scope :active, ->() { where("questions.enabled = ? or questions.predefined = ?", 1, 0) }

end
