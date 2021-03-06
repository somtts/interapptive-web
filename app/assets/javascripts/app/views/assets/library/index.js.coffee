#
# The available assets.
#
class App.Views.AssetsLibrary extends Backbone.View

  initialize: ->
    @views = []


  setCollection: (collection) ->
    @collection = collection

    @collection.on 'add',    @_add,           @
    @collection.on 'remove', @_remove,        @
    @collection.on 'sort',   @_sort,          @
    @collection.on 'filter', @_assetFiltered, @

    if @collection.length > 0
      @collection.each @_add
    else


  filterBy: (filter) ->
    @$el.removeClass('images videos sounds').addClass(filter)


  _assetFiltered: (asset, __, accepted) ->
    @_getView(asset).$el
      .removeClass('filter-on filter-off')
      .addClass("filter-#{if accepted then 'on' else 'off'}")


  _add: (asset) =>
    klass = if asset instanceof App.Models.Sound
      App.Views.AssetLibrarySound
    else if asset instanceof App.Models.Video
      App.Views.AssetLibraryVideo
    else
      App.Views.AssetLibraryElement

    view = new klass _.extend({model: asset}, @options.assetOptions)
    viewElement = view.render().el
    @views.push view

    if (index=@collection.indexOf(asset)) == 0
      @$el.prepend viewElement
    else
      @$el.children().eq(index-1).after(viewElement)



  _remove: (asset) ->
    view = @_getView(asset)
    view.remove()
    @views.splice(@views.indexOf(view), 1)


  _sort: ->
    @collection.each (asset) =>
      view = @_getView(asset)
      @$el.append view.el


  _getView: (asset) ->
    _.find @views, (view) -> view.model == asset
