require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:first_name) }
    it { should validate_presence_of(:last_name) }
    it { should validate_presence_of(:phone) }

    it 'validates phone format' do
      user = build(:user, phone: '56987654321')
      expect(user).to be_valid

      user.phone = '123456789'
      expect(user).not_to be_valid

      user.phone = '56812345678'
      expect(user).not_to be_valid

      user.phone = '569123456'
      expect(user).not_to be_valid
    end
  end

  describe 'associations' do
    it { should have_many(:trips).dependent(:destroy) }
  end

  describe '#full_name' do
    it 'returns the full name' do
      user = build(:user, first_name: 'Juan', last_name: 'Pérez')
      expect(user.full_name).to eq('Juan Pérez')
    end
  end
end
