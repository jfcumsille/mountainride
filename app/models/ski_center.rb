# == Schema Information
#
# Table name: ski_centers
#
#  id          :integer          not null, primary key
#  name        :string           not null
#  slug        :string           not null
#  description :text
#  address     :string
#  latitude    :decimal(10, 6)
#  longitude   :decimal(10, 6)
#  website_url :string
#  position    :integer
#  active      :boolean          default(TRUE), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_ski_centers_on_active    (active)
#  index_ski_centers_on_position  (position)
#  index_ski_centers_on_slug      (slug) UNIQUE
#

class SkiCenter < ApplicationRecord
  # Associations
  has_many :trips, dependent: :restrict_with_error

  # Validations
  validates :name, :slug, presence: true
  validates :slug, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }
  validates :latitude, :longitude, numericality: true, allow_nil: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? }

  private

  def generate_slug
    self.slug = name.parameterize if name.present?
  end
end
