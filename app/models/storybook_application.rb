class StorybookApplication
  @@crucible_resources_dir = File.join(Rails.root, '../Crucible/HelloWorld/Resources')
  @@crucible_ios_dir       = File.join(Rails.root, '../Crucible/HelloWorld/ios/')
  @@downloadable_file_extension_regex = nil
  @@fog_directory = Fog::Storage.new(
    :provider               => 'AWS',
    :aws_access_key_id      => 'AKIAJ3N4AG2EGQRMHXRQ',
    :aws_secret_access_key  => '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'
  ).directories.get('interapptive')

  def initialize(storybook, storybook_json, target)
    @storybook = storybook
    @json = storybook_json
    @transient_files = []
    @target = target
  end

  def logger
    Rails.logger
  end

  def download_files_and_sanitize_json(hash_or_array)
    case hash_or_array
    when Hash
      hash_or_array.each do |key, value|
        if value.is_a?(Hash) || value.is_a?(Array)
          download_files_and_sanitize_json(value)
        else
          file_name = download_file(value)
          hash_or_array[key] = file_name
        end
      end
    when Array
      hash_or_array.each_with_index do |value, key|
        if value.is_a?(Hash) || value.is_a?(Array)
          download_files_and_sanitize_json(value)
        else
          file_name = download_file(value)
          hash_or_array[key] = file_name
        end
      end
    end
    hash_or_array
  end

  def compile
    @transient_files = []
    @json_hash = download_files_and_sanitize_json(ActiveSupport::JSON.decode(@json))
    write_json_file
    write_rake_file
    xbuild_application
    @json_hash
  end

  def cleanup
    File.delete(*@transient_files)
  end

  def upload_compiled_application
    @storybook.compiled_application = File.open(File.join(@@crucible_ios_dir, 'pkg', 'dist', @target + '.ipa'))
    logger.info 'Uploading of ipa file started!'
    @storybook.save!
    logger.info 'Uploading of ipa file completed!'

    @@fog_directory.files.new(
      :key          => "compiled_applications/#{@storybook.id}/index.html",
      :content_type => 'text/html',
      :public       => true,
      :body         => File.open(File.join(@@crucible_ios_dir, 'pkg', 'dist', 'index.html'))
    ).save
    logger.info 'Uploading of ipa file index.html completed!'

    @@fog_directory.files.new(
      :key          => "compiled_applications/#{@storybook.id}/manifest.plist",
      :content_type => 'text/xml',
      :public       => true,
      :body         => File.open(File.join(@@crucible_ios_dir, 'pkg', 'dist', 'manifest.plist'))
    ).save
    logger.info 'Uploading of ipa file manifest.plist completed!'
    true
  end

  def download_file(file)
    return file unless file.is_a?(String)
    file_ext = File.extname(file)

    if file.match(/^http/) && file_ext.match(downloadable_file_extension_regex)
      new_file_name = SecureRandom.hex
      tf = Tempfile.new([new_file_name, file_ext], @@crucible_resources_dir)
      tf.binmode
      open(file, 'rb') do |read_file|
        tf.write(read_file.read)
      end
      @transient_files << tf.path
      return File.basename(tf.path)
    end
    file
  end

  # Change this method to include any new uploaders to take care that
  # introduce new type of files in the application
  def downloadable_file_extension_regex
    return @@downloadable_file_extension_regex if @@downloadable_file_extension_regex

    downloadable_extensions = FontUploader.new.extension_white_list +
      ImageUploader.new.extension_white_list +
      SoundUploader.new.extension_white_list +
      VideoUploader.new.extension_white_list
    downloadable_extensions.uniq!
    @@downloadable_file_extension_regex = Regexp.new(downloadable_extensions.join('|'), true) # true means case insensitive
    @@downloadable_file_extension_regex
  end

  private

  def xbuild_application
    f = IO.popen("cd #{@@crucible_ios_dir} && security unlock-keychain -p curiousminds /Users/curiousminds/Library/Keychains/login.keychain && rake beta:deploy --trace")
    logger.info f.readlines.join
    f.close
  end

  def write_json_file
    File.open(File.join(@@crucible_resources_dir, 'structure-ipad.json'), 'w') do |f|
      f.write(ActiveSupport::JSON.encode(@json_hash))
    end
  end

  def write_rake_file
    task = <<-END
      require 'rubygems'
      require 'betabuilder'
      BetaBuilder::Tasks.new do |config|
        config.target = '#{@target}'
        config.configuration = 'Adhoc'
        config.app_name = '#{@target}'

        config.deploy_using(:web) do |web|
          web.deploy_to = 'https://interapptive.s3.amazonaws.com/compiled_applications/#{@storybook.id}'
          web.remote_host = 'fake_path'
          web.remote_directory = 'fake_directory'
        end
      end
    END

    File.open(File.join(@@crucible_ios_dir, 'Rakefile'), 'w') do |f|
      f.write(task)
    end
  end
end