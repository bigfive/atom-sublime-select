os = require 'os'

inputCfg = switch os.platform()
  when 'win32'
    key: 'altKey'
    mouse: 1
    middleMouse: true
  when 'darwin'
    key: 'altKey'
    mouse: 1
    middleMouse: true
  when 'linux'
    key: 'shiftKey'
    mouse: 2
    middleMouse: false
  else
    key: 'shiftKey'
    mouse: 2
    middleMouse: true

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

    mouseStart  = null
    mouseEnd    = null

    resetState = =>
      mouseStart  = null
      mouseEnd    = null

    onMouseDown = (e) =>
      if mouseStart
        e.preventDefault()
        return false

      if (inputCfg.middleMouse and e.which is 2) or (e.which is inputCfg.mouse and e[inputCfg.key])
        resetState()
        mouseStart  = _screenPositionForMouseEvent(e)
        mouseEnd    = mouseStart
        e.preventDefault()
        return false

    onMouseMove = (e) =>
      if mouseStart
        if (inputCfg.middleMouse and e.which is 2) or (e.which is inputCfg.mouse)
          mouseEnd = _screenPositionForMouseEvent(e)
          selectBoxAroundCursors()
          e.preventDefault()
          return false
        if e.which == 0
          resetState()

    # Hijack all the mouse events when selecting
    hikackMouseEvent = (e) =>
      if mouseStart
        e.preventDefault()
        return false

    onBlur = (e) =>
      resetState()

    # I had to create my own version of editorComponent.screenPositionFromMouseEvent
    # The editorBuffer one doesnt quite do what I need
    _screenPositionForMouseEvent = (e) =>
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

    # Do the actual selecting
    selectBoxAroundCursors = =>
      if mouseStart and mouseEnd
        allRanges = []
        rangesWithLength = []

        for row in [mouseStart.row..mouseEnd.row]
          # Define a range for this row from the mouseStart column number to
          # the mouseEnd column number
          range = editor.bufferRangeForScreenRange [[row, mouseStart.column], [row, mouseEnd.column]]

          allRanges.push range
          if editor.getTextInBufferRange(range).length > 0
            rangesWithLength.push range

        # If there are ranges with text in them then only select those
        # Otherwise select all the 0 length ranges
        if rangesWithLength.length
          editor.setSelectedBufferRanges rangesWithLength
        else if allRanges.length
          editor.setSelectedBufferRanges allRanges

    # Subscribe to the various things
    editorElement.onmousedown   = onMouseDown
    editorElement.onmousemove   = onMouseMove
    editorElement.onmouseup     = hikackMouseEvent
    editorElement.onmouseleave  = hikackMouseEvent
    editorElement.onmouseenter  = hikackMouseEvent
    editorElement.oncontextmenu = hikackMouseEvent
    editorElement.onblur        = onBlur
