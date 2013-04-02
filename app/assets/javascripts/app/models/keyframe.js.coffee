##
# Relations
# * @scene. It belongs to a scene. The scene is either provided in the attributes
# passed to the constructor, or is taken from the collection to which the scene
# belongs (if any). A Backbone model.
# * @widgets. It has many widgets. A Backbone Collection.
# Some of these widgets are SpriteOrientations. These belong to the keyframe
# (rather than the Scene, or the SpriteWidget) because this means that changing a
# position or a scale on this keyframe implies saving the keyframe to the server.
# Keeping the orientations in the Scene would imply saving the Scene everytime a
# position or scale is saved (in a specific Keyframe), which isn't natural.
#
# There is a special kind of keyframe: the animation keyframe, which has
# the attribute `is_animation` set to true.
# The purpose of the animation keyframe is to allow for a user to create
# an animation, which is played/triggered as soon as the end-user turns to a
# given scene. In the case of Stranger in the Woods, this animation is typically
# a zoom effect. The scene will start zoomed in on part of a picture (i.e.,
# an animal) and zoom out to it's regular size, resulting in a nice, smooth
# animation. Once the animation is done, text from the first keyframe would be
# shown.
class App.Models.Keyframe extends Backbone.Model
  paramRoot: 'keyframe'

  parse: (attributes) ->
    widgets = attributes.widgets; delete attributes.widgets
    if @widgets?
      # RFCTR enable this when upgrading to Backbone 0.9.9
      # @widgets.update(widgets)
    else
      @widgets = new App.Collections.Widgets(widgets)
      @widgets.keyframe = @

    attributes

  initialize: (attributes) ->
    @parse(attributes)

    @initializeScenes(attributes)
    @initializeWidgets(attributes)
    @initializePreview()


  initializeWidgets: (attributes) ->
    @widgets.on 'reset add remove change', =>
      App.vent.trigger 'change:keyframeWidgets', @
      @save()

    @scene.widgets.on 'add',    @sceneWidgetAdded,   @
    @scene.widgets.on 'remove', @sceneWidgetRemoved, @


  initializeScenes: (attributes) ->
    @scene = attributes?.scene || @collection?.scene
    delete @attributes.scene


  toJSON: ->
    _.extend super, widgets: @widgets.toJSON()


  url: ->
    base = '/scenes/' + @scene.id + '/'
    return  (base + 'keyframes.json') if @isNew()
    base + 'keyframes/' + @get('id') + '.json'


  voiceoverUrl: ->
    "/keyframes/#{@get('id')}/audio"


  initializePreview: ->
    attributes = App.Lib.AttributesHelper.filterByPrefix @attributes, 'preview_image_'
    @preview = new App.Models.Preview(attributes, storybook: @scene.storybook)
    @preview.on 'change:data_url change:url', => @trigger 'change:preview', @
    @preview.on 'change:id', =>
      @save preview_image_id: @preview.id


  setPreviewDataUrl: (dataUrl) ->
    @preview.set 'data_url', dataUrl


  sceneWidgetAdded: (sceneWidget) ->
    if sceneWidget instanceof App.Models.SpriteWidget
      # add the widgets after adding `sceneWidget` finished (including its callbacks)
      window.setTimeout (=> @addOrientationFor(sceneWidget)), 0


  sceneWidgetRemoved: (sceneWidget) ->
    if sceneWidget instanceof App.Models.SpriteWidget
      @widgets.remove @getOrientationFor(sceneWidget)


  addOrientationFor: (spriteWidget) ->
    @widgets.add new App.Models.SpriteOrientation
      keyframe_id:      @id
      sprite_widget_id: spriteWidget.id
      position:         $.extend {}, spriteWidget.get('position')
      scale:            spriteWidget.get('scale')


  getOrientationFor: (widget) ->
    @widgets.find (w) ->
      w instanceof App.Models.SpriteOrientation &&
      w.get('sprite_widget_id') == widget.id



  canAddText: ->
    !@isAnimation() && @scene.canAddText()


  isAnimation: ->
    @get('is_animation')



  nextTextSyncOrder: ->
    text_widget_with_max_sync_order = _.max(@text_widgets(), (w) -> w.sync_order)
    (text_widget_with_max_sync_order?.sync_order || 0) + 1



  textWidgets: ->
    @widgetsByClass(App.Models.TextWidget)


  widgetsByClass: (klass) ->
    return [] unless klass?
    @widgets.filter (w) -> w instanceof klass


  updateContentHighlightTimes: (times, options={}) ->
    @save { content_highlight_times: times }, options


##
# Relations:
# @scene - it belongs to a scene.

class App.Collections.KeyframesCollection extends Backbone.Collection
  model: App.Models.Keyframe

  paramRoot: 'keyframe'


  initialize: (models, options) ->
    @scene = options.scene

    @on 'reset', =>
      @announceAnimation()
      # TODO move cache to a separate class
      @_savePositionsCache(@_positionsJSON())

    @on 'add remove', (model, _collection, options) =>
      @announceAnimation()

    @on 'remove', (model, collection) ->
      collection._recalculatePositionsAfterDelete(model)


  url: ->
    '/scenes/' + @scene.id + '/keyframes.json'


  ordinalUpdateUrl: ->
    '/scenes/' + @scene.id + '/keyframes/sort.json'


  toModdedJSON: ->
    return {"keyframes": this.toJSON()}


  comparator: (keyframe) ->
    if keyframe.isAnimation()
      -1
    else
      keyframe.get 'position'


  animationPresent: ->
    @any (keyframe) -> keyframe.isAnimation()


  announceAnimation: ->
    App.vent.trigger 'can_add:sceneAnimation',
      !@animationPresent() && @scene.canAddKeyframes()


  addNewKeyframe: (attributes={}) ->
    # add the object to the collection after it was saved
    # so we have only valid objects in the collection
    # so the views don't need to deal with `id` changes
    keyframe = new App.Models.Keyframe(
      _.extend(attributes, {
        scene: @scene
        position: @nextPosition(attributes)
      })
    )
    keyframe.save [],
      success: => @add keyframe


  nextPosition: (options) ->
    return null if options.is_animation
    @filter((k) -> !k.isAnimation()).length


  savePositions: ->
    positions = @_positionsJSON()
    return unless @_positionsJSONIsDifferent(positions)

    @_savePositionsCache(positions)
    $.ajax
      contentType:"application/json"
      dataType: 'json'
      type: 'POST'
      data: JSON.stringify positions
      url: @ordinalUpdateUrl()
      success: =>
        @trigger 'change:positions'


  _savePositionsCache: (positions) ->
    @positionsJSONCache = positions


  _positionsJSONIsDifferent: (positions) ->
    JSON.stringify(@positionsJSONCache) != JSON.stringify(positions)


  _positionsJSON: ->
    JSON = { keyframes: [] }

    @each (element) ->
      JSON.keyframes.push
        id: element.get 'id'
        position: element.get 'position'

    JSON

  _recalculatePositionsAfterDelete: (model) ->
    return if model.isAnimation()

    position = model.get('position')
    followingKeyframes = @filter (keyframe) -> keyframe.get('position') > position

    if followingKeyframes.length > 0
      _.each followingKeyframes, (keyframe) ->
        keyframe.set { position: keyframe.get('position') - 1 }, silent: true

    @sort silent: true
    @savePositions()
