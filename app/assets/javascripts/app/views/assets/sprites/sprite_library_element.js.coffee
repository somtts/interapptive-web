class App.Views.SpriteLibraryElement extends Backbone.View
  template: JST['app/templates/assets/sprites/sprite_library_element']
  tagName:  'li'
  events:
    'click .add': 'addImage'


  render: ->
    @$el.html(@template(sprite: @model))
    @$('.sprite-image').draggable
      helper: 'clone'
      appendTo: 'body'
      cursor: 'move'
      zIndex: 10000
      opacity: 0.5
      scroll: false
      start: @_highlightCanvas
      stop: @_removeCanvasHighlight
    @


  addImage: ->
    App.vent.trigger('create:image', @model)


  _highlightCanvas: =>
    $('canvas#builder-canvas').css('border', '1px solid blue')


  _removeCanvasHighlight: =>
    $('canvas#builder-canvas').css('border', '')
