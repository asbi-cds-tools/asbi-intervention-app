# Alcohol Screening and Brief Intervention (ASBI) Clinical Decision Support (CDS) Intervention App
The *ASBI Intervention App* is a [SMART on FHIR<sup>&reg;</sup>](https://docs.smarthealthit.org/) application that provides alcohol intervention CDS for helping to address patient alcohol consumption behaviors. The app is meant to be used with the [SMART<sup>&reg;</sup> app launch framework](http://hl7.org/fhir/smart-app-launch/index.html) and is designed to customize the alcohol intervention based upon patient-specific data provided by an electronic health record (EHR) as well as patient responses to one of the following three alcohol screening instruments:
1. World Health Organization's Alcohol Use Disorders Identification Test (AUDIT)
2. United States AUDIT (USAUDIT)
3. National Institute on Substance Abuse (NIDA) Quick Screen

The *ASBI Intervention App* provides implementations of following two intervention CDS, both of which have been published on the [CDS Connect Repository](https://cds.ahrq.gov/cdsconnect/artifact_discovery):
1. Brief Intervention CDS: Provides counseling guidance and prompts for talking with the patient about their alcohol use behaviors.
2. Decision Aid CDS: Provides a variety of textual and graphical summaries for providing context to the patient's responses to one of the alcohol screening instruments.

The *ASBI Intervention App* can be used in conjuction with the [ASBI Screening App](https://github.com/asbi-cds-tools/asbi-screening-app), which provides implementations of the above alcohol screening instruments.

## Cautions and Limitations
TODO: Update and link to pilot report.
This software application has not been tested in a clinical environment with real patient data. Its purpose is to faciliate testing of the two alcohol intervention CDS to be published on CDS Connect. Additional development work will be needed to integrate the **ASBI Intervention App** into a real EHR.

## Utilized Standards
A number of standards have been used to help define the *ASBI Intervention App*.

### SMART on FHIR<sup>&reg;</sup>
The [Substitutable Medical Apps, Reusable Technology (SMART)](https://smarthealthit.org/) on Fast Healthcare Interoperability Resources (FHIR<sup>&reg;</sup>) is a free and open standards-based application programming interface (API) for providing software applications with access to electronic health records (EHRs). The *ASBI Intervention App* uses the SMART on FHIR standard to access patient data in order to customize the alcohol intervention experience.

### FHIR<sup>&reg;</sup> Questionnaire
[Questionnaire](https://www.hl7.org/fhir/questionnaire.html) is one of the many [interoperable resources](http://hl7.org/fhir/resourcelist.html) defined by the Health Level 7 (HL7<sup>&reg;</sup>) [FHIR<sup>&reg;</sup> standard](http://hl7.org/fhir/). The Questionnaire resource allows a set of questions and allowable responses to be represented in an open and standard way. Each Questionnaire is defined by a set of both required and optional data elements, which are [by design](https://www.hl7.org/fhir/questionnaire.html#sdc) general in nature in order to support the capabilities most likely to be found in most healthcare systems. The *ASBI Intervention App* assumes that the alcohol screening instruments are represented by Questionnaire resources. It is further assumed that a [QuestionnaireResponse](https://www.hl7.org/fhir/questionnaireresponse.html) resource is generated from the responses provided by the patient and that the QuestionnaireResponse acts as input to the CDS implemented by this app.

### Structured Data Capture (SDC)
The base FHIR<sup>&reg;</sup> specification is meant to be an [80% solution](https://www.hl7.org/fhir/overview-arch.html#principles) for healthcare interoperability. Mechanisms such as extensions, profiles, and implementation guides [provide a means](https://www.hl7.org/fhir/extensibility.html) in which use cases outside this 80% can be addressed. The [Structured Data Capture (SDC) implementation guide](http://build.fhir.org/ig/HL7/sdc/) defines how more complex Questionnaire functionality and behavior can be expressed. Examples of additional complexity assumed by the *ASBI Intervention App* include advanced rendering of the Questionnaires and the ability to provide dynamic updates via logical expressions (see "Clinical Quality Language (CQL)" below).

### Clinical Quality Language (CQL)
[CQL](https://cql.hl7.org/) is a domain-specific programming language focused on clinical quality applications, including CDS as well as electronic clinical quality measures (eCQMs). Logical expressions written in CQL are human-readable but can also be compiled to a machine-friendly format to facilitate implementation. The *ASBI Intervention App*  executes CQL logic embedded in each Questionnaire to provide patient customized behavior. Machine-friendly versions of the CQL are embedded in this app; complete versions can be found on CDS Connect once the CDS are published.

## Underlying Technologies

### Vue.js
[Vue](https://vuejs.org/) is a JavaScript front-end framework for building user interfaces. The *ASBI Intervention App* was built using the [`vue create` command](https://cli.vuejs.org/guide/creating-a-project.html#vue-create) from the Vue command line interface (CLI).

### CQL Worker
All CQL calculations are executed within the context of a [Web Worker](https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Using_web_workers), thereby offloading them to a separate thread. This greatly improves the responsiveness of the application. This is implemented via the [CQL Worker](https://github.com/asbi-cds-tools/cql-worker) library, which uses the the [CQL Execution Engine](https://github.com/cqframework/cql-execution) behind the scenes.

## Setup
This project manages dependencies using the [Yarn package manager](https://yarnpkg.com/). The dependencies for the *ASBI Intervention App* can be installed locally by typing `yarn` at the command line. A local version of the app can be launched by typing `yarn serve` at the command line. A copy suitable for distribution can be built using the `yarn build` command.

### Download Value Sets from VSAC
The value set content used by the CQL is cached in a file named `valueset-db.json`, which has been checked into this project in an empty state. In order for the CDS to operate as intended, implementers must populate `valueset-db.json` with the value sets which have been published on the [Value Set Authority Center (VSAC)](https://vsac.nlm.nih.gov/). In order to access VSAC, you must sign up for a [UMLS Terminology Services account](https://uts.nlm.nih.gov//license.html).

Once a UMLS Terminology Services account has been obtained, the valueset-db.json file can be updated by running the following:

1. Run `node src/util/updateValueSetDB.js UMLS_API_KEY` _(replacing UMLS\_API\_KEY with your actual UMLS API key)_

To get you UMLS API Key:

1. Sign into your UMLS account at [https://uts.nlm.nih.gov/uts.html](https://uts.nlm.nih.gov/uts.html)
2. Click 'My Profile' in the orange banner at the top of the screen
3. Your API key should be listed below your username in the table
4. If no API key is listed:
   1. Click ‘Edit Profile’
   2. Select the ‘Generate new API Key’ checkbox
   3. Click ‘Save Profile’
   4. Your new API key should now be listed.

### Configuration
Parameters for the app are stored in [environmental variables](http://man7.org/linux/man-pages/man7/environ.7.html) that are stored in an `.env` file. The [dotenv package](https://www.npmjs.com/package/dotenv) is used to store the default variable values, which can be overwritten by defining a more specific env (e.g., `.env.local`) file or by setting the variables in the deployment system. For more information, see the [Vue documentation](https://cli.vuejs.org/guide/mode-and-env.html#environment-variables).

### Parameters

| Parameter | Description | Allowed Values |
| --- | --- | --- |
| `VUE_APP_FHIR_OBSERVATION_CATEGORY_QUERIES` | Some FHIR APIs require `Observation` resource queries to specify an [observation category](https://www.hl7.org/fhir/codesystem-observation-category.html). Setting this parameter to `true` causes the query of a patient's `Observation` resources to be made specified using categories. | `['true', 'false']` |
| `VUE_APP_ALCOHOL_INTERVENTION` | For selecting which alcohol intervention CDS is presented to the user. | `['briefintervention', 'decisionaid']` |

### Secure HTTP (HTTPS)

Most modern browsers are going to require HTTPS by default. To run the development server with HTTPS you will need to add the following to your `yarn.config.js` file (in addition to generating valid `key` and `crt` files):

```js
module.exports = {
  configureWebpack: {
     ...
  },
  devServer: {
    https: {
      key: fs.readFileSync("certificate.key"),
      cert: fs.readFileSync("certificate.crt")
    },
    disableHostCheck: true,
    public: 'https://localhost:8080',
    port: 8080,
    headers: { "Access-Control-Allow-Origin": "*" }
  }
};
```

To serve built files over HTTPS:
- `yarn build`
- `npm install -g http-server`
- `http-server dist -p 8080 -S -C certificate.crt -K certificate.key`
- Point your browser to `https://localhost:8080/launch.html`

## Usage
While the *ASBI Intervention App* is meant to interface with an actual EHR, a number of options are available for local testing with synthetic data.

### Using with ASBI Testing Server
This option requires installing the [ASBI Testing Server](https://github.com/asbi-cds-tools/asbi-testing-server):
1. `yarn start` in the root of the ASBI Testing Server (after installing its dependencies)
2. `yarn serve` from this project
3. Open a web browser and navigate to [http://localhost:8080/selector.html](http://localhost:8080/selector.html)
4. Select a synthetic patient from the list

This will start the SMART on FHIR<sup>&reg;</sup> launch sequence, which if everything is working should result in the ASBI Intervention App being displayed. A series of FHIR<sup>&reg;</sup> queries will be made from from this app to the ASBI Testing Server, which will respond with the appropriate resources.

### Using with Public SMART Sandbox
A public [SMART<sup>&reg;</sup> App Launcher](https://launch.smarthealthit.org/index.html) is available for sandbox tesing of SMART on FHIR apps with synthetic data. In order to use this option, the *ASBI Intervention App* must be served over a Hypertext Transfer Protocol Secure (HTTPS) connection.

#### EHR Launch
Navigate to the public SMART<sup>&reg;</sup> App Launcher and choose the "Provider EHR Launch" Launch Type. Leave all other options unselected. Paste the URL to where `public/launch_public_ehr.html` is being served from into the "App Launch URL" box at the bottom of the SMART<sup>&reg;</sup> App Launcher page. Select "Launch App!" which will bring up a patient selector widget before the *ASBI Intervention App* is launched.

#### Standalone Launch
Select the "Provider Standalone Launch" option in the public SMART<sup>&reg;</sup> App Launcher. Copy the "FHIR<sup>&reg;</sup> Server URL" shown at the bottom of the screen and paste it into the `iss` field in `public/launch_public_standalone.html`. Navigate to where `public/launch_public_standalone.html` is being served from and you should be redirected to the patient selector widget.

## License
(C) 2022 The MITRE Corporation. All Rights Reserved. Approved for Public Release: 20-0458. Distribution Unlimited.

Unless otherwise noted, this work is available under an Apache 2.0 license. It was produced by the MITRE Corporation for the National Center on Birth Defects and Developmental Disabilities, Centers for Disease Control and Prevention in accordance with the Statement of Work, contract number 75FCMC18D0047, task order number 75D30119F05691.

Any LOINC (http://loinc.org) content is copyright &copy; 1995+, Regenstrief Institute, Inc. and the Logical Observation Identifiers Names and Codes (LOINC) Committee and is available at no cost under the license at http://loinc.org/license. LOINC<sup>&reg;</sup> is a registered United States trademark of Regenstrief Institute, Inc.

References to and reproductions of the AUDIT alcohol screening instrument are made by permission from the World Health Organization (WHO). The WHO does not endorse this project, does not provide any warranty, and does not assume any liability for its use. For further information, please see:

Alcohol Use Disorders Identification Test - Guidelines for Use in Primary Care, Second Edition. Geneva, World Health Organization, 2001.

AUDIT (C) World Health Organization 2001

https://www.who.int/substance_abuse/activities/sbi/en/