module.exports = new class
  activate: ->
    atom.workspaceView.command "zotero-citations:scan", => @scan()

  bibliography: ->
    console.log("Generating bibliography for #{JSON.stringify(Object.keys(@citations))}")
    client = new XMLHttpRequest()
    req = {
      method: 'bibliography'
      params: [Object.keys(@citations)]
    }
    req = JSON.stringify(req)
    client.open('POST', 'http://localhost:23119/better-bibtex/schomd', false)
    client.send(req)

    res = JSON.parse(client.responseText)
    if res.error
      console.log(res.error)
      return null
    else
      return res.result

  cite: (key) ->
    if !@citations[key]?
      client = new XMLHttpRequest()
      req = {
        method: 'citation'
        params: [key]
      }
      req = JSON.stringify(req)
      client.open('POST', 'http://localhost:23119/better-bibtex/schomd', false)
      client.send(req)

      res = JSON.parse(client.responseText)
      if res.error
        console.log(res.error)
        @citations[key] = '??'
      else
        @citations[key] = res.result[0]

    return @citations[key]

  citation: (matched, label, keys) =>
    console.log("Found link: #{matched} with label #{label} and keys #{keys}")
    _keys = keys.split(/\s*,\s*/)
    for key in _keys
      return matched unless key[0] == '@'

    _label = (@cite(key.substring(1)) for key in _keys).join(';')
    _label = label.replace(/\?\?$/, '') + '??' if _label.match(/^[?;]*$/)
    return "[#{_label}](#{keys})"

  scan: ->
    console.log("Scanning...")
    editor = atom.workspace.getActivePaneItem()
    return unless editor

    @citations = Object.create(null)
    bibliography = null
    for line, lineno in editor.getBuffer().getLines()
      console.log(line)
      cited = line.replace(/\[([^\]]*)\]\(([^)]+)\)/g, @citation)
      if line != cited
        editor.setTextInBufferRange([[lineno, 0], [lineno, line.length]], cited)
        continue

      if line.match(/^\s*<bibliography>\s*$/)
        bibliography = [[lineno, 0]]
        continue

      if bibliography && line.match(/^\s*<\/bibliography>\s*$/)
        bibliography.push([lineno, line.length])
        continue

      if line.match(/^\s*<bibliography\/>\s*$/)
        bibliography = [[lineno, 0], [lineno, line.length]]
        continue

    if bibliography?.length == 2
      bib = @bibliography()
      editor.setTextInBufferRange(bibliography, bib) if bib
