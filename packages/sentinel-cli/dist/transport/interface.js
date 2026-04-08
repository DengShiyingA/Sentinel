"use strict";
/**
 * Transport interface — abstracts local (TCP) vs remote (Socket.IO) communication.
 * Both modes use the same message format for approval_request / decision.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.setTransport = setTransport;
exports.getTransport = getTransport;
/** Global transport instance — set by start command */
let _transport = null;
function setTransport(t) { _transport = t; }
function getTransport() { return _transport; }
//# sourceMappingURL=interface.js.map