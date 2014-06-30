{Subscriber} = require 'emissary'

module.exports =

  activate: (state) ->
    @subscribe atom.workspaceView.eachEditorView (editorView) =>
      @_handleLoad editorView

  deactivate: ->
    @unsubscribe()

  _handleLoad: (editorView) ->
    editor     = editorView.getEditor()
    scrollView = editorView.find('.scroll-view')

    altDown    = false
    mouseStart = null
    mouseEnd   = null
    monoSizer  = null

    calculateMonoSpacedCharacterSize = =>
      if scrollView
        # Create a span with an x in it and measure its width and height
        # then remove it
        span = document.createElement 'span'
        span.appendChild document.createTextNode('x')
        scrollView.append span
        size = [span.offsetWidth, span.offsetHeight]
        span.remove()
        return size
      null

    onKeyDown = (e) =>
      if e.which is 18
        altDown = true

    onKeyUp = (e) =>
      if e.which is 18
        altDown = false

    onMouseDown = (e) =>
      if altDown
        monoSizer  = calculateMonoSpacedCharacterSize()
        mouseStart = editorView.screenPositionFromMouseEvent(e)
        mouseEnd   = mouseStart
        e.preventDefault()
        return false

    onMouseUp = (e) =>
      mouseStart = null
      mouseEnd = null

    onMouseMove = (e) =>
      if mouseStart
        mouseEnd = overflowableScreenPositionFromMouseEvent(e)
        selectBoxAroundCursors()
        e.preventDefault()
        return false

    onMouseleave = =>
      if mouseStart
        editorView.mouseup()

    # I had to create my own version of editorView.screenPositionFromMouseEvent
    # The editorView one doesnt quite do what I need
    overflowableScreenPositionFromMouseEvent = (e) =>
      if scrollView and monoSizer
        editorOffset = scrollView.offset()
        return {
          row:    Math.round( (e.pageY - editorOffset.top ) / monoSizer[1] ) + editorView.getFirstVisibleScreenRow(),
          column: Math.round( (e.pageX - editorOffset.left) / monoSizer[0] )
        }
      else
        return null

    selectBoxAroundCursors = =>
      if mouseStart and mouseEnd
        newRanges = []
        selectedColumns = 0

        if mouseStart.column != mouseEnd.column
          selectedColumns = mouseEnd.column - mouseStart.column

        for row in [mouseStart.row..mouseEnd.row]
          # Define a range for this row from the mouseStart coumn number to
          # the mouseEnd column number + selected columns
          range = [[row, mouseStart.column], [row, mouseStart.column + selectedColumns]]

          # Only include a range if zero columns are selected
          # or if the line has text within the selection
          if selectedColumns == 0 or editor.getTextInBufferRange(range).length > 0
            newRanges.push range

        # Set the selected ranges
        if newRanges.length
          editor.setSelectedBufferRanges newRanges

    # Subscribe to the various things
    @subscribe editorView, 'keydown',    onKeyDown
    @subscribe editorView, 'keyup',      onKeyUp
    @subscribe editorView, 'mousedown',  onMouseDown
    @subscribe editorView, 'mouseup',    onMouseUp
    @subscribe editorView, 'mousemove',  onMouseMove
    @subscribe editorView, 'mouseleave', onMouseleave

Subscriber.extend module.exports
