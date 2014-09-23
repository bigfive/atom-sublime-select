{Subscriber} = require 'emissary'
os = require 'os'

inputCfg = switch os.platform()
  when 'darwin'
    key: 'altKey'
    mouse: 0
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
    @subscribe atom.workspaceView.eachEditorView (editorView) =>
      @_handleLoad editorView

  deactivate: ->
    @unsubscribe()

  _handleLoad: (editorView) ->
    editor     = editorView.getEditor()
    scrollView = editorView.find('.scroll-view')

    mouseStart  = null
    mouseEnd    = null
    columnWidth = null

    resetState = =>
      mouseStart  = null
      mouseEnd    = null
      columnWidth = null

    onMouseDown = (e) =>
      if (inputCfg.middleMouse and e.button is 1) or (e.button is inputCfg.mouse and e[inputCfg.key])
        resetState()
        columnWidth = calculateMonoSpacedCharacterWidth()
        mouseStart  = overflowableScreenPositionFromMouseEvent(e)
        mouseEnd    = mouseStart
        e.preventDefault()
        return false

    onMouseUp = (e) =>
      if mouseStart and (inputCfg.middleMouse and e.button is 1) or (e.button is inputCfg.mouse)
        resetState()
        e.preventDefault()
        return false

    onMouseMove = (e) =>
      if mouseStart
        mouseEnd = overflowableScreenPositionFromMouseEvent(e)
        selectBoxAroundCursors()
        e.preventDefault()
        return false

    onMouseLeave = (e) =>
      if mouseStart
        e.preventDefault()
        return false

    onMouseEnter = (e) =>
      if mouseStart
        e.preventDefault()
        return false

    onFocusOut = (e) =>
      resetState()

    # kill the right click menu when we start selecting
    onContextMenu = (e) =>
      if mouseStart
        e.preventDefault()
        return false

    # Create a span with an x in it and measure its width then remove it
    calculateMonoSpacedCharacterWidth = =>
      if scrollView
        span = document.createElement 'span'
        span.appendChild document.createTextNode('x')
        scrollView.append span
        size = span.offsetWidth
        span.remove()
        return size
      null

    # I had to create my own version of editorView.screenPositionFromMouseEvent
    # The editorView one doesnt quite do what I need
    overflowableScreenPositionFromMouseEvent = (e) =>
      { pageX, pageY }  = e
      offset            = editorView.scrollView.offset()
      editorRelativeTop = pageY - offset.top + editorView.scrollTop()
      row               = Math.floor editorRelativeTop / editorView.lineHeight
      column            = Math.round (pageX - offset.left) / columnWidth
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
        else
          editor.setSelectedBufferRanges allRanges

    # Subscribe to the various things
    @subscribe editorView, 'mousedown',   onMouseDown
    @subscribe editorView, 'mouseup',     onMouseUp
    @subscribe editorView, 'mousemove',   onMouseMove
    @subscribe editorView, 'mouseleave',  onMouseLeave
    @subscribe editorView, 'mouseenter',  onMouseEnter
    @subscribe editorView, 'contextmenu', onContextMenu
    @subscribe editorView, 'focusout',    onFocusOut

Subscriber.extend module.exports
