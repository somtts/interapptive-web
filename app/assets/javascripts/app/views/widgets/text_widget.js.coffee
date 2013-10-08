##
# HTML/CSS 'overlay' view for when editing a text widget.
# Uses contentEditable
#
class App.Views.TextWidget extends Backbone.View
  className: 'text-widget'

  events:
    'input': 'input'
    'keydown': 'keydown'

  ESCAPE_KEYCODE = 27

  ENTER_KEYCODE = 13

  CANVAS_ID = 'builder'


  initialize: ->
    #
    # canvas.attr('height') is scale of HTML canvas
    #  element as set by the attribute on the element
    #
    # canvas.height() is the actual size of the canvas
    #  after being scaled with CSS.
    #
    canvas = $('#' + CANVAS_ID)
    @canvasScale = canvas.height() / canvas.attr('height')

    @model = @options.widget.model
    @model.on 'change:font_color',        @fontColorChanged, @
    @model.on 'change:visual_font_color', @setFontColor,     @
    @model.on 'change:font_size',         @setFontSize,      @
    @model.on 'change:font_id',           @setFontFamily,    @

    App.vent.on 'activate:scene', @deselect
    App.currentSelection.on 'change:keyframe', @deselect


  render: ->
    @


  input: ->
    return App.Lib.LinebreakFilter.filter(@$el)


  keydown: (event) ->
    switch event.keyCode
      when ENTER_KEYCODE
        @shouldSave = true
        @deselect()
      when ESCAPE_KEYCODE
        @shouldSave = false
        @deselect()


  initializeEditing: ->
    @enableContentEditable()
    @setFontFamily()
    @setFontSize()
    @setElementString()
    @fontColorChanged()
    @setPosition()
    @selectText()


  deselect: =>
    if @shouldSave
      text = @$el.text()
      if text.length > 0
        @model.set('string', @$el.text())
      else
        @model.collection?.remove(@model)
        removed = true
      @shouldSave = false

    @trigger 'done' unless removed?

    @remove()


  setElementString: ->
    @$el.text @model.get('string')


  fontColorChanged: ->
    rgb = @model.get('font_color')
    @setFontColor(rgb)


  setFontColor: (rgb) ->
    @$el.css "color", "rgb(#{rgb.r}, #{rgb.g}, #{rgb.b})"


  setFontFamily: ->
    @$el.css('font-family', @model.font())


  setFontSize: ->
    @$el.css("font-size",  "#{@model.get('font_size')}px")


  setPosition: ->
    margin =
      left: parseFloat(@$el.css('margin-left')) + @model.get('position').x * @canvasScale - parseFloat(@$el.css('padding'))
      top:  parseFloat(@$el.css('margin-top')) - @model.get('position').y * @canvasScale
    @$el.css
      'margin-left': "#{margin.left}px"
      'margin-top': "#{margin.top}px"


  enableContentEditable: ->
    @$el.attr('contentEditable', 'true')


  selectText: ->
    @$el.selectText()
    @$el.focus()
