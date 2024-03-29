class Business < ApplicationRecord
	attr_accessor :remember_token

  has_many :notifications, as: :recipientable
  has_many :schedules, dependent: :destroy
  has_many :fields, dependent: :destroy
  has_many :games, dependent: :destroy
  has_many :reservations, dependent: :destroy
  has_many :charges

	extend FriendlyId
	friendly_id :slug_candidates, use: :slugged
  
	before_save { self.email = email.downcase }
	validates :name, presence: true, length: {maximum: 50}
	validate :check_email_in_user
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
	validates :email, presence: true, length: {maximum: 255},
					  format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }
	validates :phone, presence: true, length: {maximum: 10, minimum: 10},
						uniqueness: true
	validates :address, presence: true, length: {maximum: 255}
	validates :city, presence: true, length: {maximum: 50}
	validates :state, presence: true, length: {maximum: 50}
	validates :zipcode, presence: true, length: {maximum: 5, minimum: 5}
	has_secure_password
	validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

  # This method associates the attribute ":avatar" with a file attachment
    has_attached_file :avatar, styles: {
      thumb: '100x100>',
      square: '200x200#',
      medium: '300x200>'
    }

    # Validate the attached image is image/jpg, image/png, etc
    validates_attachment_content_type :avatar, :content_type => /\Aimage\/.*\Z/

	## Account ID for connect
  def save_stripe_acct_id(acct_id)
    if !acct_id.nil?
      update(stripe_user_id: acct_id)
    end
  end

  ## Customer ID for Subcriptions
  def stripe_customer
    if stripe_id?
      Stripe::Customer.retrieve(stripe_id)
    else
      stripe_customer = Stripe::Customer.create(email: email)
      update(stripe_id: stripe_customer.id)
      stripe_customer
    end
  end

  def subscribed?
    stripe_subscription_id? || (expires_at? && Time.zone.now < expires_at)
  end

  def canceled?
    (expires_at? && Time.zone.now < expires_at)
  end

  # Return the hash digest of the given string
	def Business.digest(string)
	    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
	                                                  BCrypt::Engine.cost
	    BCrypt::Password.create(string, cost: cost)
  	end

  	#Returns a random token
  	def Business.new_token
  		SecureRandom.urlsafe_base64
  	end

  	# Remembers a Business in the database for use in persistent sessions.
  def remember
    self.remember_token = Business.new_token
    update_attribute(:remember_digest, Business.digest(remember_token))
  end

  # Returns true if the given token matches the digest.
  def authenticated?(remember_token)
    return false if remember_digest.nil?
    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end

   # Forgets a user.
  def forget
    update_attribute(:remember_digest, nil)
  end

  def should_generate_new_friendly_id?
  	new_record?
  end

   def slug_candidates
    [
      :name,
      [:name, :city],
      [:name, :zipcode, :city],
      [:name, :zipcode, :city, :state]
    ]
  end

  def check_email_in_user
        email = User.find_by_email(self.email)
        if  email != nil 
          errors.add(:email, "There is a User using the same email.")
        end 
  end

  def self.get_open_businesses_at(date, time, end_time)
      if time < end_time
        Business.all.includes(:schedules).references(:schedules)
          .where("schedules.day = ? AND schedules.open_time <= ?", 
                  date.to_date.strftime("%A"), time.strftime("%H:%M"))
      else
        Business.all.includes(:schedules).references(:schedules)
          .where("schedules.day = ?", 
                  date.to_date.strftime("%A"))
      end
  end

end
