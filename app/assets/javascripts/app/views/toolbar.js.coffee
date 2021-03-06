class App.Views.ToolbarView extends Backbone.View
  events:
    'click .scene':                                'addScene'
    'click .edit-text':                            'addText'
    'click .app-settings':                         'showSettings'
    'click .publish-settings':                     'showPublishSettings'
    'click .subscription-publish-settings':        'showSubscriptionPublishSettings'
    'click .background-sound':                     'showSceneBackgroundMusic'
    'click .compile':                              'compileStorybook'
    'click .logo':                                 'switchStorybook'
    'click .resource-archive':                     'archiveStorybookResources'
    'click .publish-to-subscription':              'publishToSubscription'
    'click .enqueue-for-subscription-publication': 'enqueueForSubscriptionPublication'
    'click .preview':          'showPreview'


  initialize: ->
    @_enableOnEvent 'can_add:text', '.edit-text'
    @_enableOnEvent 'can_add:scene', '.scene'
    @_enableOnEvent 'can_edit:storybook', '.settings'
    @_enableOnEvent 'can_run:simulator', '.preview'

    App.vent.on 'has_background_sound:scene', @_changeBackgroundSoundIcon

    App.vent.on 'activate:scene', (scene) =>
      @$('li').removeClass 'disabled'
      if scene.isMainMenu()
        @$('.edit-text').addClass 'disabled'


  addScene: (event) ->
    event.preventDefault()
    return if $(event.target).parent().hasClass('disabled') or $(event.target).hasClass('disabled')

    App.vent.trigger 'create:scene'


  addText: (event) ->
    App.trackUserAction 'Added text'

    event.preventDefault()
    return if $(event.target).parent().hasClass('disabled') or $(event.target).hasClass('disabled')

    App.vent.trigger 'create:widget', type: 'TextWidget'


  showSettings: (event) ->
    return if $(event.target).parent().hasClass('disabled') or $(event.target).hasClass('disabled')

    App.vent.trigger('show:settingsform')


  showPublishSettings: ->
    App.vent.trigger('show:publishSettings')


  showSubscriptionPublishSettings: ->
    App.vent.trigger('show:subscriptionPublishSettings')


  showSceneBackgroundMusic: ->
    App.vent.trigger('show:scenebackgroundsoundform')


  switchStorybook: ->
    App.trackUserAction 'Switched storybook'
    document.location.href = '/'


  compileStorybook: (event) ->
    platform = $(event.currentTarget).find('a').data('platform')
    App.currentSelection.get('storybook').compile(platform, App.currentUser)


  archiveStorybookResources: ->
    if App.currentUser.get('is_admin')
      App.currentSelection.get('storybook').archiveResources()

    else
      App.vent.trigger('show:message', 'error', "Only admin can archive resources of a storybook.")


  publishToSubscription: ->
    App.vent.trigger('publish:subscription')


  enqueueForSubscriptionPublication: ->
    App.currentSelection.get('storybook').enqueueForSubscriptionPublication(App.currentUser)


  showPreview: ->
    return if $(event.target).parent().hasClass('disabled') or $(event.target).hasClass('disabled')

    App.vent.trigger('show:preview')


  _enableOnEvent: (event, selector) ->
    App.vent.on event, (enable) =>
      element = @$(selector)
      if enable
        element.removeClass 'disabled'
      else
        element.addClass 'disabled'


  _changeBackgroundSoundIcon: (hasBackgroundSound) =>
    el = @$('.background-sound')
    klass = 'has-sound'
    if hasBackgroundSound
      el.addClass klass
    else
      el.removeClass klass
