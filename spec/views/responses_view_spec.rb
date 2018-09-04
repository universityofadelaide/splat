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

# test cases for the learner peer scoring view (responses)
require "rails_helper"

describe "responses/new.html.erb", { type: :view } do

  before(:example) do
    allow(view).to receive(:learner?).and_return(true)
    @assignment = FactoryBot.create(:assignment, :with_question)
    group = FactoryBot.create(:group, :with_users)
    @assignment.groups << group
    @user = group.users.first
  end

  it "displays the assignment questions" do
    @questions = @assignment.questions.active.sorted
    render
    @assignment.questions.active.sorted.each do |q|
      expect(rendered).to have_content(q.question_text)
    end
  end

  it "displays all group member names" do
    @questions = @assignment.questions.active.sorted
    render
    @assignment.groups.each do |g|
      g.users.each do |u|
        expect(rendered).to have_content(u.first_name)
      end
    end
  end

end
