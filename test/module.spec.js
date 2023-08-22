const { expect } = require('chai')
const { sendSystemNotification } = require('../index')

describe('node-mac-notify', () => {
  it('should send a notification', () => {
    const kIOPMCPUPowerNotificationKey = 'com.apple.system.power.CPU';
    const status = sendSystemNotification(kIOPMCPUPowerNotificationKey);
    expect(status).to.equal(0);
  });
});
