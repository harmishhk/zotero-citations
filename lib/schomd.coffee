class Walker
  constructor: (@processor, @ast) ->
    @style = 'apa'
    @citations = {}
    @request = require('sync-request')

    @walk(@ast)

  walk: (ast) ->
    return unless ast.children

    filtered = []
    for node in ast.children
      node = @["_#{node.type}"].call(@, node) if @["_#{node.type}"]
      continue unless node
      @walk(node)
      filtered.push(node)
    ast.children = filtered

  citation: (id, caseInsensitive) ->
    return unless id
    atkeys = id.split(/\s*,\s*/)
    keys = (key.slice(1) for key in atkeys when key[0] in ['@', '#'])
    return unless atkeys.length == keys.length

    id += '/i' if caseInsensitive

    if !@citations[id]
      try
        res = @request('POST', 'http://localhost:23119/better-bibtex/schomd', {json: method: 'citation', params: [keys, {caseInsensitive, style: @style}]})
        res = JSON.parse(res.getBody('utf8'))
      catch err
        res = {error: err.message}

      switch
        when res.error
          console.log("failed to fetch #{id}: #{res.error}")
          @citations[id] = '??'

        when ! (res.result[0]?)
          console.log("no response for #{id}")
          @citations[id] = '??'

        else
          @citations[id] = res.result

    return @citations[id]

  _link: (ast) ->
    citation = @citation(ast.href)
    ast.children = @processor.parse(citation).children if citation
    return ast

  _linkReference: (ast) ->
    citation = @citation(ast.identifier, true)
    ast.children = @processor.parse(citation).children if citation
    return ast

module.exports = (processor) ->
  return (ast) ->
    (new Walker(processor, ast))
