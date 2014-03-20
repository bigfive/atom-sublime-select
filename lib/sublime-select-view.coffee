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
    for row in [@mouseStart.row..@mouseEnd.row]
      newRanges.push [[row, @mouseStart.column], [row, @mouseEnd.column]]
    atom.workspace.getActiveEditor().setSelectedBufferRanges newRanges
