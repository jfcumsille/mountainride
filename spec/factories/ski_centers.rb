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

FactoryBot.define do
  factory :ski_center do
    sequence(:name) { |n| "Centro Ski #{n}" }
    sequence(:slug) { |n| "centro-ski-#{n}" }
    description { "Un centro de ski de prueba en la Región Metropolitana" }
    address { "Camino a la montaña, km 40" }
    latitude { -33.3500 }
    longitude { -70.2667 }
    website_url { "https://example.com" }
    position { 1 }
    active { true }
  end
end
