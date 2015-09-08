CodeContext = require './code-context'
grammarMap = require './grammars'

module.exports =
class CodeContextBuilder
  # Public
  #
  # @view - a #{ScriptView} instance
  constructor: (@view) ->

  # Public: Builds code context for specified argType
  #
  # editor - Atom's #{TextEditor} instance
  # argType - {String} with one of the following values:
  #
  # * "Selection Based" (default)
  # * "Line Number Based",
  # * "File Based"
  #
  # returns a #{CodeContext} object
  buildCodeContext: (editor, argType='Selection Based') ->
    return unless editor?

    codeContext = @initCodeContext(editor)

    codeContext.argType = argType

    if argType == 'Line Number Based'
      editor.save()
    else if codeContext.selection.isEmpty() and codeContext.filepath?
      codeContext.argType = 'File Based'
      editor.save()

    # Selection and Line Number Based runs both benefit from knowing the current line
    # number
    unless argType == 'File Based'
      cursor = editor.getLastCursor()
      codeContext.lineNumber = cursor.getScreenRow() + 1

    return codeContext

  initCodeContext: (editor) ->
    filename = editor.getTitle()
    filepath = editor.getPath()
    selection = editor.getLastSelection()

    # If the selection was empty "select" ALL the text
    # This allows us to run on new files
    if selection.isEmpty()
      textSource = editor
    else
      textSource = selection

    codeContext = new CodeContext(filename, filepath, textSource)
    codeContext.selection = selection
    codeContext.shebang = @getShebang(editor)

    lang = @getLang(editor)

    if @validateLang lang
      codeContext.lang = lang

    return codeContext

  getShebang: (editor) ->
    text = editor.getText()
    lines = text.split("\n")
    firstLine = lines[0]
    return unless firstLine.match(/^#!/)

    firstLine.replace(/^#!\s*/, '')

  getLang: (editor) ->
    editor.getGrammar().name

  validateLang: (lang) ->
    valid = true
    # Determine if no language is selected.
    if lang is 'Null Grammar' or lang is 'Plain Text'
      @view.showNoLanguageSpecified()
      valid = false

    # Provide them a dialog to submit an issue on GH, prepopulated with their
    # language of choice.
    else if not (lang of grammarMap)
      @view.showLanguageNotSupported(lang)
      valid = false

    return valid
