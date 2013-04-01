class App.Views.SceneIndex extends Backbone.View

  className: 'scene-list'

  tagName:   'ul'

  events:
    'click  span'   : 'onSceneClick'
    'click .delete' : 'deleteScene'


  DELETE_SCENE_MSG: '\nYou are about to delete a scene and all its keyframes.\n\n\nAre you sure you want to continue?\n'


  initialize: ->
    @collection.on 'add'             , @appendSceneElement, @
    @collection.on 'reset'           , @render            , @
    @collection.on 'change:positions', @_updatePositions  , @
    App.vent.on    'window:resize'   , @adjustSize        , @
    App.currentSelection.on 'change:scene', @sceneChanged, @


  render: ->
    @$el.empty()
    @collection.each @appendSceneElement
    @switchScene(@collection.at(0)) if @collection.length > 0

    @initSortable()

    @adjustSize()

    @


  appendSceneElement: (scene) =>
    view = new App.Views.Scene(model: scene)
    @$el.append view.render().el


  deleteScene: (event) =>
    event.stopPropagation()

    if confirm(@DELETE_SCENE_MSG)
      scene = @collection.get $(event.currentTarget).attr('data-id')
      scene.destroy success: @_removeScene


  onSceneClick: (event) =>
    sceneId = $(event.currentTarget).data 'id'
    scene = @collection.get(sceneId)
    @switchScene(scene)


  switchScene: (scene) ->
    App.currentSelection.set scene: scene


  sceneChanged: (__, scene) ->
    $('li', @el).
    removeClass('active')
      .find("span.scene-frame[data-id=#{scene.get('id')}]")
      .parent().addClass 'active'


  initSortable: =>
    @$el.sortable
      containment : '.sidebar'
      items       : 'li[data-is_main_menu!="1"]'
      axis        : 'y'
      opacity     : 0.6
      update      : @_numberScenes


  adjustSize: ->
    $('#scene-list, .scene-list').css height: "#{$(window).height()}px"


  _removeScene: (scene) =>
    @collection.remove(scene)
    @render()


  _numberScenes: =>
    @$('li[data-is_main_menu!="1"]').each (index, element) =>
      element = $(element)

      if (id = element.data('id'))? && (scene = @collection.get(id))?
        scene.set position: index

    # Backbone bug - without timeout the model is added twice
    window.setTimeout ( =>
      @collection.sort silent: true
      @collection.savePositions()
    ), 0


  _updatePositions: =>
    @$('li[data-is_main_menu!="1"]').each (__, element) =>
      element = $(element)

      if (id = element.data('id'))? && (scene = @collection.get(id))?
        element.find('.page-number').text(scene.get('position') + 1)
