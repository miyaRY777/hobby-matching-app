class Room < ApplicationRecord
  belongs_to :issuer_profile, class_name: "Profile"
end
