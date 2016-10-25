class Folder < ApplicationRecord

    has_ancestry

    belongs_to :creator, class_name: 'User'
    has_one :chat_room, as: :crmable, dependent: :destroy
        
    has_many :folder_share_authorities, dependent: :destroy
    

    ####### Quản lý các file shortcut tới thư mục ###########
    ##  1 file có nhiều đường dẫn tới các folder, tuy nhiên chỉ có 1 đường dẫn là 'direct', còn lại là 'shortcut'

    has_many :up_file_shortcuts, dependent: :destroy
    has_many :up_files, through: :up_file_shortcuts

    ####### Shortcut relation ######################

    has_many :shortcut_relationships, foreign_key: :destination_id, class_name: 'FolderShortcut', dependent: :destroy
    has_many :destination_relationships, foreign_key: :shortcut_id, class_name: 'FolderShortcut', dependent: :destroy

    has_many :shortcuts, through: :shortcut_relationships, source: :shortcut
    has_many :destinations, through: :destination_relationships, source: :destionation

    accepts_nested_attributes_for :shortcut_relationships, allow_destroy: true
    accepts_nested_attributes_for :destination_relationships, allow_destroy: true

    ################################################

    scope :root_folder_of_user, ->(user) { where(creator_id: user.id, ancestry: nil).first }

    scope :children_of, ->(folder) { folder.children }

    before_create :create_chat_room

    def create_chat_room
        self.build_chat_room
        true
    end


end
