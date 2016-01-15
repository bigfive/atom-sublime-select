os = require 'os'

packageName = "Sublime-Style-Column-Selection"

defaultCfg = switch os.platform()
  when 'win32'
    selectKey: 'altKey'
    selectKeyName: 'Alt'
    mouseNum: 1
    mouseName: "Left"
  when 'darwin'
    selectKey: 'altKey'
    selectKeyName: 'Alt'
    mouseNum: 1
    mouseName: "Left"
  when 'linux'
    selectKey: 'shiftKey'
    selectKeyName: 'Shift'
    mouseNum: 1
    mouseName: "Left"
  else
    selectKey: 'shiftKey'
    selectKeyName: 'Shift'
    mouseNum: 1
    mouseName: "Left"

mouseNumMap =
  Left: 1,
  Middle: 2,
  Right: 3

selectKeyMap =
  Shift: 'shiftKey',
  Alt: 'altKey',
  Ctrl: 'ctrlKey'

inputCfg = defaultCfg

module.exports =
  config:
    mouseButtonTrigger:
      title: "Mouse Button"
      description: "The mouse button that will trigger column selection.
        If empty, the default will be used #{defaultCfg.mouseName} mouse button."
      type: 'string'
      enum: ['Left', 'Middle', 'Right']
      default: defaultCfg.mouseName
    selectKeyTrigger:
      ttile: "Select Key"
      description: "The key that will trigger column selection.
        If empty, the default will be used #{defaultCfg.selectKeyName} key."
      type: 'string'
      enum: ['Alt', 'Shift', 'Ctrl']
      default: defaultCfg.selectKeyName

  activate: (state) ->
    atom.config.observe "#{packageName}.mouseButtonTrigger", (newValue) =>
      inputCfg.mouseName = newValue
      inputCfg.mouseNum = mouseNumMap[newValue]

    atom.config.observe "#{packageName}.selectKeyTrigger", (newValue) =>
      inputCfg.selectKeyName = newValue
      inputCfg.selectKey = selectKeyMap[newValue]

    atom.workspace.observeTextEditors (editor) =>
      @_handleLoad editor

  deactivate: ->
    @unsubscribe()

  _handleLoad: (editor) ->
    editorBuffer = editor.displayBuffer
    editorElement = atom.views.getView editor
    editorComponent = editorElement.component

    mouseStartPos  = null
    mouseEndPos    = null

    resetState = ->
      mouseStartPos  = null
      mouseEndPos    = null

    onMouseDown = (e) ->
      if mouseStartPos
        e.preventDefault()
        return false

      if _mainMouseAndKeyDown(e)
        resetState()
        mouseStartPos = _screenPositionForMouseEvent(e)
        mouseEndPos   = mouseStartPos
        e.preventDefault()
        return false

    onMouseMove = (e) ->
      if mouseStartPos
        e.preventDefault()
        if _mainMouseDown(e)
          mouseEndPos = _screenPositionForMouseEvent(e)
          _selectBoxAroundCursors()
          return false
        if e.which == 0
          resetState()

    # Hijack all the mouse events while selecting
    hijackMouseEvent = (e) ->
      if mouseStartPos
        e.preventDefault()
        return false

    onBlur = (e) ->
      resetState()

    onRangeChange = (newVal) ->
      if mouseStartPos and !newVal.selection.isSingleScreenLine()
        newVal.selection.destroy()
        _selectBoxAroundCursors()

    # I had to create my own version of editorComponent.screenPositionFromMouseEvent
    # The editorBuffer one doesnt quite do what I need
    _screenPositionForMouseEvent = (e) ->
      if editorComponent is null
        editorComponent = atom.views.getView(editor).component
        
      pixelPosition    = editorComponent.pixelPositionForMouseEvent(e)
      targetTop        = pixelPosition.top
      targetLeft       = pixelPosition.left
      defaultCharWidth = editorBuffer.defaultCharWidth
      row              = Math.floor(targetTop / editorBuffer.getLineHeightInPixels())
      targetLeft       = Infinity if row > editorBuffer.getLastRow()
      row              = Math.min(row, editorBuffer.getLastRow())
      row              = Math.max(0, row)
      column           = Math.round (targetLeft) / defaultCharWidth
      return {row: row, column: column}

    # methods for checking mouse/key state against config
    _mainMouseDown = (e) ->
      e.which is inputCfg.mouseNum

    _keyDown = (e) ->
      e[inputCfg.selectKey]

    _mainMouseAndKeyDown = (e) ->
      _mainMouseDown(e) and e[inputCfg.selectKey]

    # Do the actual selecting
    _selectBoxAroundCursors = ->
      if mouseStartPos and mouseEndPos
        allRanges = []
        rangesWithLength = []

        for row in [mouseStartPos.row..mouseEndPos.row]
          # Define a range for this row from the mouseStartPos column number to
          # the mouseEndPos column number
          range = [[row, mouseStartPos.column], [row, mouseEndPos.column]]

          allRanges.push range
          if editor.getTextInBufferRange(range).length > 0
            rangesWithLength.push range

        # If there are ranges with text in them then only select those
        # Otherwise select all the 0 length ranges
        if rangesWithLength.length
          editor.setSelectedScreenRanges rangesWithLength
        else if allRanges.length
          editor.setSelectedScreenRanges allRanges

    # Subscribe to the various things
    editor.onDidChangeSelectionRange onRangeChange
    editorElement.onmousedown   = onMouseDown
    editorElement.onmousemove   = onMouseMove
    editorElement.onmouseup     = hijackMouseEvent
    editorElement.onmouseleave  = hijackMouseEvent
    editorElement.onmouseenter  = hijackMouseEvent
    editorElement.oncontextmenu = hijackMouseEvent
    editorElement.onblur        = onBlur
