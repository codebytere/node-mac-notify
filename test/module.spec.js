const { expect } = require('chai')
const { postNotification, listener } = require('../index')

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
})
