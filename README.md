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


### `notify.getState(name)`

* `name` String - The event name to fetch the current state for.

Returns [`BigInt`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt) - The current state of `name`.

Example:
```js
const { getState, listener } = require('node-mac-notify')

const name = 'my-event-name'

const added = listener.add(name)
console.log(`Event handler for ${name} was ${added ? 'successfully' : 'unsuccessfully'} added.`)

const state = getState(name)
console.log(`Current state of ${name} is ${state}`)
```

This method wraps [`notify_get_state`](https://www.unix.com/man-page/osx/3/notify_get_state).

### `notify.setState(name, state)`

* `name` String - The event name to set the state for.
* `state` [BigInt](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/BigInt) - Integer value of the new state.

Returns `Boolean` - Whether or not the new state was successfully set for `name`.

Example:
```js
const { getState, listener } = require('node-mac-notify')

const name = 'my-event-name'

const added = listener.add(name)
console.log(`Event handler for ${name} was ${added ? 'successfully' : 'unsuccessfully'} added.`)

const newState = 5
const success = setState(name, newState)
console.log(`State for ${name} was ${success ? 'successfully' : 'unsuccessfully'} set to ${newState}.`)
```

This method wraps [`notify_set_state`](https://www.unix.com/man-page/osx/3/notify_set_state).

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

const removed = listener.remove(name)
console.log(`Event handler for ${name} was ${removed ? 'successfully' : 'unsuccessfully'} removed.`)
```

This method wraps [`notify_cancel`](https://www.unix.com/man-page/osx/3/notify_cancel).

#### `notify.listener.suspend(name)`

* `name` String - The event name to suspend an existing event handler for.

Suspends a event handler for the event with name `name`.

```js
const { listener } = require('node-mac-notify')

const name = 'my-event-name'

listener.add(name)

const suspended = listener.suspend(name)
console.log(`Event handler for ${name} was ${suspended ? 'successfully' : 'unsuccessfully'} suspended.`)
```

This method wraps [`notify_suspend`](https://www.unix.com/man-page/osx/3/notify_suspend).

#### `notify.listener.resume(name)`

* `name` String - The event name to resume an suspended event handler for.

Resumes a suspended event handler for the event with name `name`.

```js
const { listener } = require('node-mac-notify')

const name = 'my-event-name'

listener.add(name)

const suspended = listener.suspend(name)
if (suspended) {
  const resumed = listener.resume(name)
  console.log(`Suspended event handler for ${name} was ${resumed ? 'successfully' : 'unsuccessfully'} resumed.`)
}
```

This method wraps [`notify_resume`](https://www.unix.com/man-page/osx/3/notify_resume).