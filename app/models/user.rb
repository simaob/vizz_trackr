# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  name                   :string
#  team_id                :integer
#  role_id                :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  admin                  :boolean          default(FALSE)
#  rate_id                :bigint
#  dedication             :float            default(0.74), not null
#  active                 :boolean          default(TRUE)
#

class User < ApplicationRecord
  paginates_per 60
  attr_accessor :skip_password_validation
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable
  belongs_to :team, optional: true
  belongs_to :role, optional: true
  belongs_to :rate, optional: true
  has_many :reports, dependent: :destroy
  has_many :report_parts, through: :reports
  has_many :reporting_periods, through: :reports
  has_many :contracts, through: :report_parts
  has_many :projects, through: :contracts
  has_many :full_reports, dependent: :destroy

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  validates :email, uniqueness: true
  validates :name, presence: true

  def name_with_state
    str = [name]
    str << '[acc: disabled]' unless active?
    str.join(' ')
  end

  def current_report
    reporting_period = ReportingPeriod.active_period
    return nil unless reporting_period

    reports.find_by(reporting_period_id: reporting_period.id) || reports
      .create(reporting_period_id: reporting_period.id, estimated: true, team_id: team_id)
  end

  def quick_contracts
    return [] unless reports.any?

    reports.order(created_at: :desc)
      .first.contracts.order(:name).distinct
  end

  def gravatar_url(size = 50)
    gravatar_id = Digest::MD5.hexdigest(email.downcase)
    "https://secure.gravatar.com/avatar/#{gravatar_id}.png?s=#{size}"
  end

  def destroy
    update(active: false) if active
  end

  def active_for_authentication?
    super && active
  end

  def self.search query
    return all unless query

    where('name ilike ? OR email ilike ?', "%#{query}%", "%#{query}%")
  end

  private

  def password_required?
    return false if skip_password_validation

    super
  end
end
