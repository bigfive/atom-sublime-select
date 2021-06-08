packageName = "Sublime-Style-Column-Selection"

os = require 'os'
SublimeSelectEditorHandler = require './editor-handler.coffee'

defaultCfg = switch os.platform()
  when 'win32'
    selectKey:     'altKey'
    selectKeyName: 'Alt'
    mouseNum:      1
    mouseName:     "Left"
  when 'darwin'
    selectKey:     'altKey'
    selectKeyName: 'Alt'
    mouseNum:      1
    mouseName:     "Left"
  when 'linux'
    selectKey:     'shiftKey'
    selectKeyName: 'Shift'
    mouseNum:      1
    mouseName:     "Left"
  else
    selectKey:     'shiftKey'
    selectKeyName: 'Shift'
    mouseNum:      1
    mouseName:     "Left"

mouseNumMap =
  Left:   1,
  Middle: 2,
  Right:  3

selectKeyMap =
  Shift: 'shiftKey',
  Alt:   'altKey',
  Ctrl:  'ctrlKey',

selectKeyMap.Cmd = 'metaKey' if os.platform() == 'darwin'

selectKeyMap.None = null

inputCfg = defaultCfg

module.exports =

  config:
    cursorToCrosshair:
      title: "Change Cursor to Crosshair"
      description: "The mouse cursor will change to crosshair during column selection.
        IF empty, the default will be used \"false\"."
      type:'boolean'
      default: false

    mouseButtonTrigger:
      title: "Mouse Button"
      description: "The mouse button that will trigger column selection.
        If empty, the default will be used #{defaultCfg.mouseName} mouse button."
      type: 'string'
      enum: (key for key, value of mouseNumMap)
      default: defaultCfg.mouseName

    mouseKeyLogicOperator:
      title: "Logic Operator"
      description: "Should BOTH/EITHER \"Mouse Button\" And/Or \"Key\" trigger column selection?
        If empty or \"Select Key\" is set to empty or none, the default will be used \"And\"."
      type: 'string',
      enum: ['And','Or']
      default: 'And'

    selectKeyTrigger:
      title: "Select Key"
      description: "The key that will trigger column selection.
        If empty, the default will be used #{defaultCfg.selectKeyName} key."
      type: 'string'
      enum: (key for key, value of selectKeyMap)
      default: defaultCfg.selectKeyName

  activate: (state) ->
    @observers = []
    @editor_handler = null

    @observers.push atom.config.observe "#{packageName}.cursorToCrosshair", (newValue) =>
      inputCfg.cursorToCrosshair = newValue

    @observers.push atom.config.observe "#{packageName}.mouseButtonTrigger", (newValue) =>
      inputCfg.mouseName = newValue
      inputCfg.mouseNum = mouseNumMap[newValue]

    @observers.push atom.config.observe "#{packageName}.mouseKeyLogicOperator", (newValue) =>
      inputCfg.mouseKeyLogicOperator = newValue

    @observers.push atom.config.observe "#{packageName}.selectKeyTrigger", (newValue) =>
      inputCfg.selectKeyName = newValue
      inputCfg.selectKey = selectKeyMap[newValue]

    @observers.push atom.workspace.onDidChangeActivePaneItem @switch_editor_handler
    @observers.push atom.workspace.onDidAddPane              @switch_editor_handler
    @observers.push atom.workspace.onDidDestroyPane          @switch_editor_handler
    @switch_editor_handler()

  deactivate: ->
    @editor_handler?.unsubscribe()
    observer.dispose() for observer in @observers
    @observers = null
    @editor_handler = null

  switch_editor_handler: =>
    @editor_handler?.unsubscribe()
    active_editor = atom.workspace.getActiveTextEditor()
    if active_editor
      @editor_handler = new SublimeSelectEditorHandler(active_editor, inputCfg)
      @editor_handler.subscribe()
