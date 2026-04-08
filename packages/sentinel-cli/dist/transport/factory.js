"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createTransport = createTransport;
const local_1 = require("./local");
const remote_1 = require("./remote");
const cloudkit_1 = require("./cloudkit");
function createTransport(mode, opts) {
    switch (mode) {
        case 'local':
            return new local_1.LocalTransport();
        case 'cloudkit':
            return new cloudkit_1.CloudKitTransport();
        case 'server':
            if (!opts?.serverUrl || !opts?.token) {
                throw new Error('Server mode requires serverUrl and token');
            }
            return new remote_1.RemoteTransport(opts.serverUrl, opts.token);
    }
}
//# sourceMappingURL=factory.js.map