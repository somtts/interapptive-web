nextSpriteTag = 1

class App.StorybookJSON

  constructor: ->

    # The object that will become the JSON string
    @document =
      Configurations:
        pageFlipSound:
          forward: "page-flip-sound.mp3"
          backward: "page-flip-sound.mp3"

        pageFlipTransitionDuration: 0.6
        paragraphTextFadeDuration: 0.4
        homeMenuForPages:
          normalStateImage: "home-button.png"
          tappedStateImage: "home-button-over.png"
          position: [20, 20]

      MainMenu:
        CCSprites: [],
        MenuItems: [{
            normalStateImage: "autoplay.png",
            tappedStateImage: "autoplay-over.png",
            storyMode: "autoPlay",
            position: [100, 112]
        }, {
            normalStateImage: "read-it-myself.png",
            tappedStateImage: "read-it-myself-over.png",
            storyMode: "readItMyself",
            position: [400, 112]
        }, {
            normalStateImage: "read-to-me.png",
            tappedStateImage: "read-to-me-over.png",
            storyMode: "readToMe",
            position: [700, 112]
        }],
        API: {
            CCFadeIn: [{
                duration: 2,
                actionTag: 22
            }]
        },
        runActionsOnEnter: [{
            spriteTag: 100,
            actionTag: 22
        }]

      Pages: []


  @fromJSON: (json) ->
    # TODO


  toString: ->
    JSON.stringify(@document)


  resetPages: ->
    @document.Pages = []


  resetParagraphs: (scene) ->
    page = scene._page
    page.Page.text.paragraphs = [] if page?


  # scene === page
  createPage: (scene) ->

    page =
      API: {}
      Page:
        settings:
          number: @document.Pages.length + 1,
          fontType: "Arial",
          fontColor: [255, 0, 0],
          fontHighlightColor: [255, 255, 255],
          fontSize: 24,
          backgroundMusicFile:
            loop: true,
            audioFilePath: scene.get('sound_url')
        text:
          paragraphs: []

    scene._page = page
    @createWidgetsFor(scene)
    @createParagraphsFor(scene)
    @document.Pages.push(page)
    page

  destroyPage: (scene) ->
    page = scene._page
    throw new Error("Scene has no Page") unless page?
    @document.Pages.splice(@document.Pages.indexOf(page), 1)
    _updatePageNumbers(page.settings.number)

  _updatePageNumbers: (from_number) ->
    _.each(@document.Pages, (page) ->
      if page.Page.settings.number > from_number
        page.Page.settings.number = page.Page.settings.number - from_number
    )

  createParagraphsFor: (scene) ->
    scene.keyframes.fetch
      success: =>
        scene.keyframes.each (keyframe) =>
          @createParagraph(scene, keyframe)

  createWidgetsFor: (scene) ->
    _.each(scene.get('widgets'), (widget) =>
      @createWidgetFor(scene, widget)
    )

  createWidgetFor: (scene, widget) ->
    this['add' + widget.type].call(this, scene, new App.Builder.Widgets[widget.type](widget))

  # keyframe === paragraph
  createParagraph: (scene, keyframe) ->
    page = scene._page
    throw new Error("Scene has no Page") unless page?

    paragraph =
      delayForPanning: true
      highlightingTimes: _.map(keyframe.get('content_highlight_times'), (num) -> Number(num))
      linesOfText: keyframe.texts.pluckContent()
      voiceAudioFile: keyframe.get('url')

    page.Page.text.paragraphs.push(paragraph)

    keyframe._paragraph = paragraph

    paragraph

  removeParagraph: (scene, keyframe) ->
    page = scene._page
    throw new Error("Scene has no Page") unless page?
    page.Page.text.paragraphs.splice(page.Page.text.paragraphs.indexOf(keyframe._paragraph), 1)

  updateParagraph: (keyframe) ->
    keyframe._paragraph.highlightingTimes = _.map(keyframe.get('content_highlight_times'), (num) -> Number(num))
    keyframe._paragraph.linesOfText       = keyframe.texts.pluckContent()
    keyframe._paragraph.voiceAudioFile    = keyframe.get('url')

  addText: (_text, keyframe) ->
    keyframe ||= App.currentKeyframe()

    p = keyframe._paragraph
    throw new Error("Keyframe has no Paragraph") unless p?

    _model = _text.model
    _lineOfTextJSON =
      text:    _text._content
      xOffset: _model.get('x_coord')
      yOffset: _model.get('y_coord')
    p.linesOfText.push(_lineOfTextJSON)


  addWidget: (keyframe, widget) ->
    p = keyframe._paragraph
    throw new Error("Keyframe has no Paragraph") unless p?

    # FIXME Need a more generic way to add widgets to the JSON
    # FIXME TextWidget should be handled by KeyframesTextIndex
    if widget instanceof App.Views.TextWidget
      line =
        text: widget.getText()
        xOffset: Math.round(widget.x())
        yOffset: Math.round(widget.y())

      widget._line = line
      #TODO this logic should change according to new html text widgets
      p.linesOfText.push(line)

    widget.on('change', (property) => @updateWidget(keyframe, widget, property))


  updateWidget: (keyframe, widget, property) ->
    p = keyframe._paragraph
    throw new Error("Keyframe has no Paragraph") unless p?

  removeTextFromKeyframe: () ->
    throw new Error("Not implemented yet")


  getPage: (pageNumber) ->
    @document.Pages[pageNumber]


  addSpriteWidget: (scene, sprite) ->
    page = scene._page

    page.API.CCSprites ||= []

    # Hardcoded actions
    ###
    page.API.CCMoveBy = [{
      position: [-810, 100],
      duration: 3,
      actionTag: 30
    }]
    page.API.CCScaleBy = [{
      intensity: 1.4,
      duration: 3,
      actionTag: 31
    }, {
      intensity: 1.0,
      duration: 0,
      actionTag: 32
    }, {
      intensity: 1.4,
      duration: 3,
      actionTag: 34
    }]
    page.API.CCStorySwipeEnded = {
      runAction: [{
        runAfterSwipeNumber: 1,
        spriteTag: nextSpriteTag,
        actionTags: [30, 34]
      }]
    }
    ###

    App.d1 = sprite
    spriteJSON =
      image:     sprite.getUrl()
      spriteTag: nextSpriteTag
      position:  [sprite.getPosition().x, sprite.getPosition().y]

      #actions: [32]

    page.API.CCSprites.push(spriteJSON)

    sprite.setTag(spriteJSON.spriteTag)

    nextSpriteTag += 1
    return spriteJSON.spriteTag


  updateSprite: (scene, sprite) ->
    page = scene._page

    for spriteJSON in page.API.CCSprites
      if spriteJSON.spriteTag == sprite.getTag()
        spriteJSON.position = [sprite.getPosition().x, sprite.getPosition().y]
        spriteJSON.scale = sprite.getScale()

        break

  removeSprite: (sprite) ->
    # TODO
