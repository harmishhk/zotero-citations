#!/usr/bin/env coffee

fs = require('fs')
mdast = require('mdast')
schomd = require('../lib/schomd')

markdown = fs.readFileSync('test/test.md', 'utf-8')
console.log(mdast.use(schomd).process(markdown))

#ast = mdast.parse('[](@Tay)')
#console.log(JSON.stringify(ast, null, 2))
