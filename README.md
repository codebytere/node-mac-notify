[![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](https://lbesson.mit-license.org/)
 [![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com) [![Actions Status](https://github.com/codebytere/node-mac-notify/workflows/Test/badge.svg)](https://github.com/codebytere/node-mac-notify/actions)

# node-mac-notify

## Overview

```js
$ npm i node-mac-notify
```

This native Node.js module allows you to send and monitor Darwin-style notifications on macOS.

The Darwin-style notification API allow processes to exchange stateless notification events.	Processes post notifications to a single system-wide notification server, which then distributes notifications to client processes that have registered to receive those notifications, including processes run by other users.

Notifications are associated with names in a namespace shared by all clients of the system.  Clients may post notifications for names, and may monitor names for posted notifications.  Clients may request notification delivery by a number of different methods.

Clients desiring to monitor names in the notification system must register with the system, providing a name and other information required for the desired notification delivery method. Clients that use signal-based notification should be aware that signals are not delivered to a process while it is running in a signal handler. This may affect the delivery of signals in close succession.

Notifications may be coalesced in some cases.  Multiple events posted for a name in rapid succession may result in a single notification sent to clients registered for notification for that name.

See [Apple Documentation](https://developer.apple.com/documentation/darwinnotify) or the [Unix Man Page](https://www.unix.com/man-page/osx/3/notify).

## API

### `notify.postNotification(name)`

* `name` String - The event name to post a notification for.

Returns `Boolean` - Whether or not the notification was successfully posted.

Example:
```js
const { postNotification } = require('node-mac-notify')

const name = 'my-event-name'

const posted = postNotification(name)
console.log(`Notification for ${name} was ${posted ? 'successfully' : 'unsuccessfully'} posted.`)
```

This method wraps [`notify_post`](https://www.unix.com/man-page/osx/3/notify_post).

### `notify.listener`

This module exposes an `EventEmitter`, which can be used to listen and manipulate notifications.

#### `notify.listener.add(name)`

* `name` String - The event name to add an event handler for.

Registers a event handler for the event with name `name`.

```js
const { listener } = require('node-mac-notify')

const name = 'my-event-name'

const added = listener.add(name)
console.log(`Event handler for ${name} was ${added ? 'successfully' : 'unsuccessfully'} added.`)

listener.on(name, () => {
  console.log(`An notification was posted for ${name}!`)
})
```

This method wraps [`notify_register_dispatch`](https://www.unix.com/man-page/osx/3/notify_register_dispatch).


#### `notify.listener.remove(name)`

* `name` String - The event name to remove an existing event handler for.

Removes a event handler for the event with name `name`.

```js
const { listener } = require('node-mac-notify')

const name = 'my-event-name'

listener.add(name)

const removed = listener.remove(name);
console.log(`Event handler for ${name} was ${removed ? 'successfully' : 'unsuccessfully'} removed.`)
```

This method wraps [`notify_cancel`](https://www.unix.com/man-page/osx/3/notify_cancel).
