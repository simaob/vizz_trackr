# == Schema Information
#
# Table name: reports
#
#  id                  :bigint           not null, primary key
#  user_id             :bigint           not null
#  team_id             :integer
#  role_id             :integer
#  reporting_period_id :bigint           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class Report < ApplicationRecord
  belongs_to :user
  belongs_to :team, optional: true
  belongs_to :role, optional: true
  belongs_to :reporting_period
  has_many :report_parts, dependent: :destroy
  accepts_nested_attributes_for :report_parts, allow_destroy: true
end
