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

class Author < ApplicationRecord
  validates :real_name, presence: true
  validates :public_name, presence: true
end
