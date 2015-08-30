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

    bib = ''
    citekeys = Object.keys(@citations)
    citekeys.sort() if @style != 'ieee'

    # looping to have correct ordering
    for key in citekeys
      client = new XMLHttpRequest()
      req = {
        method: 'bibliography'
        params: [key, {style: @style}]
      }
      req = JSON.stringify(req)
      client.open('POST', 'http://localhost:23119/better-bibtex/schomd', false)
      client.send(req)

      res = JSON.parse(client.responseText)
      if res.error
        console.log(res.error)
      else
        bib += res.result

    return bib

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
      else if not (res.result[0]?)
        @citations[key] = '??'
      else
        @citations[key] = res.result[0]

    return @citations[key]

  cites: (keys) ->
    # check for valid keys
    validkeys = (key for key in keys when  ZoteroScan.cite(key) != '??')

    client = new XMLHttpRequest()
    req = {
      method: 'citation'
      params: [validkeys, {style: @style}]
    }
    req = JSON.stringify(req)
    client.open('POST', 'http://localhost:23119/better-bibtex/schomd', false)
    client.send(req)

    res = JSON.parse(client.responseText)
    if res.error
      console.log(res.error)
    else if res.result.length != validkeys.length
      console.log("some citation keys are invalid")
    else
      for key, index in validkeys
        @citations[key] = res.result[index]

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
    citekeys = []
    citedlines = []
    matchregex = /\[([^\]]*)\]\[([^\]]+)\]/g
    for line, lineno in editor.getBuffer().getLines()
      console.log(line)

      # only collect citation keys at fist run
      while (match = matchregex.exec(line))
        citedlines.push(lineno)
        for key in match[2].split(/\s*,\s*/)
          if key[0] == '@' and key.substring(1) not in citekeys
            citekeys.push(key.substring(1))
      continue if lineno in citedlines

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

    # now receive citations at once
    ZoteroScan.cites(citekeys)

    # replace citation text at second run
    for lineno in citedlines
      line = editor.getBuffer().getLines()[lineno]
      cited = line.replace(/\[([^\]]*)\]\[([^\]]+)\]/g, @citation)
      if line != cited
        editor.setTextInBufferRange([[lineno, 0], [lineno, line.length]], cited)

    if bibliography?.length == 2
      bib = @bibliography()
      # number the citations when style is ieee
      if @style == 'ieee'
        bib = bib.replace(/\[([^\]]*)\][^]*?a>/g, (match, key) => (match + @citations[key.substring(1)] + ' '))
      editor.setTextInBufferRange(bibliography, "[#bibliography]: #start\n#{bib.replace(/\n$/, '')}\n[#bibliography]: #end\n") if bib
