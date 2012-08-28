 class ImagesController < ApplicationController
  require "base64"

  def index
    @storybook = Storybook.find(params[:storybook_id])
    @images = @storybook.images

    render :json => @images.map(&:as_jquery_upload_response).to_json
  end

  def show
    @scene = Scene.find params[:scene_id]
    @image = @scene.images.find params[:id]

    respond_to do |format|
      format.json { render :json => @image }
    end
  end

  def create
    @scene = Scene.find params[:scene_id]

    if params[:base64]
      file = write_file
      @images = [Image.create(:image => file)]
    else
      @images = params[:image][:files].map { |f| Image.create(:image => f) }
      @images.each do |i|
        @scene.images << i
      end
    end

    respond_to do |format|
      format.json { render :json => @images.map(&:as_jquery_upload_response).to_json }
    end
  end

  # POST /images/:id
  # PUT /images/:id.format
  def update
    @image = Image.find params[:id]
    @image.remove_image!
    file = write_file

    @image.update_attribute(:image, file)

    respond_to do |format|
      format.json { render :json => [@image.as_jquery_upload_response] }
    end
  end

  # DELETE /images/:id
  # DELETE /images/:id.json
  def destroy
    Image.find(params[:id]).try(:destroy)

    respond_to do |format|
      format.json { head :ok }
    end
  end

  private

  def write_file
    filename = "#{(0..35).map{ rand(36).to_s(36) }.join}.png" # Random alphanumeric
    file = File.open(filename, "wb")
    file.write(Base64.decode64(params[:image][:files][0]))
  end
end
