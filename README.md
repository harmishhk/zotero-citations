Zotero Markdown citations
=========

This package adds Zotero support to Atom Markdown editing. To use it, you will need to have the [Better BibTeX](http://zotplus.github.io/better-bibtex/index.html) plugin installed in Zotero, and to have enabled 'Enable export by HTTP'.

After that, you can add citations to your document by including them as reference-style links to your bibtex citation key, e.g.
**\[\(Heyns, 2014\)\]\[@heyns2014\]**. You can put whatever you want in the first set of brackets (including nothing) and the package will fill out the citation when you execute 'Zotero Citations: Scan'

To generate a bibliography, add the following where you want it to appear on a line of its own:

**\[#bibliography\]: #**

The package will expand this to a full bibliography including the required fencing so it can be done again.

## Caveat

This is still very early work, put together over two days during christmas, you can expect there to be bugs. The real gruntwork of the citations is done by BBT, which is by now extensively tested, and this package is really not much code, but still: *it edits your text*. Undo ought to work, but still. Please report any issues at https://github.com/ZotPlus/zotero-citations
