
@ledger.m2fa ?= {}

# Wrapper around the pairing API. This class defines the followings events:
#   - 'complete'
#   - 'cancel'
#   - 'joined'
#   - 'leave'
class @ledger.m2fa.PairingRequest extends @EventEmitter

  constructor: (pairindId, promise, client) ->
    @pairingId = pairindId
    @_client = client
    promise.then(
      (result) ->
        l result
      ,
      (err) ->
        e err
      ,
      (progress) ->
        @emit progress
    ).done()
    @_client.on 'm2fa.disconnect'
    @_promise = promise

  onComplete: (cb) -> @_onComplete = cb

  cancel: () ->
    @_promise = null
    @_client.stopIfNeccessary()
    @_onComplete = null
    @emit 'cancel'
