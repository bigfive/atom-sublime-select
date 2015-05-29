os = require 'os'

inputCfg = switch os.platform()
  when 'win32'
    selectKey: 'altKey'
    mainMouseNum: 1
    middleMouseNum: 2
    enableMiddleMouse: true
  when 'darwin'
    selectKey: 'altKey'
    mainMouseNum: 1
    middleMouseNum: 2
    enableMiddleMouse: true
  when 'linux'
    selectKey: 'shiftKey'
    mainMouseNum: 2
    middleMouseNum: 2
    enableMiddleMouse: false
  else
    selectKey: 'shiftKey'
    mainMouseNum: 2
    middleMouseNum: 2
    enableMiddleMouse: false

module.exports =

  activate: (state) ->
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

      if _middleMouseDown(e) or _mainMouseAndKeyDown(e)
        resetState()
        mouseStartPos = _screenPositionForMouseEvent(e)
        mouseEndPos   = mouseStartPos
        e.preventDefault()
        return false

    onMouseMove = (e) ->
      if mouseStartPos
        e.preventDefault()
        if _middleMouseDown(e) or _mainMouseDown(e)
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
    _middleMouseDown = (e) ->
      inputCfg.enableMiddleMouse and e.which is inputCfg.middleMouseNum

    _mainMouseDown = (e) ->
      e.which is inputCfg.mainMouseNum

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
