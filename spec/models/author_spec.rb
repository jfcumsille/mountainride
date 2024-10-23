# == Schema Information
#
# Table name: authors
#
#  id          :integer          not null, primary key
#  real_name   :string           not null
#  public_name :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'rails_helper'

RSpec.describe Author do
  subject { build(:author) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:real_name) }
    it { is_expected.to validate_presence_of(:public_name) }
  end

  describe 'factory' do
    it { is_expected.to be_valid }
  end
end
