# == Schema Information
#
# Table name: contracts
#
#  id         :bigint           not null, primary key
#  name       :string
#  project_id :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  budget     :float
#  alias      :string           default([]), is an Array
#  start_date :date
#  end_date   :date
#  aasm_state :string
#
require 'csv'

class Contract < ApplicationRecord
  include AASM
  include HasStateMachine

  aasm do
    state :proposal, initial: true
    state :live
    state :finished
    event :start do
      transitions from: :proposal, to: :live
    end
    event :finish do
      transitions from: :live, to: :finished
    end
    event :restart do
      transitions from: :finished, to: :live
    end
  end

  belongs_to :project
  has_many :report_parts, dependent: :destroy
  has_many :full_reports
  has_many :non_staff_costs, dependent: :destroy

  validates_uniqueness_of :name
  delegate :is_billable?, to: :project

  def alias_list
    self.alias.join(', ')
  end

  def alias_list= list
    self.alias = list.split(',').map(&:strip).uniq.sort
  end

  def total_burn with_projections = false
    relevant_reports = if with_projections
                         full_reports
                       else
                         full_reports.where(report_estimated: false)
                       end
    relevant_reports.sum(:cost) + non_staff_costs.sum(:cost)
  end

  def burn_percentage with_projections = false
    return nil unless budget

    ((total_burn(with_projections) / budget) * 100).round(2)
  end

  def completion_burn
    return 0 unless budget && percent_complete

    (budget * percent_complete / 100).round(2)
  end

  def completion_burn_percentage
    return nil unless budget && percent_complete

    ((completion_burn / budget) * 100).round(2)
  end

  def full_name
    "#{name} [#{project.name}#{(' - internal' unless project.is_billable?)}]"
  end

  def linear_income
    return nil unless budget && start_date && end_date

    months = (end_date.year * 12 + end_date.month) - (start_date.year * 12 + start_date.month) + 1

    (budget / months).to_f.round(2)
  end

  def self.to_csv
    CSV.generate(headers: true) do |csv|
      csv << ['Project', 'Contract', 'Start date', 'End Date',
              'Budget (EUR)', 'Internal?', 'Status']
      all.each do |contract|
        csv << [
          contract.project&.name,
          contract.name,
          contract.start_date&.strftime('%d/%m/%Y'),
          contract.end_date&.strftime('%d/%m/%Y'),
          contract.budget,
          !contract.project.is_billable?,
          contract.aasm_state.humanize
        ]
      end
    end
  end
end
