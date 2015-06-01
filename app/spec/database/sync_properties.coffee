describe "Database synchronized properties", ->

  store = null
  sync = null
  db = null
  context = null

  beforeEach (done) ->
    store = new ledger.storage.MemoryStore("local")
    sync = new ledger.storage.MemoryStore("sync")
    db = new ledger.database.Database('specs', store)
    db.load ->
      context = new ledger.database.contexts.Context(db, sync)
      do done

  it 'updates existing objects', (done) ->
    context.on 'insert:account', ->
      sync.substore('sync_account_0').set index: 0, name: "My Sync Spec Account", ->
        sync.emit 'pulled'
        context.on 'update:account', ->
          [account] = Account.find(index: 0, context).data()
          expect(account.get('name')).toBe("My Sync Spec Account")
          do done
    Account.create({index: 0, name: "My Spec Account"}, context).save()

  it 'creates missing objects', (done) ->
    sync.substore('sync_account_0').set index: 0, name: "My Sync Spec Account", ->
      sync.emit 'pulled'
      context.on 'insert:account', ->
        [account] = Account.find(index: 0, context).data()
        expect(account.get('name')).toBe("My Sync Spec Account")
        do done

  it 'creates data on sync store when an object is inserted', (done) ->
    sync.on 'set', (ev, items) ->
      expect(JSON.parse(items['sync.__sync_account_0_index'])).toBe(0)
      expect(JSON.parse(items['sync.__sync_account_0_name'])).toBe("My Greatest Account")
      do done
    Account.create(index: 0, name: "My Greatest Account", context).save()

  it 'updates sync store when an object is saved', (done) ->
    sync.once 'set', (ev, items) ->
      Account.findById(0, context).set('name', "My Whatever Account").save()
      sync.once 'set', (ev, items) ->
        expect(JSON.parse(items['sync.__sync_account_0_index'])).toBe(0)
        expect(JSON.parse(items['sync.__sync_account_0_name'])).toBe("My Whatever Account")
        do done
    Account.create(index: 0, name: "My Greatest Account", context).save()

  it 'deletes data from sync store when an object is deleted', (done) ->
    sync.once 'set', (ev, items) ->
      Account.findById(0, context).delete()
      sync.once 'remove', (ev, items...) ->
        expect(items).toContain('sync.__sync_account_0_index')
        expect(items).toContain('sync.__sync_account_0_name')
        do done
    Account.create(index: 0, name: "My Greatest Account", context).save()

  it 'pushes sync relations', (done) ->
    afterSave = ->
      sync.getAll (data) ->
        l data
        expect(data['__sync_account_0_name']).toBe('My tagged account')
        accountTagId = data['__sync_account_0_account_tag_id']
        expect(accountTagId).not.toBeUndefined()
        expect(data["__sync_account_tag_#{accountTagId}_name"]).toBe("My accounted tag")
        expect(data["__sync_account_tag_#{accountTagId}_color"]).toBe("#FF0000")
        do done
    sync.on 'set', _.debounce(afterSave, 50)
    account = Account.create(index: 0, name: "My tagged account", context).save()
    account.set('account_tag', AccountTag.create(name: "My accounted tag", color: "#FF0000", context).save()).save()

  it 'restores relationships', (done) ->