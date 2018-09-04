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

RSpec.describe Assignment, { type: :model } do

  it "has a valid factory" do
    assignment = FactoryBot.create(:assignment)
    expect(assignment).to be_valid
  end

  it "has a valid factory trait with_question" do
    assignment = FactoryBot.create(:assignment, :with_question)
    expect(assignment.questions.count).to eql(1)
  end

  context "column validations" do

    before(:context) do
      @bob = FactoryBot.create(:user)
      @jane = FactoryBot.create(:user)
      @users = [@bob, @jane]
      @required_parameters = %i[name lms_id]
      @create_params = FactoryBot.create(:assignment).attributes.symbolize_keys.except(:id) # remove id to avoid DB duplicates
      generate_assignment_data
    end

    it "creates when all columns are specified" do
      new_assignment = Assignment.new(@create_params)
      expect(new_assignment).to be_valid
      new_assignment.save
    end

    it "does not create when name is missing" do
      new_assignment = Assignment.new(@create_params.except(:name))
      expect(new_assignment).not_to be_valid
      new_assignment.save
    end

    it "does not create when lms_id is missing" do
      new_assignment = Assignment.new(@create_params.except(:lms_id))
      expect(new_assignment).not_to be_valid
      new_assignment.save
    end

    it "validates required parameters" do
      new_assignment = Assignment.new(@create_params.slice(*@required_parameters))
      expect(new_assignment).to be_valid
      new_assignment.save
    end
  end

  context "exporting to csv" do

    before(:example) do
      @bob = FactoryBot.create(:user, { lms_id: "a" })
      @jane = FactoryBot.create(:user, { lms_id: "b" })
      @tmart = FactoryBot.create(:user, { lms_id: "c" })
      @users = [@bob, @jane, @tmart]
      @required_parameters = %i[name lms_id]
      @create_params = FactoryBot.create(:assignment).attributes.symbolize_keys.except(:id) # remove id to avoid DB duplicates
      generate_assignment_data(@tmart.id)
    end

    it "exports the correct number of headers" do
      assignment = Assignment.new(@create_params)
      assignment.groups << FactoryBot.create(:group, :with_users)
      assignment.groups << FactoryBot.create(:group, :with_users)
      # add an extra user to the last group
      FactoryBot.create(:group_user, { group: assignment.groups.last })
      exported_rows = CSV.parse(assignment.to_csv)
      header_row = exported_rows.first

      expect(header_row.count).to eq(Assignment::HEADERS.length - 1 + assignment.groups.last.users.size)
    end

    it "exports the correct headers" do
      assignment = FactoryBot.create(:assignment)
      assignment.groups << FactoryBot.create(:group, :with_users)
      exported_rows = CSV.parse(assignment.to_csv)
      headers = exported_rows.first
      longest_record = exported_rows.map(&:count).max

      template_user_header = Assignment::HEADERS[-1]
      number_of_user_headers = longest_record - (Assignment::HEADERS.count - 1)
      user_headers = (1..number_of_user_headers).map do |user_number|
        template_user_header.sub("[n]", user_number.to_s)
      end

      expected_headers = Assignment::HEADERS[0..-2] + user_headers
      expect(headers).to eq(expected_headers)
    end

    it "generates the correct number of rows in the export" do
      result = CSV.parse(@assignment.to_csv)
      expect(result.count).to eq(@users.count + 1) # extra row for header
    end

    it "generates the correct PAF score with 2 decimal places in the export" do
      paf_cal = PAFCalculator.new(@assignment)
      allow(paf_cal).to receive(:calculate).and_return(1.343678, 1.7896)
      allow(PAFCalculator).to receive(:new).and_return(paf_cal)
      result = CSV.parse(@assignment.to_csv)
      expect(result[1][5]).to eq("1.34")
      expect(result[2][5]).to eq("1.79")
    end

    it "generates the correct SAPA score with 2 decimal places in the export" do
      sapa_cal = SAPACalculator.new(@assignment)
      allow(sapa_cal).to receive(:calculate).and_return(1.0001, 1.0051)
      allow(SAPACalculator).to receive(:new).and_return(sapa_cal)
      result = CSV.parse(@assignment.to_csv)
      expect(result[1][7]).to eq("1.00")
      expect(result[2][7]).to eq("1.01")
    end

    it "displays the user number within a group in sequence counting from 1" do
      result = CSV.parse(@assignment.to_csv)
      expect(result[1][4]).to eq(1.to_s)
      expect(result[2][4]).to eq(2.to_s)
    end

    it "adds CSV_UNUSED_FLAG for unused score" do
      result = CSV.parse(@assignment.to_csv)
      expect(result[3][10]).to include(Assignment::CSV_UNUSED_FLAG)
      expect(result[3][11]).to include(Assignment::CSV_UNUSED_FLAG)
      expect(result[3][12]).to include(Assignment::CSV_UNUSED_FLAG)
    end

    it "generates the correct total score for each user" do
      result = CSV.parse(@assignment.to_csv)
      expected_user_total = @assignment.questions.count * 100
      expected_grand_total = @assignment.questions.count * @users.count * 100
      total = 0
      n = @users.count
      (1..n).each do |i|
        user_total = 0
        (10..9 + n).each do |j|
          user_total += (result[i][j]).to_i
          total += (result[i][j]).to_i
        end
        expect(user_total).to eq(expected_user_total)
      end
      expect(total).to eq(expected_grand_total)
    end

  end

  context "calculates students stats for assignment" do

    before(:example) do
      generate_assignment_with_single_response
    end

    it "calculates total number of students" do
      expect(@assignment.number_of_students_total).to eq(2)
    end

    it "calculates total number of students that completed the assignment" do
      expect(@assignment.number_of_students_completed).to eq(1)
    end

    it "returns lms_ids of students that have not completed the assignment" do
      expected_output = [@jane.lms_id]
      expect(@assignment.not_responded_user_lms_ids).to eq(expected_output)
    end

  end

  context "clears responses" do
    before(:example) do
      generate_assignment_with_single_response
    end

    it "deletes responses for user" do
      expect(@assignment.responses.count).to eq(1)
      @assignment.clear_responses(@bob.id)
      expect(@assignment.responses.count).to eq(0)
    end
  end

  def generate_assignment_data(unused_for_user_id=nil)
    @assignment = Assignment.create(@create_params)
    @question = FactoryBot.create(:question, { assignment_id: @assignment.id })
    group = FactoryBot.create(:group)
    @assignment.groups << group
    group.users << @users
    @users.each do |u1|
      remaining_score = 100
      count = 0
      @users.each do |u2|
        count += 1
        response = Response.new
        response.assignment = @assignment
        response.question = @question
        response.for_user = u1
        response.from_user = u2
        response.score =
          if count < @users.count
            rand(0..remaining_score)
          else
            remaining_score
          end
        remaining_score -= response.score
        response.score_used = false if u1.id == unused_for_user_id
        response.save
      end
    end
  end

  def generate_assignment_with_single_response
    @bob = FactoryBot.create(:user)
    @jane = FactoryBot.create(:user)
    @users = [@bob, @jane]
    @required_parameters = %i[name lms_id]
    @assignment = FactoryBot.create(:assignment)
    @question = FactoryBot.create(:question, { assignment_id: @assignment.id })
    group = FactoryBot.create(:group)
    @assignment.users << @users
    @assignment.groups << group
    group.users << @users
    response = Response.new
    response.assignment = @assignment
    response.question = @question
    response.for_user = @jane
    response.from_user = @bob
    response.score = 100
    response.save
  end

end
