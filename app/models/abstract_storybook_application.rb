class AbstractStorybookApplication
  CRUCIBLE_RESOURCES_DIR = File.join(Rails.root, '../../Crucible/HelloWorld/Resources')
  # Following should live outside of the codebase. So that
  # configurations could be changed without redeploying
  # the application.
  FOG_DIRECTORY          = Fog::Storage.new(
    :provider               => 'AWS',
    :aws_access_key_id      => 'AKIAJ3N4AG2EGQRMHXRQ',
    :aws_secret_access_key  => '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'
  ).directories.get('interapptive')

  @downloadable_file_extension_regex = nil

  def initialize(storybook, storybook_json, target)
    @storybook         = storybook
    @json              = storybook_json
    @transient_files   = []
    @unused_file_names = []
    @target            = target
  end

  def logger
    Rails.logger
  end

  def download_files_and_sanitize_json(hash_or_array)
    @json_hash = traverse_json_hash(hash_or_array) do |transient_hash_or_array, key, value|
      file_name = download_file(value)
      transient_hash_or_array[key] = file_name
      transient_hash_or_array
    end
  end

  def move_unused_files_out_of_compilation
    traverse_json_hash(@json_hash) do |transient_hash_or_array, _, value|
      stage_for_move(value)
      transient_hash_or_array
    end
    FileUtils.mv(unused_files_movement_paths, File.join(CRUCIBLE_RESOURCES_DIR, '..'))
  end

  def move_unused_files_to_resources
    FileUtils.mv(unused_files_movement_paths('..'), CRUCIBLE_RESOURCES_DIR)
  end

  def cleanup
    begin
      File.delete(*@transient_files)
    rescue => e
      logger.info "Cleanup failed for #{@storybook.id}"
      logger.info e.message + "\n" + e.backtrace.join("\n")
    end
  end

  def compile
    raise 'This should be implemented in a subclass'
  end

  def upload_compiled_application
    raise 'This should be implemented in a subclass'
  end

  def send_notification
    raise 'This should be implemented in a subclass'
  end

  # Change this method to include any new uploaders to take care that
  # introduce new type of files in the application
  def self.downloadable_file_extension_regex
    return @downloadable_file_extension_regex if @downloadable_file_extension_regex

    downloadable_extensions = FontUploader.new.extension_white_list +
      ImageUploader.new.extension_white_list +
      SoundUploader.new.extension_white_list +
      VideoUploader.new.extension_white_list
    downloadable_extensions.uniq!
    @downloadable_file_extension_regex = Regexp.new(downloadable_extensions.join('|'), true) # true means case insensitive
    @downloadable_file_extension_regex
  end

  # System font names that could be moved out Resource directory
  # so that these are not packged with compiled application. It
  # only returns only fonts for now but we could extend it to
  # include any other files.
  def self.system_font_names
    Dir.glob(File.join(CRUCIBLE_RESOURCES_DIR, '*.ttf')).map { |p| File.basename(p) }
  end

  private

  def stage_for_move(file_name)
    if self.class.system_font_names.include?(file_name)
      @unused_file_names << file_name if @unused_file_names.exclude?(file_name)
    end
  end

  def traverse_json_hash(json_hash_or_array, &block)
    case json_hash_or_array
    when Hash
      json_hash_or_array.each do |key, value|
        if value.is_a?(Hash) || value.is_a?(Array)
          traverse_json_hash(value, &block)
        else
          json_hash_or_array = yield(json_hash_or_array, key, value)
        end
      end
    when Array
      json_hash_or_array.each_with_index do |value, key|
        if value.is_a?(Hash) || value.is_a?(Array)
          traverse_json_hash(value, &block)
        else
          json_hash_or_array = yield(json_hash_or_array, key, value)
        end
      end
    end
    json_hash_or_array
  end

  def write_json_file
    File.open(File.join(CRUCIBLE_RESOURCES_DIR, 'structure-ipad.json'), 'w') do |f|
      f.write(ActiveSupport::JSON.encode(@json_hash))
    end
  end

  def download_file(file)
    return file unless file.is_a?(String)
    file_ext = File.extname(file)

    if file_ext.match(self.class.downloadable_file_extension_regex)
      if file.match(/^http/)
        return fetch_file(file, file_ext)

      elsif file.match(/^\/assets/)
        return File.basename(file)
      end
    end
    file
  end

  def fetch_file(url, ext)
    new_file_name = SecureRandom.hex
    File.open(File.join(CRUCIBLE_RESOURCES_DIR, new_file_name + ext), 'wb+') do |asset|
      open(url, 'rb') do |read_file|
        asset << read_file.read
        @transient_files << asset.path
      end
    end
    File.basename(@transient_files.last)
  end

  def unused_files_movement_paths(modifier = '')
    @unused_file_names.map { |ufn| File.join(CRUCIBLE_RESOURCES_DIR, modifier, ufn) }
  end
end
