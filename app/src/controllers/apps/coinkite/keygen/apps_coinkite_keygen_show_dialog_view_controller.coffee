class @AppsCoinkiteKeygenShowDialogViewController extends ledger.common.DialogViewController

  view:
    xpubInput: '#xpub_input'
    signatureInput: '#signature_input'

  onAfterRender: ->
    super
    @view.xpubInput.val @params.xpub
    @view.signatureInput.val @params.signature