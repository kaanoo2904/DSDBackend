class FoldersController < ApplicationController

    include ApplicationHelper

    before_action :set_folder, only: [:show, :edit, :rename, :get_move, :move, :update, :destroy]
    before_action :authenticate_user!

    # GET /folders
    # GET /folders.json
    def index
        set_current_folder Folder.root_folder_of_user(current_user).id
        set_current_children
        set_new_items
        @chat_room = current_folder.chat_room
    end

    # GET /folders/1
    # GET /folders/1.json
    def show
        set_current_folder params[:id]
        set_current_children
        set_new_items
        @chat_room = current_folder.chat_room
    end

    # GET /folders/new
    def new
        @folder = Folder.new
    end

    # GET /folders/1/edit
    def edit
    end

    # POST /folders
    # POST /folders.json
    def create
        @folder = current_folder.children.create folder_params

        if @folder.save
            redirect_to current_folder
        else
            redirect_to current_folder
        end
    end

    # PATCH/PUT /folders/1
    # PATCH/PUT /folders/1.json
    def update
        respond_to do |format|
            if @folder.update(folder_params)                
                format.html { redirect_to current_folder, notice: 'Folder was successfully updated.' }
            else
                format.html { redirect_to current_folder, notice: 'Folder chưa đổi được tên.' }
            end
        end
    end

    # DELETE /folders/1
    # DELETE /folders/1.json
    def destroy
        @folder.destroy
        redirect_to current_folder
    end

    # GET /folders/shared_with_me
    def shared_with_me
       @folders = Folder.shared_with current_user
       @up_files = UpFile.shared_with current_user
    end

    # GET /folders/1/rename
    def rename        
    end

    # GET /folders/1/move
    def get_move
        @folders_tree = Folder.root_folder_of_user(current_user).subtree.arrange
    end

    def move
        @folder.parent_id = params[:new_parent_id]
        if @folder.save
            redirect_to current_folder
        else
            redirect_to current_folder
        end
    end

    private
    # Use callbacks to share common setup or constraints between actions.
    def set_folder
        @folder = Folder.find(params[:id])
    end

    def set_new_items
        @new_folder = Folder.new
        @new_comment = Comment.new
    end

    def set_current_children
        @folders = Folder.children_of current_folder
        @up_files = current_folder.up_files
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def folder_params
        params.require(:folder).permit(:name, :creator_id)
    end
end
