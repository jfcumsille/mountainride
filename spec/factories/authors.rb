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

FactoryBot.define do
  factory :author do
    real_name { 'Joanne Rowling' }
    public_name { 'J. K. Rowling' }
  end
end
