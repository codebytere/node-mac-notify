# node-mac-notify

WIP

```js
const { sendSystemNotification } = require('node-mac-notify')

const kIOPMCPUPowerNotificationKey = 'com.apple.system.power.CPU'
const status = sendSystemNotification(kIOPMCPUPowerNotificationKey)
```
