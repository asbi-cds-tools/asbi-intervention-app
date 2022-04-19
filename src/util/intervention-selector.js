
import questionnaireUsAudit from '../fhir/Questionnaire-USAUDIT.json';
import questionnaireWhoAudit from '../fhir/Questionnaire-WHOAUDIT.json';
import questionnaireNidaQs from '../fhir/Questionnaire-NIDAQS2USAUDIT.json';
import elmJsonBriefIntervention from '../cql/BriefInterventionLogicLibrary.json';
import elmJsonDecisionAid from '../cql/DecisionAidLogicLibrary.json';
import valueSetJson from '../cql/valueset-db.json';


export function getIntervention() {
  let intervention = process.env.VUE_APP_ALCOHOL_INTERVENTION.toLowerCase();

  let allQuestionnaires = [
    questionnaireUsAudit,
    questionnaireWhoAudit,
    questionnaireNidaQs
  ];

  if (intervention == 'briefintervention') {
    return [allQuestionnaires, elmJsonBriefIntervention, valueSetJson];
  } else if (intervention == 'decisionaid') {
    return [allQuestionnaires, elmJsonDecisionAid, valueSetJson];
  } else {
    throw new Error('Unsupported alcohol intervention has been specified');
  }
}