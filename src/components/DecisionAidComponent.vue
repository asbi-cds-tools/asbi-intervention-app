<template>
  <div id="interventionElement">
    <h1>DEMO ASBI CDS: Decision Aid App</h1>
    <div v-if="ready">
      <div class="row">
        <div id="column1" class="column">
          <div id="your-responses" class="decision-aid">
            <h3>Your Responses</h3>
            <span v-html="yourResponses"></span>
          </div>
          <div id="your-drinking" class="decision-aid">
            <h3>{{yourDrinking.title}}</h3>
            <table>
              <thead>
                <tr>
                  <th></th>
                  <th>Maximum Drinks per week</th>
                  <th>Maximum Drinks per day</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td>{{yourDrinking.peer.name}}</td>
                  <td>{{yourDrinking.peer.maximum_drinks_per_week}}</td>
                  <td>{{yourDrinking.peer.maximum_drinks_per_day}}</td>
                </tr>
                <tr>
                  <td>You</td>
                  <td>{{yourDrinking.you.drinks_per_week}}</td>
                  <td>{{yourDrinking.you.maximum_drinks_per_day}}</td>
                </tr>
              </tbody>
            </table>
          </div>
          <div id="when-drinking-is-risky" class="decision-aid">
            <h3>When drinking is risky</h3>
            <span v-html="whenDrinkingIsRisky"></span>
          </div>
        </div>
        <div id="column2" class="column">
          <div id="your-zone" class="decision-aid">
            <h3>Your drinking "Zone"</h3>
            <svg id="pyramid" viewBox="-5 -5 110 105">
              <defs>
                <marker id="arrow" viewBox="0 0 10 10" refX="5" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
                  <path d="M 0 0 L 10 5 L 0 10 z"/>
                </marker>
              </defs>
              <g transform="translate(0,0)">
                <g>
                  <path d="M50,0 58.7,15 41.3,15z" fill="darkred" stroke="none"></path>
                  <text font-size="5px" stroke="white" stroke-width="0.2" fill="white" x="50" y="11" text-anchor="middle">IV</text>
                  <path v-if="yourZone.number==4" d="M25,7 35,7" stroke="black" marker-end="url(#arrow)"/>
                </g>
                <g>
                  <path d="M41.3,15 58.7,15 67.4,30 32.6,30z" fill="red" stroke="none"></path>
                  <text font-size="5px" stroke="white" stroke-width="0.2" fill="white" x="50" y="24" text-anchor="middle">III</text>
                  <path v-if="yourZone.number==3" d="M16,21 26,21" stroke="black" marker-end="url(#arrow)"/>
                </g>
                <g>
                  <path d="M32.6,30 67.4,30 76.1,45 23.9,45z" fill="orange" stroke="none"></path>
                  <text font-size="5px" stroke="black" stroke-width="0.2" fill="black" x="50" y="39" text-anchor="middle">II</text>
                  <path v-if="yourZone.number==2" d="M7,35 17,35" stroke="black" marker-end="url(#arrow)"/>
                </g>
                <g>
                  <path d="M23.9,45 76.1,45 100,86.6 0,86.6z" fill="green" stroke="none"></path>
                  <text font-size="5px" stroke="white" stroke-width="0.2" fill="white" x="50" y="65" text-anchor="middle">I *</text>
                  <path v-if="yourZone.number==1" d="M0,49 9,55" stroke="black" marker-end="url(#arrow)"/>
                </g>
                <path d="M50,0 100,86.6 0,86.6z" fill="transparent" stroke="black"></path>
              </g>
            </svg>
            <span v-html="yourZone.footnote"></span>
          </div>
          <div id="zone-table" class="decision-aid">
            <h3>Zone table</h3>
            <table>
              <thead>
                <tr>
                  <th>Zone</th>
                  <th>Score</th>
                  <th>Description</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td>{{zoneTable.one.name}}</td>
                  <td>{{zoneTable.one.score}}</td>
                  <td>{{zoneTable.one.description}}</td>
                </tr>
                <tr>
                  <td>{{zoneTable.two.name}}</td>
                  <td>{{zoneTable.two.score}}</td>
                  <td>{{zoneTable.two.description}}</td>
                </tr>
                <tr>
                  <td>{{zoneTable.three.name}}</td>
                  <td>{{zoneTable.three.score}}</td>
                  <td>{{zoneTable.three.description}}</td>
                </tr>
                <tr>
                  <td>{{zoneTable.four.name}}</td>
                  <td>{{zoneTable.four.score}}</td>
                  <td>{{zoneTable.four.description}}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
      <div class="footer">
        <div id="for-additional-info" class="decision-aid">
          <h3>For additional info</h3>
          <span v-html="forAdditionalInfo"></span>
        </div>
        <div id="what-counts-as-a-drink" class="decision-aid">
          <h3>What counts as a drink?</h3>
          <span v-html="whatCountsAsADrink"></span>
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
import { getObservationCategories } from '../util/util.js';
import { marked } from 'marked';

// Load the Questionniare, CQL ELM JSON, and value set cache which represents the alcohol intervention
const [questionnaires, elmJson, valueSetJson, namedExpression] = getIntervention();

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
      yourResponses: {},
      yourZone: {},
      yourDrinking: {},
      whatCountsAsADrink: {},
      whenDrinkingIsRisky: {},
      forAdditionalInfo: {},
      zoneTable: {},
      ready: false // Indicate we are not yet ready for the component to render
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
    sendPatientBundle(patientBundle);

    // Have the web worker evaluate the CQL and return the brief interventions
    let decisionAids = await evaluateExpression(namedExpression);

    // Unpack the alcohol brief interventions and assimilate into the component
    this.yourResponses = marked(decisionAids.your_responses);
    this.yourDrinking = decisionAids.your_drinking;
    if (this.yourDrinking.you.maximum_drinks_per_week.lower == this.yourDrinking.you.maximum_drinks_per_week.upper) {
      this.yourDrinking.you.drinks_per_week = `${this.yourDrinking.you.maximum_drinks_per_week.lower}`;
    } else {
      this.yourDrinking.you.drinks_per_week = `${this.yourDrinking.you.maximum_drinks_per_week.lower}` + ' - ' + `${this.yourDrinking.you.maximum_drinks_per_week.upper}`;
    }
    this.yourZone = {
      number: decisionAids.your_zone.number,
      romanRomanNumeral: decisionAids.your_zone.roman_numeral,
      zoneLabels: {
        one: marked(decisionAids.your_zone.zone_labels.one),
        two: marked(decisionAids.your_zone.zone_labels.two),
        three: marked(decisionAids.your_zone.zone_labels.three),
        four: marked(decisionAids.your_zone.zone_labels.four)
      },
      footnote: marked(decisionAids.your_zone.footnote)
    };
    this.whatCountsAsADrink = decisionAids.what_counts_as_a_drink;
    this.whenDrinkingIsRisky = marked(decisionAids.when_drinking_is_risky);
    this.forAdditionalInfo = marked(decisionAids.for_additional_info);
    this.zoneTable = {
      one: decisionAids.zone_table.definitions.zone_one,
      two: decisionAids.zone_table.definitions.zone_two,
      three: decisionAids.zone_table.definitions.zone_three,
      four: decisionAids.zone_table.definitions.zone_four
    };

    // We don't show this component until `ready=true`
    this.ready = true;
  }
};
</script>

<style>
.row {
  display: flex;
}
.column {
  flex: 50%;
  max-width: 500px;
  min-width: 275px;
}
.footer {
  max-width: 1000px;
  min-width: 550px;
}
.decision-aid {
  margin: 15px;
  border: solid;
  vertical-align:top;
}
#drink-sizes > img {
  width: 100%;
  height: auto;
}
.decision-aid > h3 {
  display: block;
  margin: 15px;
}
.decision-aid > span {
  display: block;
  margin: 15px;
}
.decision-aid > table {
  border: 1px solid black;
  margin: 15px;
  border-collapse: collapse;
}
.decision-aid > table > thead {
  border: 1px solid black;
}
.decision-aid > table > thead > tr {
  border: 1px solid black;
}
.decision-aid > table > thead > tr > th {
  border: 1px solid black;
  text-align: center;
}
.decision-aid > table > tbody {
  border: 1px solid black;
}
.decision-aid > table > tbody > tr {
  border: 1px solid black;
}
.decision-aid > table > tbody > tr > td {
  border: 1px solid black;
  text-align: center;
}
</style>