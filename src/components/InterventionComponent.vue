<template>
  <div id="interventionElement">
    <h1>DEMO ASBI CDS: Brief Intervention App</h1>
    <div v-if="ready">

        <div>
          <h2>Alcohol Screening Summary</h2>
          <div>{{alcoholScreeningResultsSummary.summary}}</div>
          <details>
            <summary>Responses</summary>
            <ul>
              <li v-for="response in alcoholScreeningResultsSummary.responses" :key="response.question">
                <div class="question">{{response.question}}</div>
                <div class="response">{{response.answer}}</div>
              </li>
            </ul>
          </details>
        </div>
        <details>
          <summary>Alcohol Counseling Suggestions</summary>
          <div><span v-html="alcoholCounselingSuggestions.suggestions"></span></div>
          <div v-if="alcoholCounselingSuggestions.additional != ''">{{alcoholCounselingSuggestions.addition}}</div>
          <div v-if="alcoholCounselingSuggestions.referral"><em>A referral for treatment of possible alcohol use disorder is recommended.</em></div>
          <details>
            <summary>References:</summary>
            <div><span v-html="alcoholCounselingSuggestions.references"></span></div>
          </details>
        </details>
        <details>
          <summary>Patient Education Material</summary>
          <div><span v-html="alcoholPatientEducationResources"></span></div>
        </details>

        <div>
          <h2>Substance Use Screening Summary</h2>
          <div>{{nonAlcoholScreeningResultsSummary.summary}}</div>
          <details>
            <summary>Responses</summary>
            <ul>
              <li v-for="response in nonAlcoholScreeningResultsSummary.responses" :key="response.question">
                <div class="question">{{response.question}}</div>
                <div class="response">{{response.answer}}</div>
              </li>
            </ul>
          </details>
        </div>
        <details>
          <summary>Substance Use Counseling Suggestions</summary>
          <div><span v-html="nonAlcoholRelatedCounselingSuggestions.suggestions"></span></div>
          <div v-if="nonAlcoholRelatedCounselingSuggestions.additional != ''">{{nonAlcoholRelatedCounselingSuggestions.addition}}</div>
          <div v-if="nonAlcoholRelatedCounselingSuggestions.referral"><em>A referral for possible evaluation and treatment of substance use is recommended.</em></div>
          <details>
            <summary>References:</summary>
            <div><span v-html="nonAlcoholRelatedCounselingSuggestions.references"></span></div>
          </details>
        </details>
        <details>
          <summary>Patient Education Material</summary>
          <div><span v-html="nonAlcoholRelatedPatientEducationResources"></span></div>
        </details>

    </div>
  </div>
</template>

<script>

import { getIntervention } from '../util/intervention-selector.js';
import Worker from '../cql/cql.worker.js'; // https://github.com/webpack-contrib/worker-loader
import FHIR from 'fhirclient';
import {getObservationCategories} from '../util/util.js';
import marked from 'marked';

// Load the Questionniare, CQL ELM JSON, and value set cache which represents the alcohol intervention
const [questionnaires, elmJson, valueSetJson, namedExpression] = getIntervention();

// Top level definition of our FHIR client
var client;

// Define a web worker for evaluating CQL expressions
const cqlWorker = new Worker();

// Assemble the parameters needed by the CQL
let cqlParameters = {};

// Send the cqlWorker an initial message containing the ELM JSON representation of the CQL expressions
cqlWorker.postMessage({elmJson: elmJson, valueSetJson: valueSetJson, parameters: cqlParameters});

// Define an array to keep track of the expression messages sent to the Web Worker
var messageArray = [
  {
    expr: 'PLACEHOLDER', 
    resolver: {}
  }
];

// Define an event handler for when cqlWorker sends results back
cqlWorker.onmessage = function(event) {
  // Unpack the message in the event
  let expression = event.data.expression;
  let result = event.data.result;

  if (result == 'WAITING_FOR_PATIENT_BUNDLE') {
    cqlWorker.postMessage({expression: expression});
  } else {
    // Try to find this expression in the messageArray
    let executingExpressionIndex = messageArray.map((msg,idx) => {
      if (msg.expr == expression) return idx;
      else return -1; 
    }).reduce((a,b) => {
      if (a != -1) return a;
      else if (b != -1) return b;
      else return -1});

    // If the expression was found in the messageArray
    if (executingExpressionIndex != -1) {
      // Return the result by resolving the promise
      messageArray[executingExpressionIndex].resolver(result);
      // Remove the matching entry from the array
      messageArray.splice(executingExpressionIndex,1);
    }
  }
}

/**
 * Sends an expression to the webworker for evaluation.
 * @param {string} expression - The name of a CQL expression.
 * @returns {boolean} - A dummy return value.
 */
function evaluateExpression(expression) {
  // If this expression is already on the message stack, return its index.
  let executingExpressionIndex = messageArray.map((msg,idx) => {
    if (msg.expression == expression) return idx;
    else return -1;
  }).reduce((a,b) => {
    if (a != -1) return a;
    else if (b != -1) return b;
    else return -1});
  
  // If this expression was not found on the stack
  if (executingExpressionIndex == -1) {

    // Add an entry to the stack
    let n = messageArray.push({
      expr: expression, // The name of the expression
      resolver: null
    });
    
    // Send the entry to the Web Worker
    cqlWorker.postMessage({expression: expression});
    // Return a promise that can be resolved after the web worker returns the result
    return new Promise(resolve => messageArray[n-1].resolver = resolve);
  }
}

// Add the Questionnaires to the patient bundle.
var patientBundle = {
  resourceType: 'Bundle',
  id: 'survey-bundle',
  type: 'collection',
  entry: []
};
if (questionnaires.length > 0) {
  questionnaires.forEach(questionnaire => {
    patientBundle.entry.push({resource: questionnaire});
  });
}

// Define the survey component for Vue
export default {
  data() {
    // Indicate we are not yet ready for the component to render
    return {
      alcoholScreeningResultsSummary: {},
      alcoholCounselingSuggestions: {},
      alcoholPatientEducationResources: {},
      nonAlcoholScreeningResultsSummary: {},
      nonAlcoholRelatedCounselingSuggestions: {},
      nonAlcoholRelatedPatientEducationResources: {},
      ready: false
    };
  },
  async mounted() {
    // Wait for authorization
    client = await FHIR.oauth2.ready();

    // Get the Patient resource
    let pid = await client.patient.read().then(function(pt) {
      if (pt) patientBundle.entry.unshift({resource: pt});
      return pt.id;
    });

    // Get any Condition resources
    await client.request('/Condition?patient=' + pid).then(function(cd) {
      if (cd) {
        if (cd.resourceType == 'Bundle' && cd.entry) {
          cd.entry.forEach(c => {
            if (c.resource) patientBundle.entry.push({resource: c.resource});
          });
        } else if (Array.isArray(cd)) {
          cd.forEach(c => {
            if (c.resourceType) patientBundle.entry.push({resource: c});
          });
        } else {
          patientBundle.entry.push({resource: cd});
        }
      }
    });
    
    // Get any Observation resources
    let observationQueryString = `/Observation?patient=${pid}`;
    // Optionally request Observations using categories
    if (process.env.VUE_APP_FHIR_OBSERVATION_CATEGORY_QUERIES.toLowerCase() == 'true') {
      getObservationCategories().forEach(cat => {
        observationQueryString = observationQueryString + '&category=' + cat;
      });
    }
    await client.request(observationQueryString).then(function(ob) {
      if (ob) {
        if (ob.resourceType == 'Bundle' && ob.entry) {
          ob.entry.forEach(o => {
            if (o.resource) patientBundle.entry.push({resource: o.resource});
          });
        } else if (Array.isArray(ob)) {
          ob.forEach(o => {
            if (o.resourceType) patientBundle.entry.push({resource: o});
          });
        } else {
          patientBundle.entry.push({resource: ob});
        }
      }
    });

    // Get any Procedure resources
    await client.request('/Procedure?patient=' + pid).then(function(pr) {
      if (pr) {
        if (pr.resourceType == 'Bundle' && pr.entry) {
          pr.entry.forEach(p => {
            if (p.resource) patientBundle.entry.push({resource: p.resource});
          });
        } else if (Array.isArray(pr)) {
          pr.forEach(p => {
            if (p.resourceType) patientBundle.entry.push({resource: p});
          });
        } else {
          patientBundle.entry.push({resource: pr});
        }
      }
    });

    // Get any QuestionnaireResponse resources
    await client.request('/QuestionnaireResponse?patient=' + pid).then(function(qr) {
      if (qr) {
        if (qr.resourceType == 'Bundle' && qr.entry) {
          qr.entry.forEach(q => {
            if (q.resource) patientBundle.entry.push({resource: q.resource});
          });
        } else if (Array.isArray(qr)) {
          qr.forEach(q => {
            if (q.resourceType) patientBundle.entry.push({resource: q});
          });
        } else {
          patientBundle.entry.push({resource: qr});
        }
      }
    });

    // Send the patient bundle to the CQL web worker
    cqlWorker.postMessage({patientBundle: patientBundle});

    // Have the web worker evaluate the CQL and return the brief interventions
    let briefInterventions = await evaluateExpression(namedExpression);

    // Unpack the alcohol brief interventions and assimilate into the component
    this.alcoholScreeningResultsSummary = briefInterventions.alcohol_screening_results_summary;
    this.alcoholCounselingSuggestions = {
      suggestions: marked(briefInterventions.alcohol_counseling_suggestions.suggestions),
      additional: briefInterventions.alcohol_counseling_suggestions.additional[0],
      references: marked(briefInterventions.alcohol_counseling_suggestions.references),
      referral: briefInterventions.alcohol_counseling_suggestions.referral
    };
    this.alcoholPatientEducationResources = marked(briefInterventions.alcohol_patient_education_resources);

  // Unpack the non-alcohol brief interventions and assimilate into the component
    this.nonAlcoholScreeningResultsSummary = briefInterventions.non_alcohol_screening_results_summary;
    this.nonAlcoholRelatedCounselingSuggestions = {
      suggestions: marked(briefInterventions.non_alcohol_related_counseling_suggestions.suggestions),
      references: marked(briefInterventions.non_alcohol_related_counseling_suggestions.references),
      referral: briefInterventions.non_alcohol_related_counseling_suggestions.referral
    };
    this.nonAlcoholRelatedPatientEducationResources = marked(briefInterventions.non_alcohol_related_patient_education_resources);
    console.log(briefInterventions);

    // We don't show this component until `ready=true`
    this.ready = true;
  }
};
</script>

