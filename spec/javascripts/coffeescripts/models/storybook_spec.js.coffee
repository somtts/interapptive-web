describe "App.Models.Storybook", ->

  beforeEach ->
    @server = sinon.fakeServer.create()

    @storybook = new App.Models.Storybook

  afterEach ->
    @server.restore()

  describe 'remove an image', ->
    beforeEach ->
      @image = new App.Models.Image(id: 1)
      @storybook.images = new App.Collections.ImagesCollection [@image], storybook: @storybook
      @scene = new App.Models.Scene
        storybook: @storybook
      @storybook.scenes.add @scene

    it 'removes all corresponding sprites', ->
      sprite = new App.Models.SpriteWidget
        image_id: @image.id
      @scene.widgets.add sprite
      expect(@scene.widgets.length).toEqual 1

      @storybook.images.remove @image

      expect(@scene.widgets.length).toEqual 0

    it 'does not remove buttons, but sets the image_id to null', ->
      sprite = new App.Models.ButtonWidget
        image_id: @image.id
      @scene.widgets.add sprite
      expect(@scene.widgets.length).toEqual 1

      @storybook.images.remove @image

      expect(@scene.widgets.length).toEqual 1
      expect(@scene.widgets.at(0).get('image_id')).toEqual null

    it 'but sets the selected_image_id to null', ->
      sprite = new App.Models.ButtonWidget
        selected_image_id: @image.id
      @scene.widgets.add sprite
      expect(@scene.widgets.length).toEqual 1

      @storybook.images.remove @image

      expect(@scene.widgets.length).toEqual 1
      expect(@scene.widgets.at(0).get('selected_image_id')).toEqual null
