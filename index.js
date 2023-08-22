const notify = require('bindings')('notify.node')

const { EventEmitter } = require('events')

const listener = new EventEmitter()

listener.add = (name) => {
  notify.addListener(name, listener.emit.bind(listener))
}

listener.remove = (name) => {
  notify.removeListener(name)
}

module.exports = {
  listener,
  sendSystemNotification: notify.sendSystemNotification,
}
