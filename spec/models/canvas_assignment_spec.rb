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

RSpec.describe CanvasAssignment, { type: :model } do

  before(:example) do
    @user = FactoryBot.create(:user)
    allow(User).to(receive(:find_by).and_return(@user))
    @paf_calculator = double
    allow(@paf_calculator).to(receive(:calculate).and_return(1.0))
    @canvas_service = double
    @canvas_assignment = CanvasAssignment.new("1", "2", @paf_calculator, @canvas_service)
    @grading_standard = {
      grading_scheme: [
        { name: "A", value: 0.8 },
        { name: "B", value: 0.5 },
        { name: "C", value: 0.0 }
      ]
    }
    allow(@canvas_service).to(receive(:get_students).and_return([{ id: "1" }]))
  end

  describe "#apply_paf_grades" do

    it "raises UnsupportedGradeTypeError if grading type unsupported" do
      allow(@canvas_service).to(receive(:get_assignment).and_return({ grading_type: "unsupported" }))
      expect { @canvas_assignment.apply_paf_grades(3) } .to raise_error(UnsupportedGradeTypeError)
    end

    it "raises exception if CanvasService throws one" do
      allow(@canvas_service).to(receive(:get_assignment).and_return({ grading_type: "points" }))
      allow(@canvas_service).to(receive(:get_submissions_for_assignment).and_raise("Error"))
      expect { @canvas_assignment.apply_paf_grades(3) } .to raise_error("Error")
    end

    it "empty updates don't trigger CanvasService call" do
      allow(@canvas_service).to(receive(:get_assignment).and_return({ grading_type: "points" }))
      allow(@canvas_service).to(receive(:get_submissions_for_assignment).and_return([]))
      allow(@canvas_service).to(receive(:get_students).and_return([]))
      expect(@canvas_service).to(receive(:update_grades).exactly(0).times)
      @canvas_assignment.apply_paf_grades(3)
    end

    it "calls CanvasService update_grades if there are updates" do
      submissions = [
        {
          sis_user_id:    "a",
          user_id:        "123",
          assignment_id:  2,
          score:          10,
          grade:          20,
          attempt:        nil,
          workflow_state: "graded"
        }
      ]
      allow(@canvas_service).to(receive(:get_assignment).and_return({ grading_type: "points" }))
      allow(@canvas_service).to(receive(:get_submissions_for_assignment).and_return(submissions))
      expect(@canvas_service).to(receive(:update_grades).exactly(1).times)
      @canvas_assignment.apply_paf_grades(3)
    end

    it "processes letter_grade, grading standard set on assignment" do
      submissions = [
        {
          sis_user_id:    "a",
          user_id:        "123",
          assignment_id:  2,
          score:          5,
          grade:          "C",
          attempt:        nil,
          workflow_state: "graded"
        }
      ]
      allow(@canvas_service).to(receive(:get_assignment).and_return({ grading_type: "letter_grade", points_possible: 10, grading_standard_id: 1 }))
      allow(@canvas_service).to(receive(:get_submissions_for_assignment).and_return(submissions))
      allow(@canvas_service).to(receive(:get_grading_standard_course).and_return(@grading_standard))
      expect(@canvas_service).to(receive(:get_grading_standard_course).exactly(1).times)
      expect(@canvas_service).to(receive(:update_grades).exactly(1).times)
      @canvas_assignment.apply_paf_grades(3)
    end

    it "processes letter_grade, grading standard set on course" do
      submissions = [
        {
          sis_user_id:    "a",
          user_id:        "123",
          assignment_id:  2,
          score:          5,
          grade:          "C",
          attempt:        nil,
          workflow_state: "graded"
        }
      ]
      allow(@canvas_service).to(receive(:get_assignment).and_return({ grading_type: "letter_grade", points_possible: 10 }))
      allow(@canvas_service).to(receive(:get_course)).and_return({ grading_standard_id: 1 })
      allow(@canvas_service).to(receive(:get_submissions_for_assignment).and_return(submissions))
      allow(@canvas_service).to(receive(:get_grading_standard_course).and_return(@grading_standard))
      expect(@canvas_service).to(receive(:get_course).exactly(1).times)
      expect(@canvas_service).to(receive(:get_grading_standard_course).exactly(1).times)
      expect(@canvas_service).to(receive(:get_grading_standard_account).exactly(0).times)
      expect(@canvas_service).to(receive(:update_grades).exactly(1).times)
      @canvas_assignment.apply_paf_grades(3)
    end

    it "processes letter_grade, grading standard set on account" do
      submissions = [
        {
          sis_user_id:    "a",
          user_id:        "123",
          assignment_id:  2,
          score:          5,
          grade:          "C",
          attempt:        nil,
          workflow_state: "graded"
        }
      ]
      allow(@canvas_service).to(receive(:get_assignment).and_return({ grading_type: "letter_grade", points_possible: 10 }))
      allow(@canvas_service).to(receive(:get_course)).and_return({ grading_standard_id: 1 })
      allow(@canvas_service).to(receive(:get_submissions_for_assignment).and_return(submissions))
      allow(@canvas_service).to(receive(:get_grading_standard_course).and_raise("Error"))
      allow(@canvas_service).to(receive(:get_grading_standard_account).and_return(@grading_standard))
      expect(@canvas_service).to(receive(:get_course).exactly(1).times)
      expect(@canvas_service).to(receive(:get_grading_standard_course).exactly(1).times)
      expect(@canvas_service).to(receive(:get_grading_standard_account).exactly(1).times)
      expect(@canvas_service).to(receive(:update_grades).exactly(1).times)
      @canvas_assignment.apply_paf_grades(3)
    end

    it "processes letter_grade calculates correct new grade" do
      submissions = [
        {
          sis_user_id:    "a",
          user_id:        "123",
          assignment_id:  2,
          score:          5,
          grade:          "C",
          attempt:        nil,
          workflow_state: "graded"
        }
      ]
      allow(@paf_calculator).to(receive(:calculate).and_return(1.5))
      allow(@canvas_service).to(receive(:get_assignment).and_return({ grading_type: "letter_grade", points_possible: 10, grading_standard_id: 1 }))
      allow(@canvas_service).to(receive(:get_submissions_for_assignment).and_return(submissions))
      allow(@canvas_service).to(receive(:get_grading_standard_course).and_return(@grading_standard))
      allow(@canvas_service).to(receive(:get_students).and_return([{ id: "123" }]))
      expect(@canvas_service).to(receive(:get_grading_standard_course).exactly(1).times)
      expect(@canvas_service).to(receive(:update_grades).with("1", 3, [{ student_id: "123", grade: "B" }]))
      @canvas_assignment.apply_paf_grades(3)
    end

    it "blanks students without responses" do
      submissions = [
        {
          sis_user_id:    "a",
          user_id:        "123",
          assignment_id:  2,
          score:          5,
          grade:          "C",
          attempt:        nil,
          workflow_state: "graded"
        }
      ]
      allow(@paf_calculator).to(receive(:calculate).and_return(1.5))
      allow(@canvas_service).to(receive(:get_assignment).and_return({ grading_type: "letter_grade", points_possible: 10, grading_standard_id: 1 }))
      allow(@canvas_service).to(receive(:get_submissions_for_assignment).and_return(submissions))
      allow(@canvas_service).to(receive(:get_grading_standard_course).and_return(@grading_standard))
      allow(@canvas_service).to(receive(:get_students).and_return([{ id: "123" }, { id: "321" }]))
      expect(@canvas_service).to(receive(:get_grading_standard_course).exactly(1).times)
      expect(@canvas_service).to(receive(:update_grades).with("1", 3, [{ student_id: "123", grade: "B" }, { student_id: "321", grade: nil }]))
      @canvas_assignment.apply_paf_grades(3)
    end
  end

end
