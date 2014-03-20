SublimeSelectView = require './sublime-select-view'

module.exports =
  sublimeSelectView: null

  activate: (state) ->
    @sublimeSelectView = new SublimeSelectView(state.sublimeSelectViewState)

  deactivate: ->
    @sublimeSelectView.destroy()

  serialize: ->
    sublimeSelectViewState: @sublimeSelectView.serialize()
