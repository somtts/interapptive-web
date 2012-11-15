class App.Views.AssetLibrary extends Backbone.View
  template: JST["app/templates/assets/library"]
  events:
    'click .video-thumbnail' : 'playVideo'

  initialize: (assetType) ->
    @activeAssetType = assetType
    @acceptedFileTypes = @fileTypes(assetType)

  render: ->
    $(@el).html(@template(assetType: @activeAssetType, acceptedFileTypes: @acceptedFileTypes))
    this

  initAssetLibFor: (type) ->
    @assetType = type.replace(/(\s+)?.$/, "") # Remove last char. from params (an "s")
    $(".content-modal").addClass "asset-library-modal"
    $("#fileupload").fileupload
      downloadTemplateId: null
      uploadTemplateId: null
      downloadTemplate: JST["app/templates/assets/" + @assetType + "s/download"]
      uploadTemplate: JST["app/templates/assets/" + @assetType + "s/upload"]
    @loadAndShowFileData()

  loadAndShowFileData: ->
    $.getJSON "/storybooks/#{App.currentStorybook().get('id')}/" + @assetType + "s", (files) ->
      fileData = $("#fileupload").data("fileupload")
      fileData._adjustMaxNumberOfFiles - files.length
      template = fileData._renderDownload(files).prependTo($("#fileupload .files"))
      fileData._reflow = fileData._transition and template.length and template[0].offsetWidth
      template.addClass "in"
      $("#loading").remove()
      $("#searchtable").show()
      $(".table-striped").advancedtable({searchField: "#search", loadElement: "#loader", searchCaseSensitive: false, ascImage: "/assets/advancedtable/up.png", descImage: "/assets/advancedtable/down.png", afterRedraw: @attachDeleteEvent() })

  closeAssetLib: ->
    $("#fileupload").fileupload "disable"
    $('.content-modal').removeClass "asset-library-modal"

  setAllowedFilesFor: (assetType) ->
    pattern = @fileTypePattern(assetType)
    $("#fileupload").fileupload(acceptFileTypes: pattern)

  fileTypePattern: (assetType) ->
    file_types = @fileTypes(assetType)
    up_file_types = file_types.map((type) ->
      type.toUpperCase()
    )
    pattern = '\.('
    pattern = pattern + file_types.join('|')
    pattern = pattern + '|'
    pattern = pattern + up_file_types.join('|')
    pattern = pattern + ')$'
    new RegExp(pattern)

  fileTypes: (assetType) ->
    switch assetType
      when 'image', 'images' then return ['jpg', 'jpeg', 'gif', 'png']
      when 'video', 'videos' then return ['mov', 'mpg', 'mpeg', 'mkv', 'm4v', 'avi', 'flv']
      when 'font',  'fonts'  then return ['ttf', 'otf']
      when 'sound', 'sounds' then return ['mp3', 'wav', 'aac', 'm4a']

  playVideo: (em) ->
    video = $(em.currentTarget).data('video')
    $('.content-modal').hide()
    App.lightboxWithView(view: new App.Views.VideoPlayer(video)).show()

  attachDeleteEvent: =>
    console.log('bar')
    $('.delete-asset').click(@hideRow)

  hideRow: (e) ->
    console.log('foo')
    $(e.target).parent().hide()
