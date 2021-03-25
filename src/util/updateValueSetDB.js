// This file comes from the [Pain Management Summary](https://github.com/AHRQ-CDS/AHRQ-CDS-Connect-PAIN-MANAGEMENT-SUMMARY) 
// SMART on FHIR application, which is part of the CDS Connect project, sponsored by the Agency for Healthcare Research and 
// Quality (AHRQ), and developed under contract with AHRQ by MITRE's CAMH FFRDC. This file carries an Apache License and it 
// has been modified for use with this project.
// ---
// This script updates the valueset-db.json file with any changes from the CQL
// library and/or changes in the value set definitions in VSAC.  It should be
// called with the UMLS Username and Password as arguments.
const fs = require('fs');
const path = require('path');
const temp = require('temp');
const { Library, Repository } = require('cql-execution');
const { CodeService } = require('cql-exec-vsac');
const briefInterventionLogicElm = require('../cql/BriefInterventionLogicLibrary.json');
const decisionAidLogicElm = require('../cql/DecisionAidLogicLibrary.json');
const fhirHelpersElm = require('../cql/FHIRHelpers.json');

// First ensure an API key is provided
let apiKey;
if (process.argv.length === 3) {
  apiKey = process.argv[2];
} else if (process.argv.length === 4) {
  console.error('UMLS username and password is no longer supported. Please pass in a UMLS API key instead.');
  process.exit(1);
} else {
  console.error('The UMLS API key must be passed in as an argument');
  process.exit(1);
}

// Then initialize the cql-exec-vsac CodeService, pointing to a temporary
// folder to dump the valueset cache files.
temp.track(); // track temporary files and delete them when the process exits
const tempFolder = temp.mkdirSync('vsac-cache');
const codeService = new CodeService(tempFolder);

console.log(`Using temp folder: ${tempFolder}`);

// Then setup the CQL libraries that we need to analyze to extract the
// valuesets from.
const briefInterventionLogicLibrary = new Library(briefInterventionLogicElm, new Repository({
  FHIRHelpers: fhirHelpersElm
}));
const decisionAidLogicLibrary = new Library(decisionAidLogicElm, new Repository({
  FHIRHelpers: fhirHelpersElm
}));

// Then use the ensureValueSetsInLibrary function to analyze the CQL, request all 
// the value sets from VSAC, and store their data in the temporary folder.  The 
// second argument (true) indicates to also look at dependency libraries.
const maskedKey = apiKey.slice(0, 2) + apiKey.slice(2, -2).replace(/[^-]/g, '*') + apiKey.slice(-2);
console.log(`Loading value sets from VSAC using API key: ${maskedKey}`);
codeService.ensureValueSetsInLibraryWithAPIKey(briefInterventionLogicLibrary, true, apiKey)
  .then(() => codeService.ensureValueSetsInLibraryWithAPIKey(decisionAidLogicLibrary, true, apiKey))
  .then(() => {
    // The valueset-db.json that the codeService produces isn't exactly the
    // format that cql-execution wants, so now we must reformat it into the 
    // desired format.
    const tempDBFile = path.join(tempFolder, 'valueset-db.json');
    const original = JSON.parse(fs.readFileSync(tempDBFile, 'utf8'));
    let oidKeys = Object.keys(original).sort();
    console.log(`Loaded ${oidKeys.length} value sets`);
    console.log('Translating JSON to expected format')
    const fixed = {};
    for (const oid of oidKeys) {
      fixed[oid] = {};
      for (const version of Object.keys(original[oid])) {
        fixed[oid][version] = original[oid][version]['codes'].sort((a, b) => {
          if (a.code < b.code) return -1;
          else if (a.code > b.code) return 1;
          return 0;
        });
      }
    }

    // And finally write the result to the real locations of the valueset-db.json.
    const dbPath = path.join(__dirname, '..', 'cql', 'valueset-db.json');
    fs.writeFileSync(dbPath, JSON.stringify(fixed, null, 2), 'utf8');
    console.log('Updated:', dbPath);
  })
  .catch((error) => {
    let message = error.message;
    if (error.statusCode === 401) {
      // The default 401 message isn't helpful at all
      message = 'invalid API key or unauthorized access'
    }
    console.error('Error updating valueset-db.json:', message);
    process.exit(1);
  });

