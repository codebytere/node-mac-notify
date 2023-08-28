const notify = require('bindings')('notify.node')

const { EventEmitter } = require('events')

const listener = new EventEmitter()

function postNotification(name) {
  if (typeof name !== 'string') {
    throw new TypeError('name must be a String')
  }
  return notify.postNotification(name)
}

function setState(name, state) {
  if (typeof name !== 'string') {
    throw new TypeError('name must be a String')
  }
  if (typeof state !== 'bigint') {
    throw new TypeError('state must be a BigInt')
  }
  return notify.setState(name, state)
}

function getState(name) {
  if (typeof name !== 'string') {
    throw new TypeError('name must be a String')
  }
  return notify.getState(name)
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
  setState,
  getState,
}
