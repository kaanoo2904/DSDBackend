class UpFilesController < ApplicationController
    include ApplicationHelper
    include UpFilesHelper

    before_action :set_up_file, only: [:continue_upload, :edit, :rename, :update, :destroy]
    before_action :set_new_items, only: [:show]

    # GET /up_files
    def index
        @up_files = UpFile.all
    end

    # GET /up_files/1
    def show
        begin
            @up_file = UpFile.find(params[:id])
            @chat_room = @up_file.chat_room
        rescue ActiveRecord::RecordNotFound
            flash[:warning] = 'Không tìm thấy file. Quay về home.'
            redirect_to folder_path
        end
    end

    # GET /up_files/new
    def new
        @up_file = UpFile.new
    end

    # GET /up_files/1/edit
    def edit
    end

    # POST /up_files
    def create

        # File tạm được upload lên
        @temp_upfile = UpFile.new up_file_params

        content_range = request.headers['CONTENT-RANGE']

        if content_range.nil? #file nhỏ hơn 5MB, lưu ko phải tính :D
            @temp_upfile.status = 'ready'
            @temp_upfile.save
            save_direct_shortcut_for_file @temp_upfile, params[:folder_id]
            UpFilesCreateBroadcastJob.set(wait: 2.second).perform_later current_folder.id
            return
        end

        content_length = request.headers['CONTENT-LENGTH'].to_i

        begin_of_chunk = content_range[/\ (.*?)-/,1].to_i
        end_of_chunk = content_range[/-(.*?)\//,1].to_i
        total_chunk = content_range[/\/(\d+)/,1].to_i
        # "bytes 100-999999/1973660678" will return '100'

        if (begin_of_chunk == 0)                           # upload part đầu tiên
            @temp_upfile.status = 'uploading'
            @temp_upfile.save
            save_direct_shortcut_for_file @temp_upfile, params[:folder_id]
        else
            @up_file = UpFile.find_by(temp_up_id: @temp_upfile.temp_up_id)
            @up_file.file_size += content_length

            if (Rails.env.development?)
                #code for FTP server
                get_ftp_connection do |ftp|
                    full_path = ::File.dirname "#{ENV['ftp_folder']}/#{@up_file.link.path}"
                    base_name = File.basename(@up_file.link.to_s)
                    ftp.chdir(full_path)
                    ftp.getbinaryfile(base_name, base_name, 1024)
                    File.open(base_name, "ab") do |f|
                        f.write(up_file_params[:link].read)
                    end
                    ftp.putbinaryfile(base_name, base_name, 1024)
                    File.delete(base_name)
                end
            else
                # code for local test
                File.open(@up_file.link.path, "ab") do |f|
                    f.write(up_file_params[:link].read)
                end
            end

            if (end_of_chunk == total_chunk - 1)  # kết thúc
                @up_file.status = 'ready'
            end

            @up_file.save
            if @up_file.status == 'ready'
                UpFilesCreateBroadcastJob.perform_later current_folder.id
            end
        end
    end


    # PATCH/PUT /up_files/1
    def update
        if @up_file.update(up_file_params)
            redirect_to :back
        else
            render :edit
        end
    end

    # DELETE /up_files/1
    def destroy
        @up_file.destroy
        redirect_to current_folder, notice: 'UpFile was successfully destroyed.'
        #render :json => true
    end

    def rename

    end

    def resume_upload
        @up_file = UpFile.find_by(temp_up_id: params[:id])
        render json: { file: {size: @up_file.file_size} } and return
    end

    def check_exist
        respond_to do |format|
            format.json {
                begin
                    @up_file = UpFile.find(params[:id])
                    render json: true
                rescue
                    flash[:warning] = 'File không còn tồn tại.'
                    render json: false
                end
            }
        end
    end

    private
    # Use callbacks to share common setup or constraints between actions.
    def set_up_file
        @up_file = UpFile.find(params[:id])
    end

    def set_new_items
        @new_comment = Comment.new
    end

    def save_direct_shortcut_for_file up_file, folder_id
        shortcut = UpFileShortcut.new(up_file: up_file, folder_id: folder_id)
        shortcut.save
    end

    # Only allow a trusted parameter "white list" through.
    def up_file_params
        params.require(:up_file).permit(:link, :file_name, :uploader_id, :temp_up_id, up_file_shortcuts_params: [:up_file_id, :folder_id])
    end
end
