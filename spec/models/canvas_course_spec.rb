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

require "rails_helper"

RSpec.describe CanvasCourse, { type: :model } do

  before(:example) do
    @canvas_service = double
    @activerecord = double
    @assignment1 = FactoryBot.build(:assignment, { lms_assignment_id: 1, id: 1 })
    @assignment2 = FactoryBot.build(:assignment, { lms_assignment_id: 2, id: 2 })
    @assignment3 = FactoryBot.build(:assignment, { lms_assignment_id: 3, id: 3 })
  end

  describe "#get_assignments" do

    it "throw exception if CanvasService throws one" do
      allow(@canvas_service).to(receive(:get_assignments).and_raise("Error"))
      expect { CanvasCourse.get_assignments("1", @canvas_service) } .to raise_error("Error")
    end

    it "returns all assignments" do
      assignments = [
        @assignment1,
        @assignment2
      ]

      allow(Assignment).to(receive(:all).and_return(@activerecord))
      allow(@activerecord).to(receive(:find_each).and_yield(@assignment3))
      allow(@canvas_service).to(receive(:get_assignments).and_return(assignments))
      result = CanvasCourse.get_assignments("1", @canvas_service)
      expect(result.count).to be 2
    end

    it "returns all assignments but SPLAT" do
      assignments = [
        @assignment1,
        @assignment2
      ]
      allow(@canvas_service).to(receive(:get_assignments).and_return(assignments))
      allow(Assignment).to(receive(:all).and_return(@activerecord))
      allow(@activerecord).to(receive(:find_each).and_yield(@assignment1))
      result = CanvasCourse.get_assignments("1", @canvas_service)
      expect(result.count).to be 1
    end

  end

end
