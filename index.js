const notify = require('bindings')('notify.node')

const { EventEmitter } = require('events')

const listener = new EventEmitter()

listener.setup = (name) => {
  notify.setupListener(name, listener.emit.bind(listener))
}

listener.remove = (name) => {
  notify.removeListener(name)
}

checkNotification = (name) => {
  if (typeof name !== 'string') {
    throw new TypeError('Expected a string')
  }

  return notify.checkNotification(token)
}

module.exports = {
  listener,
  checkNotification: notify.checkNotification,
  sendSystemNotification: notify.sendSystemNotification,
}
