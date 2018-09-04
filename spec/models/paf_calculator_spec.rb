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

RSpec.describe PAFCalculator, { type: :model } do

  let(:precision) { 0.00000000001 }

  before(:example) do
    @assignment = FactoryBot.create(:assignment, :with_question)
    @question = @assignment.questions.active.sorted.first
    @group = FactoryBot.create(:group, :with_users)
    @assignment.groups << @group
    @users = @group.users
  end

  context "three users and one question" do
    it "calculates scores" do

      3.times do |i|
        FactoryBot.create(:response, { assignment: @assignment, from_user: @users[0], for_user: @users[i], score: 20, question: @question })
      end

      paf_calc = PAFCalculator.new(@assignment)
      expect(paf_calc.calculate(@users[0].id)).to be_within(precision).of(0.6)
      expect(paf_calc.calculate(@users[1].id)).to be_within(precision).of(0.6)
      expect(paf_calc.calculate(@users[2].id)).to be_within(precision).of(0.6)
    end
  end

  context "three users and five questions" do
    it "handles the case with no responders for the group" do
      5.times do
        question = FactoryBot.create(:question)
        @assignment.questions << question
      end

      paf_calc = PAFCalculator.new(@assignment)
      expect(paf_calc.calculate(@users[0].id)).to eq(nil)
      expect(paf_calc.calculate(@users[1].id)).to eq(nil)
      expect(paf_calc.calculate(@users[2].id)).to eq(nil)
    end

    it "calculates scores with all users responding" do
      # build assignment data with 5 questions and each of three users giving scores for three users
      assignment = FactoryBot.create(:assignment)
      assignment.groups << @group
      num_users = @group.users.count

      5.times do |i_question|
        question = FactoryBot.create(:question)
        assignment.questions << question

        num_users.times do |i_from|
          num_users.times do |i_for|
            FactoryBot.create(:response, {
                                assignment: assignment, from_user: @users[i_from],
              for_user: @users[i_for], score: (i_for + 1) * 12 + (i_question * 5), question: question
                              })
          end
        end
      end

      paf_calc = PAFCalculator.new(assignment)
      # The scores below are calculated using the PAF formula which can be found here https://myuni.adelaide.edu.au/courses/24800/pages/self-and-peer-learning-and-assessment-tool-splat-staff-user-guide
      expect(paf_calc.calculate(@users[0].id)).to be_within(precision).of(0.66)
      expect(paf_calc.calculate(@users[1].id)).to be_within(precision).of(1.02)
      expect(paf_calc.calculate(@users[2].id)).to be_within(precision).of(1.38)
    end
  end

  context "two groups of three users and 1 question" do
    it "calculates scores" do
      # add a second group to the assignment
      @assignment.groups << FactoryBot.create(:group, :with_users)
      @assignment.groups.each do |grp|
        grp.users.each do |user|
          FactoryBot.create(:response, { assignment: @assignment, from_user: grp.users.first, for_user: user, score: 20, question: @question })
        end
        paf_calc = PAFCalculator.new(@assignment, true)
        grp.users.each do |user|
          expect(paf_calc.calculate(user.id)).to be_within(precision).of(0.6)
        end

      end
    end
  end
end
