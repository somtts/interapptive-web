class Image < Asset
  mount_uploader :image, ImageUploader

  def as_jquery_upload_response
    {
      'id'            =>    id,
      'name'          =>    read_attribute(:image),
      'size'          =>    image.size,
      'url'           =>    image.url,
      'thumbnail_url' =>    image.thumb.url,
      'delete_url'    =>    "/images/#{self.id}",
      'delete_type'   =>    'DELETE',
      'created_at'    =>    created_at
    }
  end
end
