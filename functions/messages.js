const logger = require("firebase-functions/logger");
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { v4: uuidv4 } = require('uuid');
const { authenticate } = require("./auth");
const { Timestamp } = require('firebase-admin/firestore');

exports.changeMessageStatus = functions.firestore
    .document('messages/{messageId}')
    .onWrite((change) => {
        const message = change.after.data();
        if (message) {
            if (['delivered', 'seen', 'sent'].includes(message.status)) {
                return null;
            } else {
                return change.after.ref.update({
                    status: 'delivered',
                })
            }
        } else {
            return null;
        }
    });