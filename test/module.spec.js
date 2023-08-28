const { expect } = require('chai')
const { postNotification, setState, getState, listener } = require('../index')

describe('node-mac-notify', () => {
  let key = ''

  afterEach(() => {
    if (key) {
      const success = listener.remove(key)
      expect(success).to.be.true
      key = ''
    }
  })

  it('should send a notification', () => {
    const success = postNotification('com.apple.some.test.key')
    expect(success).to.be.true
  })

  it('can suspend a notification', () => {
    key = 'com.apple.some.test.key'

    const added = listener.add(key)
    expect(added).to.be.true

    const suspended = listener.suspend(key)
    expect(suspended).to.be.true
  })

  it('should throw if a non-existent notification is suspended', () => {
    const failKey = 'com.apple.some.test.key'
    expect(() => {
      listener.suspend(failKey)
    }).to.throw(`No observer exists for ${failKey}`)
  })

  it('can resume a suspended a notification', () => {
    key = 'com.apple.some.test.key'

    const added = listener.add(key)
    expect(added).to.be.true

    const suspended = listener.suspend(key)
    expect(suspended).to.be.true

    const resumed = listener.resume(key)
    expect(resumed).to.be.true
  })

  it('should throw if a non-existent notification is resumed', () => {
    const failKey = 'com.apple.some.test.key'
    expect(() => {
      listener.resume(failKey)
    }).to.throw(`No observer exists for ${failKey}`)
  })

  it('can remove a notification', () => {
    const removedKey = 'com.apple.some.test.key'

    const added = listener.add(removedKey)
    expect(added).to.be.true

    const removed = listener.remove(removedKey)
    expect(removed).to.be.true
  })

  it('should throw if a non-existent notification is removed', () => {
    const failKey = 'com.apple.some.test.key'
    expect(() => {
      listener.remove(failKey)
    }).to.throw(`No observer exists for ${failKey}`)
  })

  it('should throw if the same notification is added twice', () => {
    key = 'com.apple.some.test.key'

    listener.add(key)
    expect(() => {
      listener.add(key)
    }).to.throw(`An observer is already observing ${key}`)
  })

  it('can listen for notifications', (done) => {
    key = 'com.apple.special.notify.Test'

    listener.add(key)
    listener.on(key, () => {
      done()
    })

    const success = postNotification(key)
    expect(success).to.be.true
  })

  it('throws when setting state with an invalid state', () => {
    expect(() => {
      setState('i.do.not.exist', 'ping')
    }).to.throw('state must be a BigInt')
  })

  it('throws when setting state on a non-existent notification', () => {
    expect(() => {
      setState('i.do.not.exist', 1n)
    }).to.throw(`No registration token exists for ${key}`)
  })

  it('can set state for a notification', () => {
    key = 'com.apple.state.test.key'

    const added = listener.add(key)
    expect(added).to.be.true

    const success = setState(key, 5n)
    expect(success).to.be.true

    const state = getState(key)
    expect(state).to.equal(5n)
  })
})
