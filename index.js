const notify = require('bindings')('notify.node')

const { EventEmitter } = require('events')

const listener = new EventEmitter()

function postNotification(name) {
  if (typeof name !== 'string') {
    throw new TypeError('name must be a String')
  }
  return notify.postNotification(name)
}

listener.add = function add(name) {
  return notify.addListener(name, listener.emit.bind(listener))
}

listener.remove = function remove(name) {
  return notify.removeListener(name)
}

listener.suspend = function suspend(name) {
  return notify.suspendListener(name)
}

listener.resume = function resume(name) {
  return notify.resumeListener(name)
}

module.exports = {
  listener,
  postNotification,
}
