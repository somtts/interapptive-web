window.App =

  Models:      {}
  Views:       {}
  Collections: {}
  Routers:     {}
  Lib:         {}
  Config:      {}
  Services:    {}
  Dispatchers: {}

  init: ->
    # A global vent object that allows decoupled communication between
    # different parts of the application. For example, the content of the
    # main view and the buttons in the toolbar.
    # It would be great to use it to decouple more.
    @vent = _.extend {}, Backbone.Events
    # @vent.on 'all', -> console.log arguments # debug everything going through the vent

    @fontsCollection =         new App.Collections.FontsCollection         []
    @scenesCollection =        new App.Collections.ScenesCollection        []
    @imagesCollection =        new App.Collections.ImagesCollection        []
    @soundsCollection =        new App.Collections.SoundsCollection        []
    @keyframesCollection =     new App.Collections.KeyframesCollection     []
    @keyframesTextCollection = new App.Collections.KeyframeTextsCollection []
    @activeActionsCollection = new App.Collections.ActionsCollection       []

    @contentModal =   new App.Views.Modal className: 'content-modal'
    @fileMenu =       new App.Views.FileMenuView el: $('#file-menu')
    @toolbar =        new App.Views.ToolbarView  el: $('#toolbar')

    @sceneList         new App.Views.SceneIndex        collection: @scenesCollection
    @keyframeList      new App.Views.KeyframeIndex     collection: @keyframesCollection
    @keyframeTextList  new App.Views.KeyframeTextIndex collection: @keyframesTextCollection, el: $('#canvas-wrapper')

    # RFCTR: Rename to palette
    @activeSpritesList = new App.Views.ActiveSpritesList()
    @activeSpritesWindow @activeSpritesList

    # RFCTR: Rename to palette
    @spriteForm = new App.Views.SpriteForm el: $('#sprite-editor')
    @spriteFormWindow @spriteForm

    @storybooksRouter = new App.Routers.StorybooksRouter
    Backbone.history.start()


  #
  #  Temporarily Out of Service.
  #
  #    @activeActionsWindow(new App.Views.ActiveActionsList collection: @activeActionsCollection)
  #
  #    activeActionsWindow: (view) ->
  #      if view
  #        @actionsWindow = new App.Views.WidgetWindow(
  #          view:       view,
  #          el:         $('#active-actions-window'),
  #          alsoResize: '#active-actions'
  #        )
  #      else
  #        @actionsWindow
  #


  # RFCTR: Rename to palette
  activeSpritesWindow: (view) ->
    @spritesWindow unless view

    @spritesWindow = new App.Views.WidgetWindow
      el         :  $('#active-sprites-window')
      view       :  view
      title      :  'Scene Images'
      alsoResize : '#active-sprites-window ul li span'


  # RFCTR: Rename to palette
  spriteFormWindow: (view) ->
    @selectedSpriteWin unless view

    @selectedSpriteWin = new App.Views.WidgetWindow
      el        : $('#sprite-form-window')
      view      : view
      resizable : false


  showSimulator: ->
    @simulator = new App.Views.Simulator(json: App.storybookJSON.toString())

    @openLargeModal(@simulator)


  # RFCTR: Use generic modal & add sizing options to it
  openLargeModal: (view, className='') ->
    return unless view
    @closeLargeModal(false)

    @_modal = new App.Views.LargeModal(view: view, className: 'large-modal')
    $('body').append(@_modal.render().el)
    $('.large-modal').modal(backdrop: true)


  # RFCTR: cont. from above
  closeLargeModal: (animate=true) ->
   if @_modal then @_modal.hide()


  modalWithView: (view) ->
    @view unless view

    @view = new App.Views.Modal view, className: 'content-modal'


  lightboxWithView: (view) ->
    @lightboxView unless view

    @lightboxView = new App.Views.Lightbox view, className: 'lightbox-modal'


  currentUser: (user) ->
    @user unless user

    @user = new App.Models.User user


  currentStorybook: (storybook) ->
    if storybook
      # FIXME Need to remove events from old object
      @storybookJSON = new App.StorybookJSON

      @scenesCollection.on 'reset', (scenes) =>
        @storybookJSON.resetPages()
        scenes.each (scene) => @storybookJSON.createPage(scene)

      @scenesCollection.on 'add', (scene) =>
        @storybookJSON.createPage(scene)

      @scenesCollection.on 'remove', (scene) =>
        @storybookJSON.destroyPage(scene)

      @keyframesCollection.on 'reset', (keyframes) =>
        scene = @currentScene()
        if keyframes? && keyframes.length > 0 then scene.setPreviewFrom keyframes.at(0)
        @storybookJSON.resetParagraphs(scene)
        keyframes.each (keyframe) => @storybookJSON.createParagraph scene, keyframe

      @keyframesCollection.on 'add', (keyframe) =>
        @storybookJSON.createParagraph @currentScene(), keyframe

      @keyframesCollection.on 'remove', (keyframe) =>
        @storybookJSON.removeParagraph @currentScene(), keyframe

      @storybook = storybook

    @storybook


  currentScene: (scene) ->
    if scene
      @scene = scene

      if $('#keyframe-list ul').length == 0
          $('#keyframe-list').html App.keyframeList().el

      App.keyframeList().collection.scene_id = scene.get 'id'
      App.keyframeList().collection.fetch()

    @scene


  currentKeyframe: (keyframe) ->
    if keyframe
      @keyframe = keyframe
      App.vent.trigger 'keyframe:can_add_text', keyframe.canAddText()
    else
      @keyframe


  currentKeyframeText: (keyframeText) ->
    if keyframeText then @keyframeText = keyframeText else @keyframeText


  sceneList: (list) ->
    if list then @sceneListView = list else @sceneListView


  keyframeList: (list) ->
    if list then @keyframeListView = list else @keyframeListView


  keyframeTextList: (list) ->
    if list then @keyframeTextListView = list else @keyframeTextListView


  selectedText: (textWidget) ->
    if textWidget then @textWidget = textWidget else @textWidget


  # RFCTR: cont.
  fontToolbarUpdate: (fontToolbar) ->
    @selectedText().fontToolbarUpdate fontToolbar


  # RFCTR: cont.
  fontToolbarClosed: ->
    $('.text-widget').focusout()


  # RFCTR cont.
  updateKeyframeText: ->
    @keyframeTextList().updateText()

  # RFCTR: Move to asset library view, use vent where needed
  pauseVideos: ->
    $('.video-player')[0].pause()
    $('.content-modal').show()


$ ->
  App.init()

  $(window).resize -> App.vent.trigger('window:resize')

  $('.content-modal').modal(backdrop: true).modal 'hide'
  $('.lightbox-modal').modal().modal('hide').on 'hide', App.pauseVideos

  # RFCTR: Should use generic modal view
  $('#storybooks-modal').modal
    backdrop : 'static'
    show     : true
    keyboard : false
