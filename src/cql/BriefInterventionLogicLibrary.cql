/*  Library: Alcohol Screening and Brief Intervention (ASBI) Clinical Decision Support (CDS): 
Brief Intervention and Referral Logic Library
    Author: CMS Alliance to Modernize Healthcare, operated by THE MITRE Corporation.

    (C) 2020 The MITRE Corporation. All Rights Reserved. Approved for Public Release: 20-0458. 
    Distribution Unlimited.

    Unless otherwise noted, this work is available under an Apache 2.0 license. 
    It was produced by the MITRE Corporation for the National Center on Birth Defects 
    and Developmental Disabilities, Centers for Disease Control and Prevention in 
    accordance with the Statement of Work, contract number 75FCMC18D0047, task order 
    number 75D30119F05691.

    References to and reproductions of the AUDIT alcohol screening instrument are made 
    by permission from the World Health Organization (WHO). The WHO does not endorse 
    this project, does not provide any warranty, and does not assume any liability 
    for its use. For further information, please see:

    Alcohol Use Disorders Identification Test - Guidelines for Use in Primary Care, 
    Second Edition. Geneva, World Health Organization, 2001.

    AUDIT (C) World Health Organization 2001

    https://www.who.int/substance_abuse/activities/sbi/en/
*/
library BriefInterventionAndReferralLogicLibrary version '1.0'

using FHIR version '4.0.0'

include "FHIRHelpers" version '4.0.0' called FHIRHelpers

// -----------------------------------------------------------------------------
// CODESYSTEMS, VALUE SETS, CODES, AND CONCEPTS
// -----------------------------------------------------------------------------

codesystem "LOINC": 'http://loinc.org'
codesystem "SNOMED-CT": 'http://snomed.info/sct'
codesystem "FHIR Condition Clinical Status": 'http://terminology.hl7.org/CodeSystem/condition-clinical'
codesystem "FHIR Condition Verification Status": 'http://terminology.hl7.org/CodeSystem/condition-ver-status'
codesystem "ADMINISTRATIVE GENDER": 'http://terminology.hl7.org/CodeSystem/v3-AdministrativeGender'
codesystem "NULL FLAVOR": 'http://terminology.hl7.org/CodeSystem/v3-NullFlavor'
codesystem "LOCAL": 'http://www.cdc.gov/ncbddd/fasd'

// [See value set in VSAC](https://vsac.nlm.nih.gov/valueset/2.16.840.1.113883.3.526.3.378/expansion)
valueset "Pregnancy": '2.16.840.1.113883.3.526.3.378'
// [See value set in VSAC](https://vsac.nlm.nih.gov/valueset/2.16.840.1.113762.1.4.1032.80/expansion)
valueset "Pregnancy (New ICD10 codes published in 2018 and 2019)": '2.16.840.1.113762.1.4.1032.80'
// [See value set in VSAC](https://vsac.nlm.nih.gov/valueset/2.16.840.1.113762.1.4.1032.124/expansion)
valueset "Alcohol screening intervention": '2.16.840.1.113762.1.4.1032.124'

// Standard codes
code "Pregnancy status code": '82810-3' from "LOINC" display 'Pregnancy status'
code "Pregnant code": '77386006' from "SNOMED-CT" display 'Patient currently pregnant (finding)'
code "Confirmed verification status code": 'confirmed' from "FHIR Condition Verification Status" display 'Confirmed'
code "Active clinical status code": 'active' from "FHIR Condition Clinical Status" display 'Active'
code "Recurrence clinical status code": 'recurrence' from "FHIR Condition Clinical Status" display 'Recurrence'
code "Relapse clinical status code": 'relapse' from "FHIR Condition Clinical Status" display 'Relapse'
code "Inactive clinical status code": 'inactive' from "FHIR Condition Clinical Status" display 'Inactive'
code "Remission clinical status code": 'remission' from "FHIR Condition Clinical Status" display 'Remission'
code "Resolved clinical status code": 'resolved' from "FHIR Condition Clinical Status" display 'Resolved'
code "Male administrative gender code": 'M' from "ADMINISTRATIVE GENDER" display 'Male'
code "Female administrative gender code": 'F' from "ADMINISTRATIVE GENDER" display 'Female'
code "Unknown value code": 'UNK' from "NULL FLAVOR" display 'Unknown'
code "WHO AUDIT-C Total Score code": '75626-2' from "LOINC" display 'WHO AUDIT-C Total Score'
code "WHO AUDIT Total Score code": '75624-7' from "LOINC" display 'WHO AUDIT Total Score'

// Local (non-standard) codes
code "USAUDIT-C Total Score code": 'UACS' from "LOCAL" display 'USAUDIT-C Total Score'
code "USAUDIT Total Score code": 'UAFS' from "LOCAL" display 'USAUDIT Total Score'
code "Yes": 'yes' from "LOCAL" display 'Yes'
code "No": 'no' from "LOCAL" display 'No'
code "Never": 'never' from "LOCAL" display 'Never'
code "Once or twice": 'onceortwice' from "LOCAL" display 'Once or twice'
code "Monthly": 'monthly' from "LOCAL" display 'Monthly'
code "Weekly": 'weekly' from "LOCAL" display 'Weekly'
code "Daily or Almost Daily": 'dailyoralmostdaily' from "LOCAL" display 'Daily or Almost Daily'

concept "Pregnancy status": { "Pregnancy status code" } display 'Pregnancy status'
concept "Pregnant": { "Pregnant code" } display 'Patient currently pregnant (finding)'
concept "Condition Confirmed": { "Confirmed verification status code" } display 'Confirmed'
concept "Condition Active": { "Active clinical status code" } display 'Active'
concept "Condition Recurrence": { "Recurrence clinical status code" } display 'Recurrence'
concept "Condition Relapse": { "Relapse clinical status code" } display 'Relapse'
concept "Condition Inactive": { "Inactive clinical status code" } display 'Inactive'
concept "Condition Remission": { "Remission clinical status code" } display 'Remission'
concept "Condition Resolved": { "Resolved clinical status code" } display 'Resolved'
concept "Alcohol screening codes": { 
  "WHO AUDIT-C Total Score code", "WHO AUDIT Total Score code" ,
  "USAUDIT-C Total Score code", "USAUDIT Total Score code"
  } display 'Alcohol screening codes'

// -----------------------------------------------------------------------------
// PATIENT INFORMATION
// -----------------------------------------------------------------------------
context Patient

// The patient's sex at birth is used in several parts of the logic.
// Sex at birth defined according to Office of the National Coordinator (ONC) Interoperability Standards Advisory (ISA):
// https://www.healthit.gov/isa/representing-patient-sex-birth 
define SexAtBirthExtension:
  singleton from (Patient.extension Ext
    where Ext.url = 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-birthsex')
  
define SexAtBirth:
  if SexAtBirthExtension is not null then 
    SexAtBirthExtension.value.value
  else "Unknown value code".code

define MaleAtBirth:
  SexAtBirth = "Male administrative gender code".code

define FemaleAtBirth:
  SexAtBirth = "Female administrative gender code".code

define SexAtBirthUnknown:
  SexAtBirth = "Unknown value code".code

// -----------------------------------------------------------------------------
// FUNCTIONS
// -----------------------------------------------------------------------------

define function ToCode(coding FHIR.Coding):
  FHIRHelpers.ToCode(coding)

define function ToConcept(concept FHIR.CodeableConcept):
  FHIRHelpers.ToConcept(concept)

// From the CDS Connect Commons Library
// Available from the Agency for Healthcare Research and Quality (AHRQ) under an 
// Apache 2.0 license. See https://cds.ahrq.gov
define function PeriodToInterval(period FHIR.Period):
  if period is null then
    null
  else
    Interval[period."start".value, period."end".value]

// -----------------------------------------------------------------------------
// INCLUSIONS LOGIC
// -----------------------------------------------------------------------------

// The lookback for previous alcohol screening results
define RecentAlcoholScreeningLookbackStart:
  Today() - 1 year

// Load any previously completed QuestionnaireReponses for alcohol screening in 
// the past 12 months and sort by date authored.
define PreviouslyCompletedQuestionnaireResponses:
  [QuestionnaireResponse] QR
    where date from QR.authored.value between RecentAlcoholScreeningLookbackStart and Today()
      and QR.status.value in {'completed', 'amended'}
      and (QR.questionnaire.value = 'http://www.cdc.gov/ncbddd/fasd/usaudit'
        or QR.questionnaire.value = 'http://www.cdc.gov/ncbddd/fasd/audit'
        or QR.questionnaire.value = 'http://www.cdc.gov/ncbddd/fasd/nidaqs2usaudit')
    sort by authored asc

// We're interested in the most recently completed alcohol screening responses.
define MostRecentlyCompletedQuestionnaireResponse:
  Last(PreviouslyCompletedQuestionnaireResponses)

// The URL of the Questionnaire associated with the most recent responses.
define MostRecentQuestionnaireURL:
  MostRecentlyCompletedQuestionnaireResponse.questionnaire.value

// The date of last screening is needed for determining whether an intervention 
// needs to occur.
define DateOfMostRecentQuestionnaireResponse:
  MostRecentlyCompletedQuestionnaireResponse QR
  return date from QR.authored.value

// Get the response items from the most recently completed QuestionnaireResponse
define MostRecentResponseItems:
  MostRecentlyCompletedQuestionnaireResponse QR
  return all QR.item

// Reshape the response items to make them easier to process
define MostRecentResponseValues:
  (flatten MostRecentResponseItems) T return all Tuple {
    id: T.linkId.value,
    answer: T.answer.value[0]
  }

// Find previous USAUDIT-C score
define RecentScoreUsAuditC:
  singleton from ((MostRecentResponseValues) RV
    where RV.id = 'usauditc-score'
    return RV.answer.value)

// Did they receive a USAUDIT-C score?
define HasRecentScoreUsAuditC:
  RecentScoreUsAuditC is not null

// Find previous full USAUDIT score
define RecentScoreFullUsAudit:
  singleton from ((MostRecentResponseValues) RV
    where RV.id = 'usaudit-score'
    return RV.answer.value)

// Did they receive a full USAUDIT score?
define HasRecentScoreFullUsAudit:
  RecentScoreFullUsAudit is not null

// Find previous AUDIT-C score
define RecentScoreAuditC:
  singleton from ((MostRecentResponseValues) RV
    where RV.id = 'auditc-score'
    return RV.answer.value)

// Did they receive an AUDIT-C score?
define HasRecentScoreAuditC:
  RecentScoreAuditC is not null
  
// Find previous full AUDIT score
define RecentScoreFullAudit:
  singleton from ((MostRecentResponseValues) RV
    where RV.id = 'audit-score'
    return RV.answer.value)

// Did they receive a full AUDIT score?
define HasRecentScoreFullAudit:
  RecentScoreFullAudit is not null

// Recent response to the alcohol pre-screen (APS) question
define RecentApsResponses:
  (MostRecentResponseValues) RV
  where RV.id = 'prescreen-question'
  return RV.answer

// Recent APS "Yes" response
define RecentApsYesResponses:
  (RecentApsResponses) R
  where R ~ "Yes"

// Recent APS "No" response
define RecentApsNoResponses:
  (RecentApsResponses) R
  where R ~ "No"

// Did they recently answer "Yes" to the APS question?
define HasRecentYesApsResponse:
  Exists(RecentApsYesResponses)

// Did they recently answer "No" to the APS question?
define HasRecentNoApsResponse:
  Exists(RecentApsNoResponses)

// Recent response to the USAUDIT Question 1
define RecentUsauditQuestionOneResponses:
  (MostRecentResponseValues) RV
  where RV.id = 'usaudit-question-one'
  return RV.answer

// Recent response to the AUDIT Question 1
define RecentAuditQuestionOneResponses:
  (MostRecentResponseValues) RV
  where RV.id = 'audit-question-one'
  return RV.answer

// Did they recently answer "Never" to Question One of the USAUDIT?
define HasRecentNeverResponseUsauditQuestionOne:
  "Never" in RecentUsauditQuestionOneResponses

// Did they recently answer "Never" to Question One of the AUDIT?
define HasRecentNeverResponseAuditQuestionOne:
  "Never" in RecentAuditQuestionOneResponses

define RecentAlcoholScreeningObservations:
  [Observation: "Alcohol screening codes"] O
    where 
      (date from O.effective.value between RecentAlcoholScreeningLookbackStart and Today()
        or date from O.issued.value between RecentAlcoholScreeningLookbackStart and Today())
      and O.status.value in {'final', 'corrected', 'amended'}
    sort by date from Coalesce(effective, issued).value asc

define HasRecentAlcoholScreeningObservations:
  Exists(RecentAlcoholScreeningObservations)

define MostRecentAlcoholScreeningObservation:
  Last(RecentAlcoholScreeningObservations)

define DateOfMostRecentAlcoholScreeningObservation:
  date from Coalesce(
    MostRecentAlcoholScreeningObservation.effective, 
    MostRecentAlcoholScreeningObservation.issued
  ).value

// Is there any evidence of a recent alcohol screening?
define HasEvidenceOfRecentAlcoholScreening:
  HasRecentScoreUsAuditC
  or HasRecentScoreFullUsAudit
  or HasRecentScoreAuditC
  or HasRecentScoreFullAudit
  or HasRecentNoApsResponse
  or (HasRecentYesApsResponse
    and (
      HasRecentNeverResponseUsauditQuestionOne
      or HasRecentNeverResponseAuditQuestionOne
    ))
  or HasRecentAlcoholScreeningObservations

define IsIncluded:
  AgeInYears() >= 18
  and HasEvidenceOfRecentAlcoholScreening

// -----------------------------------------------------------------------------
// EXCLUSION LOGIC
// -----------------------------------------------------------------------------

define MostRecentAlcoholScreeningDate:
  if DateOfMostRecentQuestionnaireResponse is not null then
    if DateOfMostRecentAlcoholScreeningObservation is not null then
      if DateOfMostRecentQuestionnaireResponse same or after DateOfMostRecentAlcoholScreeningObservation then
        DateOfMostRecentQuestionnaireResponse
      else
        DateOfMostRecentAlcoholScreeningObservation
    else
      DateOfMostRecentQuestionnaireResponse
  else
    if DateOfMostRecentAlcoholScreeningObservation is not null then
      DateOfMostRecentAlcoholScreeningObservation
    else
      null

// Find any interventions that occured on or after the date of last screening
define BriefInterventionsSinceLastScreening:
  [Procedure: "Alcohol screening intervention"] P
    where P.status.value = 'completed' and
      date from P.performed.value same or after MostRecentAlcoholScreeningDate

// No intervention is needed if one has already occured since last screening
define Excluded:
  Exists(BriefInterventionsSinceLastScreening)

// -----------------------------------------------------------------------------
// CONSIDER PREGNANCY STATUS
// -----------------------------------------------------------------------------
// Verified pregnancy Observations in the last 42 weeks:
// Defined as FHIR Observations with the "Pregnancy status" code, from any time in the last 42 weeks, 
// with a value indicating patient is pregnant, and with a status indicating the Observation has been 
// verified.
define PregnancyObservations:
  [Observation: "Pregnancy status"] P
    let lookback: Interval[Now() - 42 weeks, Now()]
    where 
      ((P.effective as FHIR.dateTime).value in lookback
        or P.issued.value in lookback)
      and ToConcept(P.value as FHIR.CodeableConcept) ~ "Pregnant"
      and P.status.value in {'final', 'corrected', 'amended'}

define PregnancyConditions:
  ([Condition: "Pregnancy"] union [Condition: "Pregnancy (New ICD10 codes published in 2018 and 2019)"]) C
    let lookback: Interval[Now() - 42 weeks, Now()]
    where 
      ((C.onset as FHIR.dateTime).value in lookback
        or PeriodToInterval(C.onset as FHIR.Period) overlaps lookback
        or C.recordedDate.value in lookback)
      and (C.clinicalStatus ~ "Condition Active"
        or C.clinicalStatus ~ "Condition Recurrence")
      and C.verificationStatus ~ "Condition Confirmed"

// Recent response to the pregnancy question
define RecentPregnancyQuestionResponse:
  (MostRecentResponseValues) RV
  where RV.id = 'pregnancy-question'
  return RV.answer

// Did they recently answer "Yes" to the pregnancy question?
define HasRecentYesToPregnancyQuestion:
  "Yes" in RecentPregnancyQuestionResponse

// Does the patient meet the pregnancy inclusion criteria?
define DoesMeetPregnancyInclusionCriteria:
  Exists(PregnancyObservations) 
    or Exists(PregnancyConditions)
    or HasRecentYesToPregnancyQuestion

//------------------------------------------------------------------------------
// PARSE QUESTIONNAIRE AND QUESTIONNAIRERESPONSE
//------------------------------------------------------------------------------

// Load the Questionnaire associated with the most recent response
define MostRecentQuestionnaire:
  singleton from ([Questionnaire] Q
    where Q.url.value = MostRecentQuestionnaireURL)

// Get the items from the most recent Questionnaire
define MostRecentQuestionnaireItems:
  MostRecentQuestionnaire Q
  return all Q.item

// Get the text for each of the questions from the most recent Questionnaire
define MostRecentQuestionText:
  (flatten MostRecentQuestionnaireItems) T return all Tuple {
    id: T.linkId.value,
    question: T.text.value
  }

// Combine the questions and answers into one structure for ease of access
define QuestionResponsePairs:
  from 
    "MostRecentQuestionText" QT,
    "MostRecentResponseValues" RV
  where QT.id = RV.id and (RV.answer as FHIR.Coding).display is not null
  return Tuple {
    id: QT.id,
    question: QT.question,
    answer: RV.answer.display.value
  }

// Segment out the NIDA QS questions and responses not related to alcohol
define NonAlcoholQuestionResponsePairs:
  (QuestionResponsePairs) QRP
    where PositionOf('nidaqs', QRP.id) != -1
     and PositionOf('nidaqs-alcohol', QRP.id) = -1
    return Tuple {
      question: QRP.question,
      answer: QRP.answer
    }

// These are all the question and responses that are related to alcohol
define AlcoholQuestionResponsePairs:
  (QuestionResponsePairs) QRP
    where PositionOf('nidaqs', QRP.id) = -1
      or PositionOf('nidaqs-alcohol', QRP.id) != -1
    return Tuple {
      question: QRP.question,
      answer: QRP.answer
    }

//------------------------------------------------------------------------------
// 1) NOTIFICATION
//------------------------------------------------------------------------------

define DisplayNotification:
  IsIncluded and not Excluded

define NotificationText:
  if DisplayNotification then 'New screening results are available!'
  else ''

//------------------------------------------------------------------------------
// 2) ALCOHOL SCREENING RESULTS
//------------------------------------------------------------------------------

// What variant of the AUDIT was used in the most recent alcohol screening?
define AuditVariant:
  if MostRecentQuestionnaireURL = 'http://www.cdc.gov/ncbddd/fasd/usaudit'
    or MostRecentQuestionnaireURL = 'http://www.cdc.gov/ncbddd/fasd/nidaqs2usaudit'
    then 'USAUDIT'
  else if MostRecentQuestionnaireURL = 'http://www.cdc.gov/ncbddd/fasd/audit'
    then 'AUDIT'
  else null

// The AUDIT scores for Zone 1 depend upon age and sex at birth.
define ScoreBracketZoneOne:
  if FemaleAtBirth
    or SexAtBirthUnknown
    or (MaleAtBirth and AgeInYears() > 65)
  then Interval[0, 6]
  else Interval[0, 7] // (SexAtBirth = 'Male' and AgeInYears <= 65)

// The AUDIT scores for Zone 2 depend upon age and sex at birth.
define ScoreBracketZoneTwo:
  if FemaleAtBirth
    or SexAtBirthUnknown
    or (MaleAtBirth and AgeInYears() > 65)
  then Interval[7, 15]
  else Interval[8, 15] // (SexAtBirth = 'Male' and AgeInYears <= 65)

// The AUDIT scores for Zone 3 depends upon the variant of the AUDIT.
define ScoreBracketZoneThree:
  if AuditVariant = 'USAUDIT' then Interval[16, 24]
  else if AuditVariant = 'AUDIT' then Interval[16, 19]
  else null

// The AUDIT scores for Zone 4 depends upon the variant of the AUDIT.
define ScoreBracketZoneFour:
  if AuditVariant = 'USAUDIT' then Interval[25, 46]
  else if AuditVariant = 'AUDIT' then Interval[20, 40]
  else null

// Get the most recent alcohol screening score
define MostRecentScreeningScore:
  if HasRecentScoreFullUsAudit then (convert RecentScoreFullUsAudit as String to Integer)
  else if HasRecentScoreUsAuditC then (convert RecentScoreUsAuditC as String to Integer)
  else if HasRecentScoreFullAudit then (convert RecentScoreFullAudit as String to Integer)
  else if HasRecentScoreAuditC then (convert RecentScoreAuditC as String to Integer)
  else 0

// According to the most recent alcohol screening responses, is the patient a 
// Zone 1 drinker?
define IsZoneOneDrinker:
  MostRecentScreeningScore in ScoreBracketZoneOne

// According to the most recent alcohol screening responses, is the patient a 
// Zone 2 drinker?
define IsZoneTwoDrinker:
  MostRecentScreeningScore in ScoreBracketZoneTwo

// According to the most recent alcohol screening responses, is the patient a 
// Zone 3 drinker?
define IsZoneThreeDrinker:
  MostRecentScreeningScore in ScoreBracketZoneThree

// According to the most recent alcohol screening responses, is the patient a 
// Zone 4 drinker?
define IsZoneFourDrinker:
  MostRecentScreeningScore in ScoreBracketZoneFour

define ZoneNumber:
  if IsZoneOneDrinker then 1
  else if IsZoneTwoDrinker then 2
  else if IsZoneThreeDrinker then 3
  else if IsZoneFourDrinker then 4
  else 0

define ZoneRomanNumeral:
  if IsZoneOneDrinker then 'I'
  else if IsZoneTwoDrinker then 'II'
  else if IsZoneThreeDrinker then 'III'
  else if IsZoneFourDrinker then 'IV'
  else ''

define PregnantAndDrinking:
  DoesMeetPregnancyInclusionCriteria 
  and not (
    HasRecentNoApsResponse
    or (HasRecentYesApsResponse 
      and (HasRecentNeverResponseUsauditQuestionOne
        or HasRecentNeverResponseAuditQuestionOne))
    or (MostRecentScreeningScore = 0
      and not Exists(NonAlcoholQuestionResponsePairs))
  )

define PregnantAndNotDrinking:
  DoesMeetPregnancyInclusionCriteria and not PregnantAndDrinking

define AlcoholScreeningResultsTextSummaryPartOne:
  if PregnantAndNotDrinking then 
    'The patient indicates they do not drink alcohol\n'
  else if PregnantAndDrinking then
    'The patient indicates they are drinking alcohol. There is NO known safe amount of alcohol use during pregnancy or while trying to become pregnant.<sup>*</sup>\n'
  else (
    if IsZoneOneDrinker then 
      'The patient’s screening results indicate low risk drinking or abstinence. '
    else if IsZoneTwoDrinker or IsZoneThreeDrinker or IsZoneFourDrinker then
      'The patient indicates they are drinking alcohol. '
    else ''
  )

define AlcoholScreeningResultsTextSummaryPartTwo:
  if PregnantAndNotDrinking then
    ''
  else
    'The patient’s screening score is ' 
      + convert MostRecentScreeningScore to String
      + ', and falls within Zone '
      + ZoneRomanNumeral

define AlcoholScreeningResultsTextSummaryPartThree:
  if PregnantAndNotDrinking then
    ''
  else if PregnantAndDrinking then (
    if IsZoneOneDrinker then ', which for NONPREGNANT individuals indicates low-risk drinking.\n'
    else if IsZoneTwoDrinker then ', which for NONPREGNANT individuals indicates drinking in excess of guidelines.'
    else if IsZoneThreeDrinker then ', which for NONPREGNANT individuals indicates harmful or hazardous drinking.'
    else if IsZoneFourDrinker then ', which for NONPREGNANT individuals indicates high-risk drinking and probable alcohol dependence.'
    else ''
  )
  else (
    if IsZoneOneDrinker then '.\n'
    else if IsZoneTwoDrinker then ', indicating they are drinking in excess of guidelines.\n'
    else if IsZoneThreeDrinker then ', indicating harmful or hazardous drinking.\n'
    else if IsZoneFourDrinker then ', indicating high-risk drinking and probable alcohol dependence.\n'
    else ''
  )

define AlcoholScreeningResultsTextSummaryPartFour:
  if PregnantAndDrinking then '\n<sup>*</sup> Centers for Disease Control and Prevention (CDC). CDC’s Alcohol Screening and Brief Intervention Efforts. [https://www.cdc.gov/ncbddd/fasd/alcohol-screening.html](https://www.cdc.gov/ncbddd/fasd/alcohol-screening.html). Accessed February 18, 2020.'
  else ''

define AlcoholScreeningResultsTextSummary:
  AlcoholScreeningResultsTextSummaryPartOne
  + AlcoholScreeningResultsTextSummaryPartTwo
  + AlcoholScreeningResultsTextSummaryPartThree
  + AlcoholScreeningResultsTextSummaryPartFour

define AlcoholScreeningResultsSummary:
  Tuple {
    summary: AlcoholScreeningResultsTextSummary,
    score: MostRecentScreeningScore,
    zone: ZoneNumber,
    responses: AlcoholQuestionResponsePairs
  }

//------------------------------------------------------------------------------
// 3) ALCOHOL-RELATED COUNSELING SUGGESTIONS
//------------------------------------------------------------------------------

define AlcoholCounselingSuggestionText:
  if DisplayNotification then (
    if PregnantAndNotDrinking then 'For patients that are pregnant or trying to become pregnant whose screening response indicates they are not currently drinking alcohol, brief counseling interventions increase the likelihood that they will remain abstinent during pregnancy.<sup>1</sup> ACOG and several other organizations suggest the following talking points:<sup>2,3,4</sup>\n- Praise the patient for not drinking.\n- Emphasize the importance of continuing to not drink at any time during pregnancy, or while trying to become pregnant.\n- Reinforce to the patient that there is no known safe amount of alcohol use in pregnancy or while trying to become pregnant.\n  * Alcohol use during pregnancy can cause [birth defects](https://www.cdc.gov/ncbddd/birthdefects/index.html) and [developmental disabilities](https://www.cdc.gov/ncbddd/developmentaldisabilities/index.html), collectively known as [fetal alcohol spectrum disorders](https://www.cdc.gov/ncbddd/fasd/) (FASDs). FASDs are preventable if a developing baby is not exposed to alcohol before birth.\n  * Alcohol use during pregnancy is also linked to other outcomes, such as miscarriage, stillbirth, preterm (early) birth, and sudden infant death syndrome (SIDS).\n- Provide the patient with the patient education references listed below if additional information about drinking and pregnancy is requested by the patient, or if you feel it may be warranted.\n'
    else if PregnantAndDrinking then 'For patients that are pregnant or trying to become pregnant whose screening responses indicate they are currently drinking alcohol, ANY alcohol use is considered excessive. ACOG and several other organizations suggest the following talking points:<sup>1,2,4</sup>\n- Provide non-judgmental feedback and advice on ceasing alcohol use during pregnancy.\n- Emphasize that there is no known safe amount of alcohol a woman can consume during pregnancy, or while they are trying to become pregnant.\n  * Alcohol use during pregnancy can cause birth defects and developmental disabilities, collectively known as fetal alcohol spectrum disorders (FASDs). FASDs are preventable if a developing baby is not exposed to alcohol before birth.\n  * Alcohol use during pregnancy is also linked to other outcomes, such as miscarriage, stillbirth, preterm (early) birth, and sudden infant death syndrome (SIDS).\n * It is not safe to drink at any time during pregnancy, including the earliest stage of pregnancy before you may know you are pregnant.\n- Offer an appropriate follow-up visit with the patient.\n- Provide the patient with the patient education resources listed below if additional information about drinking and pregnancy is requested by the patient, or if you feel it may be warranted.\n\nIf you think the patient may be unable to reduce or eliminate their alcohol use, or may be dependent on alcohol, consider referring the patient for diagnostic evaluation and possible treatment of alcohol use disorder.<sup>3</sup>\n'
    else (
      if IsZoneOneDrinker then 'For patients in Zone I, brief counseling can serve to reinforce low risk drinking, and could be effective if the patient underreported their drinking when responding to the screening questions, or might have had past problems with risky drinking.<sup>1</sup>\n- Acknowledge and praise the patient’s abstinence or low risk alcohol use.\n- Consider the patient’s responses to AUDIT questions \#9 and \#10, if present. Points scored on these two questions could indicate past problems with alcohol, and the patient may need to be advised to avoid alcohol.<sup>2, 3</sup>\n- If the patient is not abstinent, reinforce the following:\n  * What constitutes a standard drink in the United States (e.g., one 12 ounce can of beer, 5 ounces of table wine, or 1.5 ounces of 80-proof gin, vodka, whiskey, etc.)\n  * The recommended frequency and quantity of alcohol intake to stay within low risk guidelines:<sup>2</sup>\n    + Men up to and including age 65: no more than 4 drinks on any single day and no more than 14 drinks per week.\n    + Men ages 66 and older and all women: no more than 3 drinks on any single day and no more than 7 drinks per week.\n-	Provide education regarding when the patient should avoid drinking alcohol, based on relevant patient factors:<sup>2</sup>\n  * Taking medications that interact with alcohol\n  * Having a medical condition made worse by drinking\n  * Being under the legal drinking age\n  * Planning to drive or operate machinery\n  *	Being pregnant or trying to become pregnant\n-	Provide the patient with the patient education resources listed below.\n'
      else if IsZoneTwoDrinker then 'For patients in Zone II, a brief intervention using simple advice on the reduction of drinking, engaging the patient in reflective motivational conversations, and providing patient education materials may be the most appropriate course of action.<sup>1,2,3</sup>\n- Provide information to the patient on their screening results.\n- Reinforce the following information with the patient:\n  * What constitutes a standard drink in the United States (e.g., one 12 ounce can of beer, 5 ounces of table wine, or 1.5 ounces of 80-proof gin, vodka, whiskey, etc.)\n  * The recommended frequency and quantity of alcohol intake to stay within low risk guidelines:<sup>3</sup>\n    + Men up to and including age 65: no more than 4 drinks on any single day and no more than 14 drinks per week.\n    + All women and men ages 66 and older: no more than 3 drinks on any single day and no more than 7 drinks per week.- Discuss the patient’s responses to the AUDIT questions that may indicate particular concern:\n  * Responses to questions #4, #5, and #6 could indicate alcohol dependence symptoms, and responses to question #9 or #10 may indicate past problems with alcohol.<sup>3,4</sup>\n- Provide education regarding when the patient should avoid drinking alcohol, based on relevant patient factors:<sup>3</sup>\n  * Taking medications that interact with alcohol\n  * Having a medical condition made worse by drinking\n  * Being under the legal drinking age\n  * Planning to drive or operate machinery\n  * Being pregnant or trying to become pregnant\n- Provide the patient with the patient education resources listed below.\n'
      else if IsZoneThreeDrinker then 'For patients in Zone III, a combination of feedback, brief counseling, and continued monitoring may be effective, with further diagnostic evaluation indicated if the patient fails to respond or is suspected of alcohol dependence.<sup>1,2,3</sup>\n- Provide feedback to the patient on their screening results.\n- Reinforce the following information with the patient:\n  * What constitutes a standard drink in the United States (e.g., one 12 ounce can of beer, 5 ounces of table wine, or 1.5 ounces of 80-proof gin, vodka, whiskey, etc.)\n  * The recommended frequency and quantity of alcohol intake to stay within low risk guidelines:<sup>3</sup>\n    + Men up to age 65: no more than 4 drinks on any single day and no more than 14 drinks per week.\n    + Women and men ages 66 and older: no more than 3 drinks on any single day and no more than 7 drinks per week.\n- Discuss the patient’s responses to any screening questions that may indicate particular concern:\n  * Responses to questions #4, #5, and #6 could indicate dependence symptoms, and responses to questions #9 or #10 may indicate past problems with alcohol.<sup>3,4</sup>\n- Provide education regarding when you should avoid drinking alcohol, based on relevant patient factors:<sup>3</sup>\n  * Taking medications that interact with alcohol\n  * Having a medical condition made worse by drinking\n  * Being under the legal drinking age\n  * Planning to drive or operate machinery\n  * Being pregnant or trying to become pregnant\n- Offer an appropriate follow-up visit with the patient.\n- Provide the patient with the patient education resources listed below.\n\nIf you think the patient may be dependent on alcohol, consider referring the patient for diagnostic evaluation and possible treatment of alcohol use disorder.'
      else if IsZoneFourDrinker then 'Patients in Zone IV, which suggests alcohol dependence, should be referred to a specialist for diagnostic evaluation and possible treatment.<sup>1,2,3</sup>\n- Provide feedback to the patient on their screening results, including the following:\n  * The patient’s level of drinking far exceeds safe guidelines, and specific problems related to drinking are already present\n  * The patient has signs of alcohol dependence\n- Discuss the need for referral to a specialist for diagnostic evaluation and possible treatment of alcohol use disorder with the patient, and encourage the patient to see the specialist.\n- Offer an appropriate follow-up visit with the patient.\n- Provide the patient with the patient education resources listed below.\n'
      else ''
    )
 ) else ''

define AdditionalBriefInterventionConsiderations: {
  if PregnantAndDrinking then 'Additional guidance on the important components of conducting a brief intervention:\n- Raise the subject\n- Provide feedback about screening results\n- Ask patients what they like and what they don’t like about their drinking (in that order)\n- Ask if they would like your medical advice\n- Listen for “change talk” to assess how ready the patient is to modify his or her behavior\n- Provide options the patient can choose from to develop a plan\n- Seek agreement for a follow‐up visit\n- Thank patient\n'
  else ''
}

define AlcoholCounselingSuggestionReferences:
  if DisplayNotification then (
    if PregnantAndNotDrinking or PregnantAndDrinking then '1. Curry SJ, Krist AH, Owens DK, et al. Screening and Behavioral Counseling Interventions to Reduce Unhealthy Alcohol Use in Adolescents and Adults: US Preventive Services Task Force Recommendation Statement. JAMA - J Am Med Assoc. 2018;320(18):1899-1909. doi:10.1001/jama.2018.16789\n2. The American College of Obstetricians and Gynecologists. At-Risk Drinking and Alcohol Dependence: Obstetric and Gynecologic Implications - ACOG. Committee on Health Care for Underserved Women. [https://www.acog.org/Clinical-Guidance-and-Publications/Committee-Opinions/Committee-on-Health-Care-for-Underserved-Women/At-Risk-Drinking-and-Alcohol-Dependence-Obstetric-and-Gynecologic-Implications](https://www.acog.org/Clinical-Guidance-and-Publications/Committee-Opinions/Committee-on-Health-Care-for-Underserved-Women/At-Risk-Drinking-and-Alcohol-Dependence-Obstetric-and-Gynecologic-Implications). Published 2011. Accessed January 21, 2020.\n3. World Health Organization. Guidelines for the Identification and Management of Substance Use and Substance Use Disorders in Pregnancy. Vol 34.; 2014. [http://www.ncbi.nlm.nih.gov/pubmed/24783312](http://www.ncbi.nlm.nih.gov/pubmed/24783312). Accessed October 2, 2019.\n4. Centers for Disease Control and Prevention (CDC). CDC’s Alcohol Screening and Brief Intervention Efforts. [https://www.cdc.gov/ncbddd/fasd/alcohol-screening.html](https://www.cdc.gov/ncbddd/fasd/alcohol-screening.html). Accessed February 18, 2020.\n'
    else (
      if IsZoneOneDrinker then '1. Babor TF, Higgins-Biddle JC. Brief Intervention for Hazardous and Harmful Drinking: A Manual for Use in Primary Care.; 2001. [https://apps.who.int/iris/bitstream/handle/10665/67210/WHO_MSD_MSB_01.6b.pdf?sequence=1](https://apps.who.int/iris/bitstream/handle/10665/67210/WHO_MSD_MSB_01.6b.pdf?sequence=1)\n2. Babor TF, Higgins-Biddle JC, Robaina K. The Alcohol Use Disorders Identification Test, Adapted for Use in the United States: A Guide for Primary Care Practitioners.; 2017. [https://www.dshs.wa.gov/sites/default/files/BHSIA/dbh/wasbirt/USAUDIT-Guide_2016.pdf](https://www.dshs.wa.gov/sites/default/files/BHSIA/dbh/wasbirt/USAUDIT-Guide_2016.pdf)\n3. Babor TF, Higgins-Biddle JC, Saunders JB, Monteiro MG. The Alcohol Use Disorders Identification Test: Guidelines for Use in Primary Care.; 2001. [https://www.who.int/substance_abuse/publications/audit/en/](https://www.who.int/substance_abuse/publications/audit/en/). Accessed October 10, 2019.\n'
      else if IsZoneTwoDrinker then '1. Babor TF, Higgins-Biddle JC. Brief Intervention for Hazardous and Harmful Drinking: A Manual for Use in Primary Care.; 2001. [https://apps.who.int/iris/bitstream/handle/10665/67210/WHO_MSD_MSB_01.6b.pdf?sequence=1](https://apps.who.int/iris/bitstream/handle/10665/67210/WHO_MSD_MSB_01.6b.pdf?sequence=1)\n2. Higgins-Biddle JC, Hungerford DW, Baker SD, et al. Planning and Implementing Screening and Brief Intervention for Risky Alcohol Use A Step-by-Step Guide for Primary Care Practices. Centers Dis Control Prev Natl Cent Birth Defects Dev Disabil. 2014.\n3. Babor TF, Higgins-Biddle JC, Robaina K. The Alcohol Use Disorders Identification Test, Adapted for Use in the United States: A Guide for Primary Care Practitioners.; 2017. [https://www.dshs.wa.gov/sites/default/files/BHSIA/dbh/wasbirt/USAUDIT-Guide_2016.pdf](https://www.dshs.wa.gov/sites/default/files/BHSIA/dbh/wasbirt/USAUDIT-Guide_2016.pdf)\n4. Babor TF, Higgins-Biddle JC, Saunders JB, Monteiro MG. The Alcohol Use Disorders Identification Test: Guidelines for Use in Primary Care.; 2001. [https://www.who.int/substance_abuse/publications/audit/en/](https://www.who.int/substance_abuse/publications/audit/en/). Accessed October 10, 2019.\n'
      else if IsZoneThreeDrinker then '1. Babor TF, Higgins-Biddle JC. Brief Intervention for Hazardous and Harmful Drinking: A Manual for Use in Primary Care.; 2001. [https://apps.who.int/iris/bitstream/handle/10665/67210/WHO_MSD_MSB_01.6b.pdf?sequence=1](https://apps.who.int/iris/bitstream/handle/10665/67210/WHO_MSD_MSB_01.6b.pdf?sequence=1)\n2. Higgins-Biddle JC, Hungerford DW, Baker SD, et al. Planning and Implementing Screening and Brief Intervention for Risky Alcohol Use A Step-by-Step Guide for Primary Care Practices. Centers Dis Control Prev Natl Cent Birth Defects Dev Disabil. 2014.\n3. Babor TF, Higgins-Biddle JC, Robaina K. The Alcohol Use Disorders Identification Test, Adapted for Use in the United States: A Guide for Primary Care Practitioners.; 2017. [https://www.dshs.wa.gov/sites/default/files/BHSIA/dbh/wasbirt/USAUDIT-Guide_2016.pdf](https://www.dshs.wa.gov/sites/default/files/BHSIA/dbh/wasbirt/USAUDIT-Guide_2016.pdf)\n4. Babor TF, Higgins-Biddle JC, Saunders JB, Monteiro MG. The Alcohol Use Disorders Identification Test: Guidelines for Use in Primary Care.; 2001. [https://www.who.int/substance_abuse/publications/audit/en/](https://www.who.int/substance_abuse/publications/audit/en/). Accessed October 10, 2019.\n'
      else if IsZoneFourDrinker then '1. Babor TF, Higgins-Biddle JC. Brief Intervention for Hazardous and Harmful Drinking: A Manual for Use in Primary Care.; 2001. [https://apps.who.int/iris/bitstream/handle/10665/67210/WHO_MSD_MSB_01.6b.pdf?sequence=1](https://apps.who.int/iris/bitstream/handle/10665/67210/WHO_MSD_MSB_01.6b.pdf?sequence=1)\n2. Higgins-Biddle JC, Hungerford DW, Baker SD, et al. Planning and Implementing Screening and Brief Intervention for Risky Alcohol Use A Step-by-Step Guide for Primary Care Practices. Centers Dis Control Prev Natl Cent Birth Defects Dev Disabil. 2014.\n3. Babor TF, Higgins-Biddle JC, Robaina K. The Alcohol Use Disorders Identification Test, Adapted for Use in the United States: A Guide for Primary Care Practitioners.; 2017. [https://www.dshs.wa.gov/sites/default/files/BHSIA/dbh/wasbirt/USAUDIT-Guide_2016.pdf](https://www.dshs.wa.gov/sites/default/files/BHSIA/dbh/wasbirt/USAUDIT-Guide_2016.pdf)\n'
      else ''
    )
  ) else ''

define AlcoholTreatmentReferralSuggested:
  if DisplayNotification and (IsZoneThreeDrinker or IsZoneFourDrinker or PregnantAndDrinking) then true
  else false

define AlcoholCounselingSuggestions:
  Tuple {
    suggestions: AlcoholCounselingSuggestionText,
    additional: AdditionalBriefInterventionConsiderations,
    references: AlcoholCounselingSuggestionReferences,
    referral: AlcoholTreatmentReferralSuggested
  }

//------------------------------------------------------------------------------
// 4) ALCOHOL-RELATED PATIENT EDUCATION RESOURCES
//------------------------------------------------------------------------------

define AlcoholPatientEducationResources:
  if DisplayNotification then (
    if PregnantAndNotDrinking then '- Find out more about “Alcohol Use in Pregnancy”: [https://www.cdc.gov/ncbddd/fasd/alcohol-use.html](https://www.cdc.gov/ncbddd/fasd/alcohol-use.html)\n- Fact Sheet on Fetal Alcohol Spectrum Disorders (FASDS): [https://www.cdc.gov/ncbddd/fasd/documents/fasd_english-508.pdf](https://www.cdc.gov/ncbddd/fasd/documents/fasd_english-508.pdf)\n- An Alcohol-Free Pregnancy is the Best Choice for Your Baby (brochure): [https://www.cdc.gov/ncbddd/fasd/documents/FASDBrochure_final-508.pdf](https://www.cdc.gov/ncbddd/fasd/documents/FASDBrochure_final-508.pdf)\n'
    else if PregnantAndDrinking then '- 5 Things You Should Know About Drinking Alcohol During Pregnancy: [https://www.cdc.gov/ncbddd/fasd/women.html](https://www.cdc.gov/ncbddd/fasd/women.html)\n- Alcohol Use in Pregnancy: [https://www.cdc.gov/ncbddd/fasd/alcohol-use.html](https://www.cdc.gov/ncbddd/fasd/alcohol-use.html)\n- Fact Sheet on Fetal Alcohol Spectrum Disorders (FASDS): [https://www.cdc.gov/ncbddd/fasd/documents/fasd_english-508.pdf](https://www.cdc.gov/ncbddd/fasd/documents/fasd_english-508.pdf)\n- An Alcohol-Free Pregnancy is the Best Choice for Your Baby (brochure): [https://www.cdc.gov/ncbddd/fasd/factsheets.html](https://www.cdc.gov/ncbddd/fasd/factsheets.html)\n'
    else (
      if IsZoneOneDrinker then '- What Is A Standard Drink?: [https://www.niaaa.nih.gov/what-standard-drink](https://www.niaaa.nih.gov/what-standard-drink)\n- Alcohol Use And Your Health: [https://www.cdc.gov/alcohol/fact-sheets/alcohol-use.htm](https://www.cdc.gov/alcohol/fact-sheets/alcohol-use.htm)\n'
      else if IsZoneTwoDrinker then '- Rethinking Drinking: Alcohol & Your Health: [https://www.rethinkingdrinking.niaaa.nih.gov/](https://www.rethinkingdrinking.niaaa.nih.gov/)\n- Alcohol Use And Your Health: [https://www.cdc.gov/alcohol/fact-sheets/alcohol-use.htm](https://www.cdc.gov/alcohol/fact-sheets/alcohol-use.htm)\n'
      else if IsZoneThreeDrinker then '- Rethinking Drinking: Alcohol & Your Health: [https://www.rethinkingdrinking.niaaa.nih.gov/](https://www.rethinkingdrinking.niaaa.nih.gov/)\n- Alcohol Use And Your Health: [https://www.cdc.gov/alcohol/fact-sheets/alcohol-use.htm](https://www.cdc.gov/alcohol/fact-sheets/alcohol-use.htm)\n- Find Your Way to Alcohol Treatment (NIAAA Alcohol Treatment Navigator): [https://alcoholtreatment.niaaa.nih.gov/](https://alcoholtreatment.niaaa.nih.gov/)\n- Find Treatment for Substance Use Disorder: [https://findtreatment.gov/](https://findtreatment.gov/)\n'
      else if IsZoneFourDrinker then '- Treatment for Alcohol Problems: Finding and Getting Help: [https://www.niaaa.nih.gov/publications/brochures-and-fact-sheets/treatment-alcohol-problems-finding-and-getting-help](https://www.niaaa.nih.gov/publications/brochures-and-fact-sheets/treatment-alcohol-problems-finding-and-getting-help)\n- NIAAA Alcohol Treatment Navigator: [https://alcoholtreatment.niaaa.nih.gov/](https://alcoholtreatment.niaaa.nih.gov/)\n- Find Treatment for Substance Use Disorder: [https://findtreatment.gov/](https://findtreatment.gov/)\n'
      else ''
    )
 ) else ''

//------------------------------------------------------------------------------
// 5) NON-ALCOHOL-RELATED NIDA QS RESULTS
//------------------------------------------------------------------------------

// Did the most recent alcohol screening include the NIDA QS?
define NidaQsWasPerformed:
  if MostRecentQuestionnaireURL = 'http://www.cdc.gov/ncbddd/fasd/nidaqs2usaudit' then 
    true
  else 
    false

define RecentNidaTobaccoResponse:
  (MostRecentResponseValues) RV
  where RV.id = 'nidaqs-tobacco-question'
  return singleton from (RV.answer as FHIR.Coding)

define RecentNidaRxDrugResponse:
  (MostRecentResponseValues) RV
  where RV.id = 'nidaqs-rx-drug-question'
  return singleton from (RV.answer as FHIR.Coding)

define RecentNidaIllegalDrugResponse:
  (MostRecentResponseValues) RV
  where RV.id = 'nidaqs-illegal-drug-question'
  return singleton from (RV.answer as FHIR.Coding)

define TobaccoDidDidNot:
  if singleton from RecentNidaTobaccoResponse ~ "Never" then 
    'did not use'
  else if singleton from RecentNidaTobaccoResponse in {"Once or twice", "Monthly", "Weekly", "Daily or Almost Daily"} then
    'used'
  else ''

define RxDrugDidDidNot:
  if singleton from RecentNidaRxDrugResponse ~ "Never" then 
    'did not use'
  else if singleton from RecentNidaRxDrugResponse in {"Once or twice", "Monthly", "Weekly", "Daily or Almost Daily"} then
    'used'
  else ''

define IllegalDrugDidDidNot:
  if singleton from RecentNidaIllegalDrugResponse ~ "Never" then 
    'did not use'
  else if singleton from RecentNidaIllegalDrugResponse in {"Once or twice", "Monthly", "Weekly", "Daily or Almost Daily"} then
    'used'
  else ''

define NonAlcoholScreeningResultsTextSummary:
  if NidaQsWasPerformed then
    'The patient indicates that in the past year, they ' 
    + TobaccoDidDidNot + ' tobacco products; they '
    + RxDrugDidDidNot + ' prescription drugs for nonmedical reasons; and that they '
    + IllegalDrugDidDidNot + ' illegal drugs.'
  else ''

define NonAlcoholScreeningResultsSummary:
  Tuple {
    summary: NonAlcoholScreeningResultsTextSummary,
    responses: NonAlcoholQuestionResponsePairs
  }

//------------------------------------------------------------------------------
// 6) NON-ALCOHOL-RELATED COUNSELING SUGGESTIONS
//------------------------------------------------------------------------------

define TobaccoCounselingSuggestionText:
  if TobaccoDidDidNot = 'used' then (
    if PregnantAndNotDrinking or PregnantAndDrinking then '- If the patient is using tobacco products, consider providing them with the following information:<sup>2,3</sup>\n  * Smoking during pregnancy increases the risk of health problems for developing babies, including preterm birth, low birth weight and birth defects of the mouth and lips. Smoking during pregnancy can also increase the risk of sudden infant death syndrome.\n  * Quitting smoking is an important way to protect both your own health and the health of your baby\n- Consider providing the patient with the patient education resources listed below\n'
    else '- If the patient is using tobacco products, advise them to quit:<sup>2</sup>\n  * If the patient seems willing to quit, provide appropriate interventions to assist them.\n- Consider providing the patient with the patient education resources listed below.\n'
  )
  else ''

define TobaccoCounselingSuggestionReferences:
  if TobaccoDidDidNot = 'used' then (
    if PregnantAndNotDrinking or PregnantAndDrinking then '2. Centers for Disease Control and Prevention (CDC). Substance Use During Pregnancy | CDC. [https://www.cdc.gov/reproductivehealth/maternalinfanthealth/substance-abuse/substance-abuse-during-pregnancy.htm](https://www.cdc.gov/reproductivehealth/maternalinfanthealth/substance-abuse/substance-abuse-during-pregnancy.htm). Published 2019. Accessed March 11, 2020.\n3. The American College of Obstetricians and Gynecologists. Smoking Cessation During Pregnancy - ACOG. [https://www.acog.org/Clinical-Guidance-and-Publications/Committee-Opinions/Committee-on-Obstetric-Practice/Smoking-Cessation-During-Pregnancy?IsMobileSet=false](https://www.acog.org/Clinical-Guidance-and-Publications/Committee-Opinions/Committee-on-Obstetric-Practice/Smoking-Cessation-During-Pregnancy?IsMobileSet=false). Published 2017. Accessed March 11, 2020.\n'
    else '2. Agency for Healthcare Research and Quality. Treating Tobacco Use and Dependence. [https://www.ahrq.gov/prevention/guidelines/tobacco/clinicians/references/quickref/index.html](https://www.ahrq.gov/prevention/guidelines/tobacco/clinicians/references/quickref/index.html). Accessed March 14, 2020.\n'
  )
  else ''

define DrugCounselingReferenceNumber:
  if TobaccoDidDidNot = 'used' then '4'
  else '3'

define DrugCounselingSuggestionText:
  if RxDrugDidDidNot = 'used' or IllegalDrugDidDidNot = 'used' then (
    if PregnantAndNotDrinking or PregnantAndDrinking then '- If the patient is using illegal drugs or prescription drugs for nonmedical reasons, and agrees to discuss the screening results, consider providing the patient with the following information: <sup>2,' + DrugCounselingReferenceNumber + '</sup>\n  * Substance use, and in particular, use of opioid pain medications during pregnancy, is linked to several serious health impacts for you and your baby (e.g., preterm birth, stillbirth, maternal mortality).\n  * Marijuana use is also linked to health concerns, and should be discouraged during pregnancy.\n- Consider referring the patient for further evaluation and treatment of their substance use.\n- Consider providing the patient with the patient education resources listed below\n'
    else '- If the patient is using illegal drugs or prescription drugs for nonmedical reasons and agrees to discuss the screening results, consider doing additional screening or information gathering to determine the extent of the patient’s drug use.\n- Provide medical advice specific to the patient’s drug use.\n- Consider referring the patient for further evaluation and treatment of their substance use.\n- Consider providing the patient with the patient education resources listed below.\n'
  )
  else ''

define DrugCounselingSuggestionReferences:
  if TobaccoDidDidNot = 'used' then (
    if PregnantAndNotDrinking or PregnantAndDrinking then DrugCounselingReferenceNumber + '. The American College of Obstetricians and Gynecologists. Marijuana Use During Pregnancy and Lactation - ACOG. [https://www.acog.org/Clinical-Guidance-and-Publications/Committee-Opinions/Committee-on-Obstetric-Practice/Marijuana-Use-During-Pregnancy-and-Lactation](https://www.acog.org/Clinical-Guidance-and-Publications/Committee-Opinions/Committee-on-Obstetric-Practice/Marijuana-Use-During-Pregnancy-and-Lactation). Published 2019. Accessed March 12, 2020.\n'
    else ''
  ) else (
    if PregnantAndNotDrinking or PregnantAndDrinking then '2. Centers for Disease Control and Prevention (CDC). Substance Use During Pregnancy | CDC. [https://www.cdc.gov/reproductivehealth/maternalinfanthealth/substance-abuse/substance-abuse-during-pregnancy.htm](https://www.cdc.gov/reproductivehealth/maternalinfanthealth/substance-abuse/substance-abuse-during-pregnancy.htm). Published 2019. Accessed March 11, 2020.\n' + DrugCounselingReferenceNumber + '. The American College of Obstetricians and Gynecologists. Marijuana Use During Pregnancy and Lactation - ACOG. [https://www.acog.org/Clinical-Guidance-and-Publications/Committee-Opinions/Committee-on-Obstetric-Practice/Marijuana-Use-During-Pregnancy-and-Lactation](https://www.acog.org/Clinical-Guidance-and-Publications/Committee-Opinions/Committee-on-Obstetric-Practice/Marijuana-Use-During-Pregnancy-and-Lactation). Published 2019. Accessed March 12, 2020.\n'
    else ''
  )

define NonAlcoholRelatedCounselingSuggestionText:
  if NidaQsWasPerformed then
    'The National Institute on Drug Abuse (NIDA)<sup>1</sup> suggests the following when reviewing the results of the NIDA QS with patients:\n- Review the results of the NIDA QS with the patient.\n- Avoid any tone that could be considered judgmental or confrontational.\n- Offer additional counseling on the impact of the patient’s specific substance use and assess their readiness to quit.\n- If the patient seems responsive, offer assistance with their effort to reduce or eliminate their use of the substance(s).\n'
    + TobaccoCounselingSuggestionText
    + DrugCounselingSuggestionText
  else ''

define NonAlcoholRelatedCounselingSuggestionReferences:
  if NidaQsWasPerformed then
    '1. National Institute on Drug Abuse. The NIDA Quick Screen | National Institute on Drug Abuse (NIDA). [https://www.drugabuse.gov/publications/resource-guide-screening-drug-use-in-general-medical-settings/nida-quick-screen](https://www.drugabuse.gov/publications/resource-guide-screening-drug-use-in-general-medical-settings/nida-quick-screen). Accessed December 4, 2019.\n'
    + TobaccoCounselingSuggestionReferences
    + DrugCounselingSuggestionReferences
  else ''

define DrugTreatmentReferralSuggested:
  if RxDrugDidDidNot = 'used' or IllegalDrugDidDidNot = 'used' then true
  else false

define NonAlcoholRelatedCounselingSuggestions:
  Tuple {
    suggestions: NonAlcoholRelatedCounselingSuggestionText,
    references: NonAlcoholRelatedCounselingSuggestionReferences,
    referral: DrugTreatmentReferralSuggested
  }

//------------------------------------------------------------------------------
// 7) NON-ALCOHOL-RELATED PATIENT EDUCATION RESOURCES
//------------------------------------------------------------------------------

define TobaccoPatientEducationResources:
  if TobaccoDidDidNot = 'used' then (
    if PregnantAndNotDrinking or PregnantAndDrinking then '- MotherToBaby Fact Sheet about exposure to cigarette smoke in pregnancy and while breastfeeding: [https://mothertobaby.org/fact-sheets/cigarette-smoking-pregnancy/pdf/](https://mothertobaby.org/fact-sheets/cigarette-smoking-pregnancy/pdf/)\n- March of Dimes: Smoking During Pregnancy: [https://www.marchofdimes.org/pregnancy/smoking-during-pregnancy.aspx](https://www.marchofdimes.org/pregnancy/smoking-during-pregnancy.aspx)\n- Smoking, Pregnancy, and Babies: [https://www.cdc.gov/tobacco/campaign/tips/diseases/pregnancy.html](https://www.cdc.gov/tobacco/campaign/tips/diseases/pregnancy.html)\n'
    else '- Planning and support to help quit smoking: [https://smokefree.gov/quit-smoking](https://smokefree.gov/quit-smoking)\n- Information and tools to “Quit Smoking”: [https://www.cdc.gov/tobacco/quit_smoking/index.htm](https://www.cdc.gov/tobacco/quit_smoking/index.htm)\n'
  )
  else ''

define DrugPatientEducationResources:
  if RxDrugDidDidNot = 'used' or IllegalDrugDidDidNot = 'used' then (
    if PregnantAndNotDrinking or PregnantAndDrinking then '- CDC: Opioid Use During Pregnancy: [https://www.cdc.gov/pregnancy/opioids/index.html](https://www.cdc.gov/pregnancy/opioids/index.html)\n- CDC: What You Need to Know About Marijuana Use and Pregnancy: [https://www.cdc.gov/marijuana/factsheets/pregnancy.htm](https://www.cdc.gov/marijuana/factsheets/pregnancy.htm)\n- Step by Step Guide to Finding Treatment for Drug Use Disorders: [https://www.drugabuse.gov/publications/step-by-step-guides-to-finding-treatment-drug-use-disorders/if-you-have-problem-drugs-adults](https://www.drugabuse.gov/publications/step-by-step-guides-to-finding-treatment-drug-use-disorders/if-you-have-problem-drugs-adults)\n'
    else '- Step by Step Guide to Finding Treatment for Drug Use Disorders: [https://www.drugabuse.gov/publications/step-by-step-guides-to-finding-treatment-drug-use-disorders/if-you-have-problem-drugs-adults](https://www.drugabuse.gov/publications/step-by-step-guides-to-finding-treatment-drug-use-disorders/if-you-have-problem-drugs-adults)\n- Helpful Materials for Patients Living With Chronic Pain: [https://www.cdc.gov/drugoverdose/patients/materials.html](https://www.cdc.gov/drugoverdose/patients/materials.html)\n- Find Treatment for Substance Use Disorder: [https://findtreatment.gov/](https://findtreatment.gov/)\n'
  )
  else ''

define NonAlcoholRelatedPatientEducationResources:
  TobaccoPatientEducationResources + DrugPatientEducationResources

define BriefInterventions:
  Tuple {
    alcohol_screening_results_summary: AlcoholScreeningResultsSummary,
    alcohol_counseling_suggestions: AlcoholCounselingSuggestions,
    alcohol_patient_education_resources: AlcoholPatientEducationResources,
    non_alcohol_screening_results_summary: NonAlcoholScreeningResultsSummary,
    non_alcohol_related_counseling_suggestions: NonAlcoholRelatedCounselingSuggestions,
    non_alcohol_related_patient_education_resources: NonAlcoholRelatedPatientEducationResources
  }