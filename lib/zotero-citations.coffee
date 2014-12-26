module.exports = new class
  activate: ->
    atom.workspaceView.command "zotero-citations:scan", => @scan()

  cite: (key) ->
    return ''

  bibliography: ->
    return Object.keys(@citations).join("\n")

  citation: (matched, label, keys) =>
    console.log("Found link: #{matched} with label #{label} and keys #{keys}")
    _keys = keys.split(/\s*,\s*/)
    console.log("keys = " + JSON.stringify(_keys))
    for key in _keys
      return matched unless key[0] == '@'
    found = 0
    for key in _keys
      key = key.substring(1)
      console.log("key = " + JSON.stringify(key))
      console.log("citation = " + JSON.stringify(@citations))
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
      console.log(line)
      cited = line.replace(/\[([^\]]+)\]\(([^)]+)\)/g, @citation)
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
