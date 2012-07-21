class App.Views.ToolbarView extends Backbone.View
  events:
    'click .add-scene'   : 'addScene'
    'click .add-keyframe': 'addKeyframe'
    'click .add-image'   : 'addImage'
    'click .add-text'    : 'addText'
    'click .add-touch'   : 'addTouch'
    'click .add-sprite'  : 'addSprite'
    'click .images'      : 'showImageLibrary'
    'click .videos'      : 'showVideoLibrary'
    'click .fonts'       : 'showFontLibrary'
    'click .sounds'      : 'showSoundLibrary'

  initialize: ->
    @assetLibraryView = new App.Views.AssetLibrary()

  render: ->
    $el = $(this.el)

  _addWidget: (widget) ->
    keyframe = App.currentKeyframe()
    App.builder.widgetLayer.addWidget(widget)
    keyframe.addWidget(widget)
    widget.on('change', -> keyframe.updateWidget(widget))

  addScene: ->
    @scene = App.sceneList().createScene()

  addKeyframe: ->
    App.keyframeList().createKeyframe()

  addImage: ->
    App.modalWithView(view: App.imageList()).show()

  addText: ->
    # FIXME we should have some delegate that actually handles adding things
    text = new App.Builder.Widgets.TextWidget(string: (prompt('Enter some text') or '<No Text>'))
    text.setPosition(new cc.Point(100, 100))
    @_addWidget(text)

  addTouch: ->
    alert('TODO show touch point dialogue here')
    widget = new App.Builder.Widgets.TouchWidget
    widget.setPosition(new cc.Point(300, 300))
    @_addWidget(widget)

  addSprite: ->
    imageSelected = (sprite) =>
      widget = new App.Builder.Widgets.SpriteWidget(url: sprite.get('url'))
      widget.setPosition(new cc.Point(300, 400))
      @_addWidget(widget)

      App.modalWithView().hide()
      view.off('image_select', imageSelected)

    view = App.spriteList()
    view.on('image_select', imageSelected)

    App.modalWithView(view: view).show()

  showImageLibrary: ->
    @loadDataFor("image")

  showVideoLibrary: ->
    @loadDataFor("video")

  showFontLibrary: ->
    @loadDataFor("font")

  showSoundLibrary: ->
    @loadDataFor("sound")

  loadDataFor: (assetType) ->
    @assetLibraryView.activeAssetType = assetType
    App.modalWithView(view: @assetLibraryView).show()
    @assetLibraryView.setAllowedFilesFor assetType + "s"
    @assetLibraryView.initAssetLibFor assetType + "s"

