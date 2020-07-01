
import CqlProcessor from './CqlProcessor.js';
var processor = {};

/**
 * Define an event handler for when a message is sent to this web worker.
 * Three types of messages can be sent here.
 * 1. elmJson & valueSetJon - Logic and code libraries for initial setup
 * 2. patientBundle - An initial or updated patient bundle
 * 3. expression - A logical expression needing to be evaluated
 * It is assumed that at least initially messages are sent in that order. For 
 * the third type, if an expression can be evaluated, the result is sent back 
 * as a message.
 * @param {object} rx - The message object being sent
 */
onmessage = function(rx) {
  let elmJson;
  let valueSetJson;
  let patientBundle;
  let expression;
  let parameters;

  // For efficiency, first check if this is an expression message, since that is the type called most often
  if ((expression = rx.data.expression) != null) {
    let tx;
    if (processor.patientSource._bundles.length > 0) {
      let result = processor.evaluateExpression(expression);
      tx = {
        expression: expression,
        result: result
      };
    } else {
      tx = {
        expression: expression,
        result: 'WAITING_FOR_PATIENT_BUNDLE'
      }
    }
    this.postMessage(tx); // send the result back
  } else if ((patientBundle = rx.data.patientBundle) != null) {
    processor.loadBundle(patientBundle);
  } else if ((elmJson = rx.data.elmJson) != null && (valueSetJson = rx.data.valueSetJson) != null) {
    parameters = rx.data.parameters;
    processor = new CqlProcessor(elmJson, valueSetJson, parameters);
  }
}

