const { expect } = require('chai')
const { postNotification, listener } = require('../index')

describe('node-mac-notify', () => {
  let key = ''

  afterEach(() => {
    if (key) {
      const success = listener.remove(key)
      expect(success).to.be.true
    }
  })

  it('should send a notification', () => {
    const status = postNotification('com.apple.some.test.key')
    expect(status).to.equal(0)
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

    const status = postNotification(key)
    expect(status).to.equal(0)
  })
})
