{CompositeDisposable} = require 'atom'

module.exports = ZoteroScan =
  subscriptions: null

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'zotero-citations:scan': => @scan()
    @subscriptions.add atom.commands.add 'atom-workspace', 'zotero-citations:pick': => @pick()

  deactivate:
    @subscriptions.dispose() if @subscriptions

  pick: ->
    req = new XMLHttpRequest()
    req.open('GET', 'http://localhost:23119/better-bibtex/cayw?format=atom-zotero-citations', false)
    req.send(null)

    atom.workspace.getActiveTextEditor()?.insertText(req.responseText) if req.status == 200 && req.responseText

  bibliography: ->
    console.log("Generating bibliography for #{JSON.stringify(Object.keys(@citations))}")
    client = new XMLHttpRequest()
    req = {
      method: 'bibliography'
      params: [Object.keys(@citations), {style: @style}]
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
    console.log("label lookup for #{key}")
    if !@citations[key]?
      client = new XMLHttpRequest()
      req = {
        method: 'citation'
        params: [key, {style: @style}]
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

    _label = (ZoteroScan.cite(key.substring(1)) for key in _keys).join(';')
    _label = label.replace(/\?\?$/, '') + '??' if _label.match(/^[?;]*$/)
    return "[#{_label}][#{keys}]"

  styleRE: /^\[#citation-style\]: #([^\s]+)$/

  scan: ->
    console.log("Scanning...")
    editor = atom.workspace.getActivePaneItem()
    return unless editor

    @style = 'apa'
    @citations = Object.create(null)
    bibliography = null
    for line, lineno in editor.getBuffer().getLines()
      console.log(line)
      cited = line.replace(/\[([^\]]*)\]\[([^\]]+)\]/g, @citation)
      if line != cited
        editor.setTextInBufferRange([[lineno, 0], [lineno, line.length]], cited)
        continue

      if style = @styleRE.exec(line)
        @style = style[1]

      if line.match(/^\[#bibliography\]: #start\s*$/)
        bibliography = [[lineno, 0]]
        continue

      if line.match(/^\[#bibliography\]: #end\s*$/)
        bibliography.push([lineno, line.length])
        continue

      if line.match(/^\[#bibliography\]: #\s*$/)
        bibliography = [[lineno, 0], [lineno, line.length]]
        continue

    if bibliography?.length == 2
      bib = @bibliography()
      editor.setTextInBufferRange(bibliography, "[#bibliography]: #start\n#{bib.replace(/\n$/, '')}\n[#bibliography]: #end\n") if bib
