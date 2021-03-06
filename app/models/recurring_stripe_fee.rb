# == Schema Information
#
# Table name: stripe_fees
#
#  id          :integer          not null, primary key
#  fee_plan_id :integer
#  type        :string(255)
#  percent     :decimal(8, 7)    default(0.0)
#  amount      :decimal(8, 2)    default(0.0)
#  interval    :string(255)
#  plan        :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class RecurringStripeFee < StripeFee
  validates_numericality_of :amount, :greater_than => 0.5, message: "Minimal Stripe fee is 0.5$"
  validates :interval, inclusion: { in: ['month', 'year'], message: "%{value} is not a valid interval." }
  validates_presence_of :fee_plan
  belongs_to :fee_plan, :inverse_of => :recurring_stripe_fees
  # Consistency
  before_create :retrieve_interval_and_amount
  # Create recurring plan on Stripe.
  before_create :create_stripe_plan
  # Subscribe everyone to pay the new fee.
  after_create :subscribe_people_with_fee_plan
  # Destroy the plan on Stripe, so customers are unsubscribed.
  after_destroy :destroy_stripe_plan

  before_update :update_stripe_plan


  def create_stripe_plan
    if self.valid?
      plan_name = create_plan_id
      stripe_ret = StripeOps.create_stripe_plan(self.amount, self.interval, plan_name)
      self.plan = stripe_ret.id if stripe_ret.kind_of? Stripe::Plan
    end
  end

  def update_stripe_plan
    if self.valid?
      StripeOps.update_stripe_plan(amount, interval, plan)
    end
  end

  def destroy_stripe_plan
    stripe_ret = StripeOps.retrieve_plan(self.plan)
    stripe_ret.delete if stripe_ret.kind_of? Stripe::Plan
  end

  def retrieve_interval_and_amount
    unless self.plan.blank?
      stripe_plan = StripeOps.retrieve_plan(self.plan)
      if stripe_plan.kind_of? Stripe::Plan
        self.interval = stripe_plan.interval
        self.amount = stripe_plan.amount.to_dollars
      end
    end
  end

  private

  def create_plan_id
    unless self.percent.zero?
      "#{self.fee_plan.name} #{self.interval.capitalize}ly: #{self.percent}%"
    else
      "{self.fee_plan.name} #{self.interval.capitalize}ly: #{self.amount}$"
    end
  end

  def subscribe_people_with_fee_plan
    self.fee_plan.subscribe_payers_to_stripe(self.plan)
  end
end
