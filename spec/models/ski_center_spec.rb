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

require 'rails_helper'

RSpec.describe SkiCenter, type: :model do
  describe 'validations' do
    subject { build(:ski_center) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:slug) }

    it 'validates slug format' do
      ski_center = build(:ski_center, slug: 'valle-nevado')
      expect(ski_center).to be_valid

      ski_center.slug = 'Valle Nevado'
      expect(ski_center).not_to be_valid

      ski_center.slug = 'valle_nevado'
      expect(ski_center).not_to be_valid

      ski_center.slug = 'valle-nevado-2024'
      expect(ski_center).to be_valid
    end

    it 'validates latitude is numeric' do
      ski_center = build(:ski_center, latitude: -33.35)
      expect(ski_center).to be_valid

      ski_center.latitude = 'invalid'
      expect(ski_center).not_to be_valid

      ski_center.latitude = nil
      expect(ski_center).to be_valid
    end

    it 'validates longitude is numeric' do
      ski_center = build(:ski_center, longitude: -70.27)
      expect(ski_center).to be_valid

      ski_center.longitude = 'invalid'
      expect(ski_center).not_to be_valid

      ski_center.longitude = nil
      expect(ski_center).to be_valid
    end
  end

  describe 'associations' do
    it { should have_many(:trips).dependent(:restrict_with_error) }
  end

  describe 'scopes' do
    let!(:active_center) { create(:ski_center, active: true, position: 2) }
    let!(:inactive_center) { create(:ski_center, active: false) }
    let!(:first_center) { create(:ski_center, active: true, position: 1, name: 'B Center') }
    let!(:unpositioned_center) { create(:ski_center, active: true, position: nil, name: 'A Center') }

    describe '.active' do
      it 'returns only active centers' do
        expect(SkiCenter.active).to include(active_center, first_center, unpositioned_center)
        expect(SkiCenter.active).not_to include(inactive_center)
      end
    end

    describe '.ordered' do
      it 'orders by position first, then by name' do
        ordered = SkiCenter.ordered.to_a
        expect(ordered.index(first_center)).to be < ordered.index(active_center)
        expect(ordered.last).to eq(unpositioned_center)
      end
    end
  end

  describe 'callbacks' do
    describe '#generate_slug' do
      it 'generates slug from name if slug is blank' do
        ski_center = build(:ski_center, name: 'Valle Nevado', slug: nil)
        ski_center.valid?
        expect(ski_center.slug).to eq('valle-nevado')
      end

      it 'does not override existing slug' do
        ski_center = build(:ski_center, name: 'Valle Nevado', slug: 'custom-slug')
        ski_center.valid?
        expect(ski_center.slug).to eq('custom-slug')
      end

      it 'handles special characters in name' do
        ski_center = build(:ski_center, name: 'La Parva & Friends', slug: nil)
        ski_center.valid?
        expect(ski_center.slug).to eq('la-parva-friends')
      end
    end
  end
end
