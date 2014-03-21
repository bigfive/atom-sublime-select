{View} = require 'atom'

module.exports =
class SublimeSelectView extends View

  @content: ->
    @span ""

  initialize: (serializeState) ->
    atom.workspaceView.command "sublime-select:start", => @start()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @stop()

  stop: ->
    atom.workspaceView.off 'mousedown',    @onMouseDown
    atom.workspaceView.off 'mouseup',      @onMouseUp
    atom.workspaceView.off 'cursor:moved', @onMouseMove

  start: ->
    atom.workspaceView.on 'mousedown',    @onMouseDown
    atom.workspaceView.on 'mouseup',      @onMouseUp
    atom.workspaceView.on 'cursor:moved', @onMouseMove

  onMouseDown: (e) =>
    @mouseStart = atom.workspace.getActiveEditor().getCursor().selection.getBufferRange().start
    @mouseEnd = @mouseStart

  onMouseUp: (e) =>
    @mouseStart = null
    @mouseEnd = null
    @stop()

  onMouseMove: (e) =>
    if @mouseStart?
      @mouseEnd = atom.workspace.getActiveEditor().getCursor().getBufferPosition()
      @selectBoxAroundCursors()

  selectBoxAroundCursors: =>
    newRanges = []
    editor = atom.workspace.getActiveEditor()
    zeroColumns = @mouseStart.column is @mouseEnd.column

    for row in [@mouseStart.row..@mouseEnd.row]
      range = [[row, @mouseStart.column], [row, @mouseEnd.column]]

      # Include a range if zero columns are selected
      # or if the line has text within the selection
      newRanges.push range if zeroColumns or editor.getTextInBufferRange(range).length > 0

    editor.setSelectedBufferRanges newRanges
