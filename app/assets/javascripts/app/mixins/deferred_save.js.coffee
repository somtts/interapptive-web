App.Mixins.DeferredSave =
  _SAVE_TIMER: null

  # Override save with a call to `deferredSave` to
  # - prevent `save` being called once to create the record, and then again before
  # the ajax request returns (which would create two records instead of one)
  # - debounce calls to `save` so we don't save too often
  # This does not take into account any parameters. Use `set` to change the
  # attributes, followed by a call to `save` without parameters.
  deferredSave: ->
    deferBy = 1000
    if @isNew()
      if @_duringFirstSave
        window.clearTimeout @_SAVE_TIMER
        @_SAVE_TIMER = window.setTimeout(@deferredSave.bind(@), deferBy)
      else
        @_duringFirstSave = true
        @_actualSave()
    else
      window.clearTimeout @_SAVE_TIMER
      @_SAVE_TIMER = window.setTimeout(@_actualSave.bind(@), deferBy)


  _actualSave: ->
    Backbone.Model.prototype.save.apply @
