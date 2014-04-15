{Subscriber} = require 'emissary'

module.exports =

  activate: (state) ->
    @subscribe atom.workspaceView.eachEditorView (editorView) =>
      @_handleLoad editorView

  deactivate: ->
    @unsubscribe()

  _handleLoad: (editorView) ->

    editor = editorView.getEditor()

    [altDown, mouseStart, mouseEnd] = []

    onKeyDown = (e) ->
      if e.which is 18
        altDown = true

    onKeyUp = (e) =>
      if e.which is 18
        altDown = false

    onMouseDown = (e) =>
      if altDown
        mouseStart = editor.getCursor().selection.getBufferRange().start
        mouseEnd = mouseStart

    onMouseUp = (e) =>
      mouseStart = null
      mouseEnd = null

    onMouseMove = (e) =>
      if mouseStart
        mouseEnd = editor.getCursor().getBufferPosition()
        selectBoxAroundCursors()

    selectBoxAroundCursors = =>
      newRanges = []

      zeroColumns = mouseStart.column is mouseEnd.column

      for row in [mouseStart.row..mouseEnd.row]
        range = [[row, mouseStart.column], [row, mouseEnd.column]]

        # Include a range if zero columns are selected
        # or if the line has text within the selection
        newRanges.push range if zeroColumns or editor.getTextInBufferRange(range).length > 0

      editor.setSelectedBufferRanges newRanges

    @subscribe editorView, 'keydown',      onKeyDown
    @subscribe editorView, 'keyup',        onKeyUp
    @subscribe editorView, 'mousedown',    onMouseDown
    @subscribe editorView, 'mouseup',      onMouseUp
    @subscribe editorView, 'cursor:moved', onMouseMove

Subscriber.extend module.exports
