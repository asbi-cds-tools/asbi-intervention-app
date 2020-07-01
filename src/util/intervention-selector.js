
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
    let namedExpression = 'BriefInterventions';
    return [allQuestionnaires, elmJsonBriefIntervention, valueSetJson, namedExpression];
  } else if (intervention == 'decisionaid') {
    let namedExpression = 'DecisionAids';
    return [[], elmJsonDecisionAid, valueSetJson, namedExpression];
  } else {
    throw new Error('Unsupported alcohol intervention has been specified');
  }
}