<template>
  <div id="interventionElement">
    <div v-if="ready">
      <div class="row">
        <div class="single-column">
          <div class="instruction-title">
            {{general_guidance.title}}
          </div>
          <div class="instruction-text">
            {{general_guidance.text}}
          </div>
          <button id="more-information" v-on:click="show = true">
            Additional Guidance on Brief Intervention Elements
          </button>
          <transition v-if="show" name="modal">
            <div class="modal-mask">
          <div class="modal-wrapper">
            <div class="modal-container">
            <div id="additional">
              <span v-html="general_guidance.additional"></span>
            </div>
            <button @click="show = false">
              Close
            </button>
            </div></div></div>
          </transition>
        </div>
      </div>
      <div class="row">
        <div class="columnLeft">
          <div class="instruction-title">
            {{provide_feedback.instructions.title}}
          </div>
          <div class="instruction-text">
            {{provide_feedback.instructions.text}}
          </div>
        </div>
        <div class="columnRight">
          <div class="bold-content">
            <span v-html="provide_feedback.content.part1"></span>
          </div>
          <div class="bold-content">
            <span v-html="provide_feedback.content.part2"></span>
          </div>
          <div class="content">
            <span v-html="provide_feedback.content.part3"></span>
          </div>
          <div class="tab-content">
            <span v-html="provide_feedback.content.part4"></span>
          </div>
        </div>
      </div>
      <div class="row">
        <div class="columnLeft">
          <div class="instruction-title">
            {{reinforce_key_information.instructions.title}}
          </div>
          <div class="instruction-text">
            {{reinforce_key_information.instructions.text}}
          </div>
        </div>
        <div class="columnRight">
          <div class="bold-content">
            <span v-html="reinforce_key_information.content.part1"></span>
          </div>
          <div class="content">
            <span v-html="reinforce_key_information.content.part2"></span>
          </div>
          <div class="bold-content">
            <span v-html="reinforce_key_information.content.part3"></span>
          </div>
          <div class="content" v-if="reinforce_key_information.content.part4">
            <table>
              <thead>
                <tr>
                  <th><span v-html="reinforce_key_information.content.part4.you.title"></span></th>
                  <th><span v-html="reinforce_key_information.content.part4.peer.title"></span></th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td><span v-html="reinforce_key_information.content.part4.you.drinks_per_week"></span></td>
                  <td><span v-html="reinforce_key_information.content.part4.peer.drinks_per_week"></span></td>
                </tr>
                <tr>
                  <td><span v-html="reinforce_key_information.content.part4.you.drinks_per_day"></span></td>
                  <td><span v-html="reinforce_key_information.content.part4.peer.drinks_per_day"></span></td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
      <div class="row" v-if="discuss_responses">
        <div class="columnLeft">
          <div class="instruction-title">
            {{discuss_responses.instructions.title}}
          </div>
          <div class="instruction-text">
            {{discuss_responses.instructions.text}}
          </div>
        </div>
        <div class="columnRight">
          <div class="content">
            <span v-html="discuss_responses.content.part1"></span>
          </div>
          <div class="content">
            <span v-html="discuss_responses.content.part2"></span>
          </div>
          <div class="content">
            <span v-html="discuss_responses.content.part3"></span>
          </div>
          <div class="content">
            <span v-html="discuss_responses.content.part4"></span>
          </div>
        </div>
      </div>
      <div class="row" v-if="provide_education">
        <div class="columnLeft">
          <div class="instruction-title">
            {{provide_education.instructions.title}}
          </div>
          <div class="instruction-text">
            {{provide_education.instructions.text}}
          </div>
        </div>
        <div class="columnRight">
          <div class="tab-content">
            <span v-html="provide_education.content"></span>
          </div>
        </div>
      </div>
      <div class="row">
        <div class="columnLeft">
          <div class="instruction-title">
            {{appropriate_follow_up.instructions.title}}
          </div>
          <div class="instruction-text">
            {{appropriate_follow_up.instructions.text}}
          </div>
        </div>
        <div class="columnRight">
          <div class="tab-content">
            <span v-html="appropriate_follow_up.content"></span>
          </div>
        </div>
      </div>
      <div class="row">
        <div class="columnLeft">
          <div class="instruction-title">
            {{share_resources.instructions.title}}
          </div>
          <div class="instruction-text">
            {{share_resources.instructions.text}}
          </div>
        </div>
        <div class="columnRight">
          <div class="tab-content">
            <span v-html="share_resources.content"></span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>

import { getIntervention } from '../util/intervention-selector.js';
import Worker from "../../node_modules/cql-worker/src/cql.worker.js"; // https://github.com/webpack-contrib/worker-loader
import { initialzieCqlWorker } from 'cql-worker';
import FHIR from 'fhirclient';
import {
  getObservationCategories, 
  observationToQr
} from '../util/util.js';
import { marked } from 'marked';

// Load the Questionniare, CQL ELM JSON, and value set cache which represents the alcohol intervention
const [questionnaires, elmJson, valueSetJson] = getIntervention();

// Top level definition of our FHIR client
var client;

// Define a web worker for evaluating CQL expressions
const cqlWorker = new Worker();

// Assemble the parameters needed by the CQL
let cqlParameters = {};

// Initialize the cql-worker
let [setupExecution, sendPatientBundle, evaluateExpression] = initialzieCqlWorker(cqlWorker);

// Send the cqlWorker an initial message containing the ELM JSON representation of the CQL expressions
setupExecution(elmJson, valueSetJson, cqlParameters);

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
    // Properties are populated after mount; see mounted() below.
    return {
      general_guidance: {},
      provide_feedback: {},
      reinforce_key_information: {},
      discuss_responses: {},
      provide_education: {},
      appropriate_follow_up: {},
      share_resources: {},
      ready: false, // Indicate we are not yet ready for the component to render
      show: false
    };
  },
  async mounted() {
    // Wait for authorization
    client = await FHIR.oauth2.ready();

    // Get the Patient resource
    let pid = await client.patient.read().then(function(pt) {
      if (pt) patientBundle.entry.unshift({resource: pt});
      console.log(pt);
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
            if (o.resource) patientBundle.entry.push({resource: observationToQr(o.resource)});
          });
        } else if (Array.isArray(ob)) {
          ob.forEach(o => {
            if (o.resourceType) patientBundle.entry.push({resource: observationToQr(o)});
          });
        } else {
          patientBundle.entry.push({resource: observationToQr(ob)});
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
    sendPatientBundle(patientBundle);

    // Have the web worker evaluate the CQL and return the brief interventions
    let BriefIntervention = await evaluateExpression('EvidenceBasedBriefIntervention');

    this.general_guidance = {
      title: BriefIntervention?.general_guidance?.title,
      text: BriefIntervention?.general_guidance?.text,
      additional: marked(BriefIntervention?.general_guidance?.additional ?? '')
    };
    this.provide_feedback = {
      instructions: BriefIntervention?.provide_feedback?.instructions,
      content: {
        part1: marked(BriefIntervention?.provide_feedback?.content?.part1 ?? ''),
        part2: marked(BriefIntervention?.provide_feedback?.content?.part2 ?? ''),
        part3: BriefIntervention?.provide_feedback?.content?.part3,
        part4: marked(BriefIntervention?.provide_feedback?.content?.part4 ?? ''),
      }
    };
    this.reinforce_key_information = {
      instructions: BriefIntervention?.reinforce_key_information?.instructions,
      content: {
        part1: marked(BriefIntervention?.reinforce_key_information?.content?.part1 ?? ''),
        part2: BriefIntervention?.reinforce_key_information?.content?.part2,
        part3: marked(BriefIntervention?.reinforce_key_information?.content?.part3 ?? ''),
        part4: BriefIntervention?.reinforce_key_information?.content?.part4 ? {
          you: {
            title: marked(BriefIntervention?.reinforce_key_information?.content?.part4?.you?.title ?? ''),
            drinks_per_week: marked(
              BriefIntervention?.reinforce_key_information?.content?.part4?.you?.drinks_per_week?.lower + 
              '-' +
              BriefIntervention?.reinforce_key_information?.content?.part4?.you?.drinks_per_week?.upper +
              '\n\nDrinks per Week'
            ),
            drinks_per_day: marked(
              BriefIntervention?.reinforce_key_information?.content?.part4?.you?.drinks_per_day?.lower + 
              '-' +
              BriefIntervention?.reinforce_key_information?.content?.part4?.you?.drinks_per_day?.upper +
              '\n\nDrinks per Day'
            )
          },
          peer: {
            title: marked(BriefIntervention.reinforce_key_information.content.part4.peer.title ?? ''),
            drinks_per_week: marked(
              BriefIntervention.reinforce_key_information.content.part4.peer.drinks_per_week +
              '\n\nDrinks per Week'
            ),
            drinks_per_day: marked(
              BriefIntervention.reinforce_key_information.content.part4.peer.drinks_per_day +
              '\n\nDrinks per Day'
            )
          }
        } : null
      }
    };
    this.discuss_responses = BriefIntervention.discuss_responses ? {
      instructions: BriefIntervention?.discuss_responses?.instructions,
      content: {
        part1: '<div class="bold-content">' +
          marked(BriefIntervention?.discuss_responses?.content?.part1 ?? '') +
          '</div>'
        ,
        part2: '<div class="response-group">' +
          marked(
            BriefIntervention?.discuss_responses?.content?.part2?.response4 +
            '\n\n' + 
            BriefIntervention?.discuss_responses?.content?.part2?.response5 +
            '\n\n' +
            BriefIntervention?.discuss_responses?.content?.part2?.response6 +
            '\n\n'
          ) +
          '</div>' + 
          '<div class="italic-content">' +
          marked(BriefIntervention?.discuss_responses?.content?.part2?.context ?? '') +
          '</div>'
        ,
        part3: '<div class="response-group">' +
          marked(
            BriefIntervention?.discuss_responses?.content?.part3?.response7 +
            '\n\n' + 
            BriefIntervention?.discuss_responses?.content?.part3?.response8 +
            '\n\n'
          ) +
          '</div>' + 
          marked(BriefIntervention?.discuss_responses?.content?.part3?.context ?? '') +
          '<p> </p>'
        ,
        part4: '<div class="response-group">' +
          marked(
            BriefIntervention?.discuss_responses?.content?.part4?.response9 +
            '\n\n' + 
            BriefIntervention?.discuss_responses?.content?.part4?.response10 +
            '\n\n'
          ) +
          '</div>' +
          '<div class="italic-content">' +
          marked(BriefIntervention?.discuss_responses?.content?.part4?.context ?? '') +
          '</div>'
        ,
      }
    } : null;
    this.provide_education = BriefIntervention.provide_education ? {
      instructions: {
        title: BriefIntervention?.provide_education?.instructions?.title,
        text: BriefIntervention?.provide_education?.instructions?.text
      },
      content: marked(BriefIntervention?.provide_education?.content ?? '')
    } : null;
    this.appropriate_follow_up = {
      instructions: {
        title: BriefIntervention?.appropriate_follow_up?.instructions?.title,
        text: BriefIntervention?.appropriate_follow_up?.instructions?.text
      },
      content: marked(BriefIntervention?.appropriate_follow_up?.content ?? '')
    };
    this.share_resources = {
      instructions: {
        title: BriefIntervention?.share_resources?.instructions?.title,
        text: BriefIntervention?.share_resources?.instructions?.text
      },
      content: marked(BriefIntervention?.share_resources?.content ?? '')
    };

    // We don't show this component until `ready=true`
    this.ready = true;
  }
};
</script>

<style>
.row {
  display: flex;
  border-bottom: solid;
}
.single-column {
  flex: 50%;
  /* max-width: 1024px;
  min-width: 275px; */
}
.instruction-title {
  font-size: 24px;
  /* color:cornflowerblue; */
}
/* .section-span {
  border-bottom: solid;
} */
.columnLeft {
  flex: 33%;
  padding-right: 25px;
  margin-right: 25px;
  /* max-width: 500px;
  min-width: 275px; */
}
.columnRight {
  flex: 67%;
  /* max-width: 500px;
  min-width: 275px; */
}
.content {
  margin-bottom: 40px;
}
svg {
  width: 85%;
  height: auto;
}
.response-group > p {
  margin-top: -4px;
  margin-bottom: -4px;
}
.bold-content {
  font-weight: bold;
  font-size: larger;
  margin-left: 3%;
}
.tab-content {
  margin-left: 3%;
  margin-bottom: 40px;
}
.italic-content {
  font-style: italic;
  font-size: large;
  margin-left: 6%;
  margin-top: -4px;
}
.italic-content > p {
  margin-top: 0px;
  /* margin-bottom: 30px; */
}
.bold-content strong {
  color: red;
}
table, th, td {
  border: 1px solid black;
}
#interventionElement {
  margin-left: 25px;
  margin-top: 25px;
  margin-right: 25px;
}
div.single-column > div.instruction-tet {
  font-size: 18px;
}
.instruction-title {
  color: #1565f6;
  margin-top: 12px;
}
.instruction-text{
margin-top: 12px; /*separate from black line*/
margin-left: 8px; /*indent from left; under heading*/
}
.modal-enter {
  opacity: 0;
}
.modal-leave-active {
  opacity: 0;
}
.modal-enter .modal-container,
.modal-leave-active .modal-container {
  -webkit-transform: scale(1.1);
  transform: scale(1.1);
}
.modal-mask {
  position: fixed;
  z-index: 9998;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.25);
  display: table;
  transition: opacity 0.3s ease;
}
.modal-wrapper {
  display: table-cell;
  vertical-align: middle;
}
.modal-container {
  width: 400px;
  margin: 0px auto;
  padding: 20px 30px;
  background-color: #fff;
  border-radius: 10px;
  border-style: solid;
  border-color: #1565f6;
  border-width: thick;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.33);
  transition: all 0.3s ease;
  font-family: Helvetica, Arial, sans-serif;
}
button#more-information {
  background: none!important;
  border: none;
  padding: 0!important;
  color: #1565f6;
  text-decoration: underline;
  cursor: pointer;
  float: right;
  font-size: 14px;
  font-style: italic;
  margin-right: 10px;
  margin-bottom: 10px;
}
div#additional > span  > p > a {
  overflow-wrap: break-word;
}
div#additional > span > p:nth-child(3) {
  font-size: 13px;
}
ul {
  line-height: 1.5em;
}
table{
  border-collapse: collapse;
  text-align: center;
  /* width: 300px; */
  margin-bottom: 20px;
}
div.content table{
  margin-left: 15%;
}
div.content span p strong{
font-size: large;
}
div.content table thead{
  font-size: larger;
  text-align: center;
}
.response-group{
  margin-left: 6%;
  /* line-height: 1.5; */
}
.response-group > p {
  margin-bottom: 10px;
}
.response-group .bold-content p{
  margin-top: 8x;
}
ol{
  line-height: 1.5;
}
 div.content table thead tr th span p{
  margin: 20px;
 }
div.content table tbody tr td span p{
  font-size: larger;
  margin-bottom: 2px;
  margin-top: 4px;
 }
th { 
  border-left: 2px solid #1565f6;
  border-top: 2px solid #1565f6;
  border-right: 2px solid #1565f6;
  border-bottom: 2px solid #1565f6;
}
td { 
  border-left: 2px solid #1565f6;
  border-top: none;
  border-right: 2px solid #1565f6;
  border-bottom: 2px solid #1565f6;
  padding: 20px;
}
div.content table tbody tr td span p:nth-child(1) {
  color: red;
  font-weight: bold;
}
</style>