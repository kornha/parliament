const admin = require('firebase-admin');
const { joinRoom } = require('./rooms');
const { changeMessageStatus } = require('./messages');
const { createUserFunction } = require('./users');

admin.initializeApp();

module.exports = {
    joinRoom,
    changeMessageStatus,
    createUserFunction,
};
