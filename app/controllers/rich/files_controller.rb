module Rich
  class FilesController < ApplicationController

    before_filter :authenticate_rich_user
    before_filter :set_rich_file, only: [:show, :destroy]

    layout "rich/application"

    def index
      @type = params[:type]
      @frequently_used = params[:frequently_used]

      if(params[:scoped] == 'true')
        if(@type == "image")
          @items = RichFile.images.order("created_at DESC").where("owner_type = ? AND owner_id = ?", params[:scope_type], params[:scope_id])
        else
          @items = RichFile.files.order("created_at DESC").where("owner_type = ? AND owner_id = ?", params[:scope_type], params[:scope_id])
        end
      else
        if(@type == "image")
          @items = RichFile.images.order("created_at DESC")
        else
          @items = RichFile.files.order("created_at DESC")
        end
      end
      
      if @frequently_used.present? && @frequently_used == "true"
        @items = @items.where(frequently_used: true).page params[:page]
      else
        @items = @items.where(frequently_used: false).page params[:page]
      end

      # stub for new file
      @rich_asset = RichFile.new

      respond_to do |format|
        format.html
        format.js
      end

    end

    def show
      # show is used to retrieve single files through XHR requests after a file has been uploaded

      if(params[:id])
        # list all files
        @file = @rich_file
        render :layout => false
      else
        render :text => "File not found"
      end

    end

    def create

      @file = RichFile.new(:simplified_type => params[:simplified_type])

      if(params[:scoped] == 'true')
        @file.owner_type = params[:scope_type]
        @file.owner_id = params[:scope_id].to_i
      end

      @file.rich_file_title = params[:file_title]
      @file.rich_file_link_to = params[:file_link_to]
      @file.frequently_used = params[:file_frequently_used] if params[:file_frequently_used].present?

      # use the file from Rack Raw Upload
      file_params = params[:file] || params[:qqfile]
      if(file_params)
        file_params.content_type = Mime::Type.lookup_by_extension(file_params.original_filename.split('.').last.to_sym)
        @file.rich_file = file_params
      end

      if @file.save
        response = { :success => true, :rich_id => @file.id }
      else
        response = { :success => false,
                     :error => "Could not upload your file:\n- "+@file.errors.to_a[-1].to_s,
                     :params => params.inspect }
      end

      @frequently_used = @file.frequently_used

      render :json => response, :content_type => "text/html"
    end

    def destroy
      if(params[:id])
        @rich_file.destroy
        @fileid = params[:id]
      end
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_rich_file
        @rich_file = RichFile.find(params[:id])
      end
  end
end
