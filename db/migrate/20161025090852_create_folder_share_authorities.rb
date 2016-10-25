class CreateFolderShareAuthorities < ActiveRecord::Migration[5.0]
  def change
    create_table :folder_share_authorities do |t|
      t.references :folder, foreign_key: true
      t.references :user, foreign_key: true
      t.boolean :can_create
      t.boolean :can_view, default: true
      t.boolean :can_update
      t.boolean :can_destroy
      t.string :share_type
      
      t.timestamps
    end
  end
end
