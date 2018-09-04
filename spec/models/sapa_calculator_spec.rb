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

RSpec.describe SAPACalculator, { type: :model } do

  let(:precision) { 0.00000000001 }

  context "three users and one question" do
    it "calculates scores with one user responding" do
      assignment = FactoryBot.create(:assignment, :with_question)
      question = assignment.questions.first
      group = FactoryBot.create(:group, :with_users)
      assignment.groups << group
      users = group.users
      3.times do |i|
        FactoryBot.create(:response, { assignment: assignment, from_user: users[0], for_user: users[i], score: 20, question: question })
      end

      sapa_calc = SAPACalculator.new(assignment)
      expect(sapa_calc.calculate(users[0].id)).to be_within(precision).of(1.0) # with no other data just accept the user's score
      expect(sapa_calc.calculate(users[1].id)).to be_nil # since this user has not responded they have no sapa score
      expect(sapa_calc.calculate(users[2].id)).to be_nil
    end
  end

  context "no responders" do
    it "returns nil for each user's score" do
      @assignment = FactoryBot.create(:assignment, :with_question)
      @group = FactoryBot.create(:group, :with_users)
      @assignment.groups << @group
      sapa_calc = SAPACalculator.new(@assignment)
      expect(sapa_calc.calculate(@group.users[0].id)).to eq(nil)
      expect(sapa_calc.calculate(@group.users[1].id)).to eq(nil)
      expect(sapa_calc.calculate(@group.users[2].id)).to eq(nil)
    end
  end

  context "three users and five questions" do
    before(:all) do
      @assignment = FactoryBot.create(:assignment)
      @group = FactoryBot.create(:group, :with_users)
      @assignment.groups << @group

      5.times do
        question = FactoryBot.create(:question)
        @assignment.questions << question
      end
      @users = @group.users
      Response.where({ assignment: @assignment }).destroy_all
      @assignment.questions.each do |question|
        @users[0..-2].each_with_index do |from_user, _index| # note: last user is skipped
          @users.each do |for_user|
            score = 20
            FactoryBot.create(:response, { assignment: @assignment, from_user: from_user, for_user: for_user, score: score, question: question })
          end
        end
      end
    end

    it "calculates scores with not all users responding" do
      @sapa_calc = SAPACalculator.new(@assignment)
      expect(@sapa_calc.calculate(@users[0].id)).to be_within(precision).of(1.0)
      expect(@sapa_calc.calculate(@users[1].id)).to be_within(precision).of(1.0)
      expect(@sapa_calc.calculate(@users[2].id)).to be_nil
    end

    # extend the User class so we can have a user who values their contribution more
    # highly than their peers
    class User

      attr_accessor :sapa_weighting

      def peer_score(user)
        if user.id == id
          20 + (@sapa_weighting || 0)
        else
          20
        end
      end

    end

    context "calculates scores with all users responding" do
      before(:all) do
        # build assignment data with 5 questions and each of three users giving scores for three users
        @users = @group.users
        # destroy data left over from previous case
        Response.where({ assignment: @assignment }).destroy_all

        @assignment.questions.each do |question|
          @users.each do |from_user|
            from_user.sapa_weighting = 1 if from_user.id == @users.first.id # first user gives themself more points
            from_user.sapa_weighting = -1 if from_user.id == @users.last.id # last user gives themself less points
            @users.each do |for_user|
              score = from_user.peer_score(for_user)
              FactoryBot.create(:response, { assignment: @assignment, from_user: from_user, for_user: for_user, score: score, question: question })
            end
          end
        end
        @sapa_calc = SAPACalculator.new(@assignment, true)
      end

      # the first user gave themself 21 whereas the average from others was 20
      # the last user gave themself 19 whereas the average from others was 20
      it "calculates scores for user 1" do
        expect(@sapa_calc.calculate(@users[0].id)).to be_within(precision).of(1.05)
      end

      it "calculates scores for user 2" do
        expect(@sapa_calc.calculate(@users[1].id)).to be_within(precision).of(1.0)
      end

      it "calculates scores for user 3" do
        expect(@sapa_calc.calculate(@users[2].id)).to be_within(precision).of(0.95)
      end
    end
  end

end
