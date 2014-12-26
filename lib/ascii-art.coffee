module.exports =
  activate: ->
    atom.workspaceView.command "ascii-art:convert", => @convert()

  convert: ->
    # This assumes the active pane item is an editor
    selection = atom.workspace.getActiveEditor().getSelection()

    figlet = require 'figlet'
    figlet selection.getText(), {font: "Larry 3D 2"}, (error, asciiArt) ->
      if error
        console.error(error)
      else
        selection.insertText("\n" + asciiArt + "\n")
  cite: (key) ->
    return ''

  bibliography: ->
    return Object.keys(@citations).join("\n")

  citation: (matched, label, keys) ->
    console.log("Found link: #{matched}")
    _keys = keys.split(/\s*,\s*/)
    return matched if _keys.length == 0
    for key in _keys
      return matched unless key[0] == '@'
    found = 0
    for key in _keys
      key = key.substring(1)
      @citations[key] ?= @cite(key)
      found += 1 if @citations[key] != ''
    if found == 0
      label = label.replace(/\?\?$/, '') + '??'
    else
      label = ((if @citations[key] == '' then '??' else @citations[key]) for key in _keys).join(';')
    return "[#{label}](#{keys})"

  scan: ->
    console.log("Scanning...")
    editor = atom.workspace.getActivePaneItem()
    return unless editor

    @citations = Object.create(null)
    bibliography = null
    for line, lineno in editor.getBuffer().getLines()
      cited = line.replace(/\[([^\]]*])\]\(([^\)]*])\)/g, @citation)
      if line != cited
        editor.setTextInBufferRange([[lineno, 0], [lineno, line.length]], cited)
        continue

      if line.match(/^\s*<bibliography>\s*$/)
        bibliography = [[lineno, 0]]
        continue

      if bibliography && line.match(/^\s*<\/bibliography>\s*$/)
        bibliography.push([lineno, line.length])
        continue

    if bibliography?.length == 2
      editor.setTextInBufferRange(bibliography, @bibliography())
