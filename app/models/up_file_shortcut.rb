class UpFileShortcut < ApplicationRecord
  belongs_to :up_file
  belongs_to :folder

  validates :up_file_id, presence: true
  validates :folder_id, presence: true
end
