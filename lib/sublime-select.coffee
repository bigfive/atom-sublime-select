{Subscriber} = require 'emissary'

module.exports =

  activate: (state) ->
    @subscribe atom.workspaceView.eachEditorView (editorView) =>
      @_handleLoad editorView

  deactivate: ->
    @unsubscribe()

  _handleLoad: (editorView) ->

    editor = editorView.getEditor()

    [altDown, mouseStart, mouseEnd, mouseEndPx, mouseStartPx] = []

    onKeyDown = (e) ->
      if e.which is 18
        altDown = true

    onKeyUp = (e) =>
      if e.which is 18
        altDown = false

    onMouseDown = (e) =>
      if altDown
        mouseStart = editor.getCursor().getBufferPosition()
        mouseStartPx = [e.screenX, e.screenY]
        mouseEnd = mouseStart
        mouseEndPx = mouseStartPx

    onMouseUp = (e) =>
      mouseStart = null
      mouseStartPx = null
      mouseEnd = null
      mouseEndPx = null

    onMouseMove = (e) =>
      if mouseStart
        mouseEnd = editor.getCursor().getBufferPosition()
        mouseEndPx = [e.screenX, e.screenY]
        selectBoxAroundCursors()

    selectBoxAroundCursors = =>
      newRanges = []

      if mouseStart.column is mouseEnd.column
        selectedBuffers = 0
      else
        # Find the pixel width of 1 column to caculate the number of columns to select
        columnWidthPx = editorView.pixelPositionForBufferPosition([mouseStart.row,mouseStart.column]).left / mouseStart.column
        selectedColumns = Math.round (mouseEndPx[0] - mouseStartPx[0]) / columnWidthPx

      for row in [mouseStart.row..mouseEnd.row]

        # Define a range for this row from the mouse start to the mouseEnd + selected columns
        range = [[row, mouseStart.column], [row, mouseStart.column + selectedColumns]]

        # Include a range if zero columns are selected
        # or if the line has text within the selection
        newRanges.push range if selectedColumns == 0 or editor.getTextInBufferRange(range).length > 0

      # Set the selected ranges
      if newRanges.length
        editor.setSelectedBufferRanges newRanges

    # Subscribe to the various things
    @subscribe editorView, 'keydown',   onKeyDown
    @subscribe editorView, 'keyup',     onKeyUp
    @subscribe editorView, 'mousedown', onMouseDown
    @subscribe editorView, 'mouseup',   onMouseUp
    @subscribe editorView, 'mousemove', onMouseMove

Subscriber.extend module.exports
