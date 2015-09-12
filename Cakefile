{exec} = require 'child_process'

task 'test', 'verify coffeescript', ->
  exec 'coffeelint *.coffee lib/*.coffee', (err, stdout, stderr) ->
    console.log stdout + stderr
    throw err if err
  exec 'coffee test.coffee', (err, stdout, stderr) ->
    console.log stdout + stderr
    throw err if err
