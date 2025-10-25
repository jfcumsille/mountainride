class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  has_many :trips, dependent: :destroy

  # Validations
  validates :first_name, :last_name, presence: true
  validates :phone, format: { with: /\A569\d{8}\z/ }, presence: true

  # Methods
  def full_name
    "#{first_name} #{last_name}"
  end
end
