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

# test cases for the instructor export view
require "rails_helper"

describe "assignments/show.html.erb", { type: :view } do

  before(:example) do
    allow(view).to receive(:instructor?).and_return(true)
    @assignment = FactoryBot.create(:assignment)
  end

  it "provides a link to generate the csv file" do
    render
    expect(rendered).to match(%r{<a .*href="\/assignments\/export.csv\?})
  end

  it "displays the assignment questions" do
    render
    @assignment.questions.each do |q|
      expect(rendered).to have_content(q.question_text)
    end
  end

end
