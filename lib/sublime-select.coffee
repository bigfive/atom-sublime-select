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
    columnWidth  = null

    calculateMonoSpacedCharacterWidth = =>
      if scrollView
        # Create a span with an x in it and measure its width then remove it
        span = document.createElement 'span'
        span.appendChild document.createTextNode('x')
        scrollView.append span
        size = span.offsetWidth
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
        columnWidth = calculateMonoSpacedCharacterWidth()
        mouseStart  = overflowableScreenPositionFromMouseEvent(e)
        mouseEnd    = mouseStart
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

    onMouseleave = (e) =>
      if altDown
        e.preventDefault()
        return false

    # I had to create my own version of editorView.screenPositionFromMouseEvent
    # The editorView one doesnt quite do what I need
    overflowableScreenPositionFromMouseEvent = (e) =>
      { pageX, pageY }  = e
      offset            = editorView.scrollView.offset()
      editorRelativeTop = pageY - offset.top + editorView.scrollTop()
      row               = Math.floor editorRelativeTop / editorView.lineHeight
      column            = Math.round (pageX - offset.left) / columnWidth
      return {row: row, column: column}

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
        else
          editor.setSelectedBufferRanges allRanges

    # Subscribe to the various things
    @subscribe editorView, 'keydown',    onKeyDown
    @subscribe editorView, 'keyup',      onKeyUp
    @subscribe editorView, 'mousedown',  onMouseDown
    @subscribe editorView, 'mouseup',    onMouseUp
    @subscribe editorView, 'mousemove',  onMouseMove
    @subscribe editorView, 'mouseleave', onMouseleave

Subscriber.extend module.exports
