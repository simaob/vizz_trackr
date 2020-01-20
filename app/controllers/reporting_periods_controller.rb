class ReportingPeriodsController < ApplicationController
  before_action :set_reporting_period, only: [:show, :edit, :update, :reports,
                                              :announce, :destroy, :update_state]
  authorize_resource

  # GET /reporting_periods
  # GET /reporting_periods.json
  def index
    @reporting_periods = ReportingPeriod.order(date: :desc)
      .includes(:full_reports)
    @data = ::Api::Charts::ReportingPeriod.new(@reporting_periods)
      .reporting_periods_cost_data
  end

  # GET /reporting_periods/1
  # GET /reporting_periods/1.json
  def show
    @total_reporters = @reporting_period.full_reports
      .select(:user_id).distinct.count
    @total_project_reports = @reporting_period.total_contracts_reported
    @reports = @reporting_period.reports
      .joins(:user).order('users.name ASC')
  end

  def announce
    post_response = Slack::SlackApiHelper.post('chat.postMessage', @reporting_period.announcement)
    if post_response['ok']
      redirect_to reporting_periods_url, notice: 'Announcement successfully sent to slack!'
    else
      redirect_to reporting_periods_url, alert: 'Failed to announce, please try again later.'
    end
  end

  def reports
    respond_to do |format|
      format.html do
        @roles = Role.order(:name)
        @reports = @reporting_period.full_reports
          .includes(:contract, :project).order(:user_name)

        @reports = @reports.for_role(params[:role_id]) if params[:role_id].present?
      end
      format.csv do
        send_data @reporting_period.to_csv,
                  type: 'csv',
                  filename: "report-#{@reporting_period.display_name}.csv"
      end
    end
  end

  # GET /reporting_periods/new
  def new
    @reporting_period = ReportingPeriod.new
    @reporting_periods = ReportingPeriod.order(date: :desc)
  end

  # GET /reporting_periods/1/edit
  def edit
    @reporting_periods = ReportingPeriod.order(date: :desc)
  end

  # POST /reporting_periods
  # POST /reporting_periods.json
  def create
    @reporting_period = ReportingPeriod.new(reporting_period_params)
    if params[:copy_reporting_period_id]
      source = ReportingPeriod.find(params[:copy_reporting_period_id])
      @reporting_period.copy_reports_from source
    end

    respond_to do |format|
      if @reporting_period.save
        format.html { redirect_to :reporting_periods, notice: 'Reporting period was successfully created.' }
        format.json { render :show, status: :created, location: @reporting_period }
      else
        format.html do
          @reporting_periods = ReportingPeriod.order(date: :desc)
          render :new
        end
        format.json { render json: @reporting_period.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /reporting_periods/1
  # PATCH/PUT /reporting_periods/1.json
  def update
    respond_to do |format|
      if @reporting_period.update(reporting_period_params)
        format.html { redirect_to reporting_periods_path, notice: 'Reporting period was successfully updated.' }
        format.json { render :show, status: :ok, location: @reporting_period }
      else
        format.html { render :edit }
        format.json { render json: @reporting_period.errors, status: :unprocessable_entity }
      end
    end
  end

  def income
    @monthly_incomes = MonthlyIncome
      .joins(:contract)
      .where(contracts: {aasm_state: 'live'},
             month: 2.months.ago..6.months.from_now)
      .order(month: :desc)
    @timeframe = (@monthly_incomes.minimum(:month)..@monthly_incomes.maximum(:month))
      .map { |d| Date.new(d.year, d.month, 1) }.uniq
    @contracts = Contract.where(aasm_state: 'live').order(:name)
  end

  def update_state
    respond_to do |format|
      if @reporting_period.public_send("#{reporting_period_params[:aasm_state]}!")
        format.html { redirect_to reporting_periods_path, notice: 'Reporting period was successfully updated.' }
        format.json { render :show, status: :ok, location: @reporting_period }
      else
        format.html { render :edit }
        format.json { render json: @reporting_period.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /reporting_periods/1
  # DELETE /reporting_periods/1.json
  def destroy
    @reporting_period.destroy
    respond_to do |format|
      format.html { redirect_to reporting_periods_url, notice: 'Reporting period was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_reporting_period
    @reporting_period = ReportingPeriod.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def reporting_period_params
    params.require(:reporting_period).permit(:date, :aasm_state)
  end
end
