{WorkspaceView} = require 'atom'
AsciiArt = require '../lib/zotero-citations'

# Use the command `window:run-package-specs` (cmd-alt-ctrl-p) to run specs.
#
# To run a specific `it` or `describe` block add an `f` to the front (e.g. `fit`
# or `fdescribe`). Remove the `f` to unfocus the block.

describe "AsciiArt", ->
  promise = null
  beforeEach ->
    atom.workspaceView = new WorkspaceView()
    atom.workspace = atom.workspaceView.model
    promise = atom.packages.activatePackage('zotero-citations')
    waitsForPromise ->
      atom.workspace.open()

  it "scans", ->
    atom.workspaceView.trigger 'zotero-citations:scan'
    waitsForPromise ->
      promise
