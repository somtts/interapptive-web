class App.Views.FontToolbar extends Backbone.View
  template: JST['app/templates/widgets/font_toolbar']

  className: 'font_toolbar'

  # defaults
  _hidden: true
  _fontColor: "#000000"
  _fontSize: 12
  _fontFace: "Arial"
  _fontWeight: "bold" # or normal
  _textAlign: "left" # "center", "right"
  #_active: false # keeps hide() from hiding if there is a rollout event etc
  #_timer: null

  events:
    'change .font_face'          :   'onChangeFontFace'
    'change .font_size'          :   'onChangeFontSize'
    'mouseenter'                 :   'mouseEnter'
    'mouseleave'                 :   'mouseLeave'
    'mousemove'                  :   'mouseMove'
    'a .bold'                    :   'boldClick'
    'click .text_align #right'   :   'rightAlignClick'
    'click .text_align #center'  :   'centerAlignClick'
    'click .text_align #left'    :   'leftAlignClick'
    'click .close_x'             :   'onCloseClick'
    'click .delete'              :   'destroyKeyframeText'

  initialize: ->
    @render()
    $(@el).find(".colorpicker").miniColors
      change: (hex, rgb) =>
        @onChangeFontColor(hex, rgb)
    $(@el).draggable()

  render: (model)->
    App.fontsCollection.fetch
      success: =>
        @writeFontFaces(App.fontsCollection.models)
        $(@el).html(@template(fonts: App.fontsCollection.models))
    this

  writeFontFaces: (fonts) ->
    $storybook_font_faces = $('#storybook-font-faces').html('')
    _.each fonts, (f) ->
      font_face = "@font-face { font-family: '#{f.get('name')}'; src: url('#{f.get('url')}'); }"
      $storybook_font_faces.append(font_face)

  setDefaults: ->
    @fontFace @_textWidget().model?.get('face') ? @_fontFace
    @fontColor @_textWidget().model?.get('color') ? @_fontColor
    @fontSize @_textWidget().model?.get('size') ? @_fontSize
    #TODO font weight and font align defaults

  keyframeText: (keyframeText) ->
    @_keyframeText()

  collection: (collection) ->
    if collection then @collection = collection else @collection

  attachToTextWidget: (textWidget) ->
    @_textWidget(textWidget)
    @setDefaults()
    @setPosition(@_textWidget().bottom(), @_textWidget().left())
    @show()

  _textWidget: (textWidget) ->
    if textWidget then @textWidget = textWidget else @textWidget

  _keyframeText: ->
    @_textWidget().model

  update: (e) ->
    App.fontToolbarUpdate(this)

  onChangeFontFace: (e) ->
    @update()

  fontFace: (ff) ->
    if ff then $(@el).find('.font_face').val(ff) else $(@el).find(".font_face option:selected").val()

  onChangeFontSize: (e) ->
    @update()

  fontSize: (fs)->
    if fs then $(@el).find(".font_size").val(fs) else $(@el).find(".font_size option:selected").val()

  onChangeFontColor: (hex, rgb) ->
    @update()

  fontColor: (fc) ->
    if fc then $(@el).find('.colorpicker').val(fc) else $(@el).find('.colorpicker').val()

  fontWeight: (fw) ->
    el = $(@el)
    if fw
      if fw == "bold"
        el.find('.font_weight').addClass('selected')
      else
        el.find('.font_weight').removeClass('selected')
    else
      @_fontWeight

  textAlign: (ta) ->
    if ta then @_textAlign = ta else @_textAlign

  # events
  mouseMove: -> 

  mouseEnter: ->
    @_active = true

  mouseLeave: ->
    @_active = false

  boldClick: ->
    if @fontWeight() == "bold"
      @fontWeight("normal")
    else
      @bold("bold")

    @update()

  leftAlignClick: ->
    @deselectAlignment()
    @textAlign('left')

    @update()

  centerAlignClick: ->
    @deselectAlignment()
    @textAlign('center')

    @update()

  rightAlignClick: ->
    @deselectAlignment()
    @textAlign('right')
    @update()

  deselectAlignment: ->
    $('.align_button').removeClass('selected')

  show: ()->
    $(@el).show()
    @_hidden = false

  setPosition: (_top, _left) ->
    # TODO calculate padding in a more clear way 
    # ENHANCEMENT may need to solve for text too high or too far to the right
    padding = 20
    $(@el).css
      top : _top - ($(@el).height() + padding)
      left : _left

  onCloseClick: ->
    @hide()
    App.fontToolbarClosed()

  hide: ->
    if !@_mouseEntered
      $(@el).hide()
      @_hidden = true

  hidden: ->
    return @_hidden

  leave: ->

  destroyKeyframeText: (e) ->
    $target = $(e.target)
    self = this
    @keyframeText().destroy
      success: (model, response) ->
        $('#keyframe_text_' + model.id).remove()
        self.onCloseClick()
