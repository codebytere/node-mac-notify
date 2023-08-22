const notify = require('bindings')('notify.node')

module.exports = {
  sendSystemNotification: notify.sendSystemNotification,
}
