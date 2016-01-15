module.exports =
  class SublimeSelectEditorHandler
    constructor: (editor, inputCfg) ->
      @editor = editor
      @inputCfg = inputCfg
      @_resetState()
      @_setup_vars()

    subscribe: ->
      @selection_observer = @editor.onDidChangeSelectionRange @onRangeChange
      @editorElement.addEventListener 'mousedown',   @onMouseDown
      @editorElement.addEventListener 'mousemove',   @onMouseMove
      @editorElement.addEventListener 'mouseup',     @onMouseEventToHijack
      @editorElement.addEventListener 'mouseleave',  @onMouseEventToHijack
      @editorElement.addEventListener 'mouseenter',  @onMouseEventToHijack
      @editorElement.addEventListener 'contextmenu', @onMouseEventToHijack
      @editorElement.addEventListener 'blur',        @onBlur

    unsubscribe: ->
      @_resetState()
      @selection_observer.dispose()
      @editorElement.removeEventListener 'mousedown',   @onMouseDown
      @editorElement.removeEventListener 'mousemove',   @onMouseMove
      @editorElement.removeEventListener 'mouseup',     @onMouseEventToHijack
      @editorElement.removeEventListener 'mouseleave',  @onMouseEventToHijack
      @editorElement.removeEventListener 'mouseenter',  @onMouseEventToHijack
      @editorElement.removeEventListener 'contextmenu', @onMouseEventToHijack
      @editorElement.removeEventListener 'blur',        @onBlur

    # -------
    # Event Handlers
    # -------

    onMouseDown: (e) =>
      if @mouseStartPos
        e.preventDefault()
        return false

      if @_mainMouseAndKeyDown(e)
        @_resetState()
        @mouseStartPos = @_screenPositionForMouseEvent(e)
        @mouseEndPos   = @mouseStartPos
        e.preventDefault()
        return false

    onMouseMove: (e) =>
      if @mouseStartPos
        e.preventDefault()
        if @_mainMouseDown(e)
          @mouseEndPos = @_screenPositionForMouseEvent(e)
          @_selectBoxAroundCursors()
          return false
        if e.which == 0
          @_resetState()

    # Hijack all the mouse events while selecting
    onMouseEventToHijack: (e) =>
      if @mouseStartPos
        e.preventDefault()
        return false

    onBlur: (e) =>
      @_resetState()

    onRangeChange: (newVal) =>
      if @mouseStartPos and !newVal.selection.isSingleScreenLine()
        newVal.selection.destroy()
        @_selectBoxAroundCursors()

    # -------
    # Methods
    # -------

    _resetState: ->
      @mouseStartPos = null
      @mouseEndPos   = null

    _setup_vars: ->
      @editorBuffer ?= @editor.displayBuffer
      @editorElement ?= atom.views.getView @editor
      @editorComponent ?= @editorElement.component

    # I had to create my own version of @editorComponent.screenPositionFromMouseEvent
    # The @editorBuffer one doesnt quite do what I need
    _screenPositionForMouseEvent: (e) ->
      @_setup_vars()
      pixelPosition    = @editorComponent.pixelPositionForMouseEvent(e)
      targetTop        = pixelPosition.top
      targetLeft       = pixelPosition.left
      defaultCharWidth = @editorBuffer.defaultCharWidth
      row              = Math.floor(targetTop / @editorBuffer.getLineHeightInPixels())
      targetLeft       = Infinity if row > @editorBuffer.getLastRow()
      row              = Math.min(row, @editorBuffer.getLastRow())
      row              = Math.max(0, row)
      column           = Math.round (targetLeft) / defaultCharWidth
      return {row: row, column: column}

    # methods for checking mouse/key state against config
    _mainMouseDown: (e) ->
      e.which is @inputCfg.mouseNum

    _mainMouseAndKeyDown: (e) ->
      if @inputCfg.selectKey
        @_mainMouseDown(e) and e[@inputCfg.selectKey]
      else
        @_mainMouseDown(e)

    # Do the actual selecting
    _selectBoxAroundCursors: ->
      if @mouseStartPos and @mouseEndPos
        allRanges = []
        rangesWithLength = []

        for row in [@mouseStartPos.row..@mouseEndPos.row]
          # Define a range for this row from the @mouseStartPos column number to
          # the @mouseEndPos column number
          range = [[row, @mouseStartPos.column], [row, @mouseEndPos.column]]

          allRanges.push range
          if @editor.getTextInBufferRange(range).length > 0
            rangesWithLength.push range

        # If there are ranges with text in them then only select those
        # Otherwise select all the 0 length ranges
        if rangesWithLength.length
          @editor.setSelectedScreenRanges rangesWithLength
        else if allRanges.length
          @editor.setSelectedScreenRanges allRanges
