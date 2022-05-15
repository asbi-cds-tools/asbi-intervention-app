/*  Library: Alcohol Screening and Brief Intervention (ASBI) Clinical Decision Support (CDS): Brief Intervention and Referral Logic Library
    Author: CMS Alliance to Modernize Healthcare, operated by THE MITRE Corporation.

    (C) 2022 The MITRE Corporation. All Rights Reserved. Approved for Public Release: 20-0458. 
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
library BriefInterventionAndReferralLogicLibrary version '2.0.0'
/* Change Log
- Version 1.1.0: Moving from FHIR 4.0.0 to 4.0.1 and CQL 1.4 to 1.5.
- Version 2.0.0: Updates based upon clinical pilot with WHO AUDIT.
*/

using FHIR version '4.0.1'

include "FHIRHelpers" version '4.0.1' called FHIRHelpers

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
code "Sex assigned at birth": '76689-9' from "LOINC" display 'Sex assigned at birth'

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
  
define SexAtBirthObservation:
  [Observation: "Sex assigned at birth"] S
    where S.status.value in {'final', 'corrected', 'amended'}

define SexAtBirth:
  if SexAtBirthExtension is not null then
    SexAtBirthExtension.value.value
  else if SexAtBirthObservation is not null then
    Coalesce(SexAtBirthObservation.value.coding).code.value
  else "Unknown value code".code

define MaleAtBirth:
  SexAtBirth = "Male administrative gender code".code

define FemaleAtBirth:
  SexAtBirth = "Female administrative gender code".code

define SexAtBirthUnknown:
  SexAtBirth = "Unknown value code".code or
  (
    MaleAtBirth = false and
    FemaleAtBirth = false
  )

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

//------------------------------------------------------------------------------
// NOTIFICATION
//------------------------------------------------------------------------------

define DisplayNotification:
  IsIncluded and not Excluded

define NotificationText:
  if DisplayNotification then 'New screening results are available!'
  else ''

//------------------------------------------------------------------------------
// DETERMINE DRINKING ZONE
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
  if HasRecentScoreFullUsAudit then RecentScoreFullUsAudit
  else if HasRecentScoreUsAuditC then RecentScoreUsAuditC
  else if HasRecentScoreFullAudit then RecentScoreFullAudit
  else if HasRecentScoreAuditC then RecentScoreAuditC
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

//------------------------------------------------------------------------------
// EXTRACT RESPONSES FROM QUESTIONS #1 - #3
//------------------------------------------------------------------------------

define RespondedToQuestionOne:
  Exists(RecentUsauditQuestionOneResponses)
   or Exists(RecentAuditQuestionOneResponses)

define QuestionOneResponse:
  if RespondedToQuestionOne then (
    if AuditVariant = 'USAUDIT' then (singleton from RecentUsauditQuestionOneResponses).display.value
    else if AuditVariant = 'AUDIT' then (singleton from RecentAuditQuestionOneResponses).display.value
    else null
  ) else null

// Recent response to the USAUDIT Question 2
define RecentUsauditQuestionTwoResponses:
  (MostRecentResponseValues) RV
  where RV.id = 'usaudit-question-two'
  return RV.answer.display.value

// Recent response to the AUDIT Question 2
define RecentAuditQuestionTwoResponses:
  (MostRecentResponseValues) RV
  where RV.id = 'audit-question-two'
  return RV.answer.display.value

define RespondedToQuestionTwo:
  Exists(RecentUsauditQuestionTwoResponses)
   or Exists(RecentAuditQuestionTwoResponses)

define QuestionTwoResponse:
  if RespondedToQuestionTwo then (
    if AuditVariant = 'USAUDIT' then singleton from RecentUsauditQuestionTwoResponses
    else if AuditVariant = 'AUDIT' then singleton from RecentAuditQuestionTwoResponses
    else null
  ) else null

// Recent response to the USAUDIT Question 3
define RecentUsauditQuestionThreeResponses:
  (MostRecentResponseValues) RV
  where RV.id = 'usaudit-question-three'
  return RV.answer.display.value

// Recent response to the AUDIT Question 3
define RecentAuditQuestionThreeResponses:
  (MostRecentResponseValues) RV
  where RV.id = 'audit-question-three'
  return RV.answer.display.value

define RespondedToQuestionThree:
  Exists(RecentUsauditQuestionThreeResponses)
   or Exists(RecentAuditQuestionThreeResponses)

define QuestionThreeResponse:
  if RespondedToQuestionThree then (
    if AuditVariant = 'USAUDIT' then singleton from RecentUsauditQuestionThreeResponses
    else if AuditVariant = 'AUDIT' then singleton from RecentAuditQuestionThreeResponses
    else null
  ) else null

define PregnantAndDrinking:
  DoesMeetPregnancyInclusionCriteria 
  and not (
    HasRecentNoApsResponse
    or (HasRecentYesApsResponse 
      and (HasRecentNeverResponseUsauditQuestionOne
        or HasRecentNeverResponseAuditQuestionOne))
  )

define PregnantAndNotDrinking:
  DoesMeetPregnancyInclusionCriteria and not PregnantAndDrinking

//------------------------------------------------------------------------------
// EXTRACT RESPONSES FROM QUESTIONS #4 - #6
//------------------------------------------------------------------------------

// Recent response to the USAUDIT Question 4
define RecentUsauditQuestionFourResponses:
  (MostRecentResponseValues) RV
  where RV.id = 'usaudit-question-four'
  return RV.answer.display.value

// Recent response to the AUDIT Question 4
define RecentAuditQuestionFourResponses:
  (MostRecentResponseValues) RV
  where RV.id = 'audit-question-four'
  return RV.answer.display.value

define RespondedToQuestionFour:
  Exists(RecentUsauditQuestionFourResponses)
   or Exists(RecentAuditQuestionFourResponses)

define QuestionFourResponse:
  if RespondedToQuestionFour then (
    if AuditVariant = 'USAUDIT' then singleton from RecentUsauditQuestionFourResponses
    else if AuditVariant = 'AUDIT' then singleton from RecentAuditQuestionFourResponses
    else null
  ) else null

// Recent response to the USAUDIT Question 5
define RecentUsauditQuestionFiveResponses:
  (MostRecentResponseValues) RV
  where RV.id = 'usaudit-question-five'
  return RV.answer.display.value

// Recent response to the AUDIT Question 5
define RecentAuditQuestionFiveResponses:
  (MostRecentResponseValues) RV
  where RV.id = 'audit-question-five'
  return RV.answer.display.value

define RespondedToQuestionFive:
  Exists(RecentUsauditQuestionFiveResponses)
   or Exists(RecentAuditQuestionFiveResponses)

define QuestionFiveResponse:
  if RespondedToQuestionFive then (
    if AuditVariant = 'USAUDIT' then singleton from RecentUsauditQuestionFiveResponses
    else if AuditVariant = 'AUDIT' then singleton from RecentAuditQuestionFiveResponses
    else null
  ) else null

// Recent response to the USAUDIT Question 6
define RecentUsauditQuestionSixResponses:
  (MostRecentResponseValues) RV
  where RV.id = 'usaudit-question-six'
  return RV.answer.display.value

// Recent response to the AUDIT Question 6
define RecentAuditQuestionSixResponses:
  (MostRecentResponseValues) RV
  where RV.id = 'audit-question-six'
  return RV.answer.display.value

define RespondedToQuestionSix:
  Exists(RecentUsauditQuestionSixResponses)
   or Exists(RecentAuditQuestionSixResponses)

define QuestionSixResponse:
  if RespondedToQuestionSix then (
    if AuditVariant = 'USAUDIT' then singleton from RecentUsauditQuestionSixResponses
    else if AuditVariant = 'AUDIT' then singleton from RecentAuditQuestionSixResponses
    else null
  ) else null

//------------------------------------------------------------------------------
// EXTRACT RESPONSES FROM QUESTIONS #7 - #8
//------------------------------------------------------------------------------

// Recent response to the USAUDIT Question 7
define RecentUsauditQuestionSevenResponses:
  (MostRecentResponseValues) RV
  where RV.id = 'usaudit-question-seven'
  return RV.answer.display.value

// Recent response to the AUDIT Question 7
define RecentAuditQuestionSevenResponses:
  (MostRecentResponseValues) RV
  where RV.id = 'audit-question-seven'
  return RV.answer.display.value

define RespondedToQuestionSeven:
  Exists(RecentUsauditQuestionSevenResponses)
   or Exists(RecentAuditQuestionSevenResponses)

define QuestionSevenResponse:
  if RespondedToQuestionSeven then (
    if AuditVariant = 'USAUDIT' then singleton from RecentUsauditQuestionSevenResponses
    else if AuditVariant = 'AUDIT' then singleton from RecentAuditQuestionSevenResponses
    else null
  ) else null

// Recent response to the USAUDIT Question 8
define RecentUsauditQuestionEightResponses:
  (MostRecentResponseValues) RV
  where RV.id = 'usaudit-question-eight'
  return RV.answer.display.value

// Recent response to the AUDIT Question 8
define RecentAuditQuestionEightResponses:
  (MostRecentResponseValues) RV
  where RV.id = 'audit-question-eight'
  return RV.answer.display.value

define RespondedToQuestionEight:
  Exists(RecentUsauditQuestionEightResponses)
   or Exists(RecentAuditQuestionEightResponses)

define QuestionEightResponse:
  if RespondedToQuestionEight then (
    if AuditVariant = 'USAUDIT' then singleton from RecentUsauditQuestionEightResponses
    else if AuditVariant = 'AUDIT' then singleton from RecentAuditQuestionEightResponses
    else null
  ) else null

//------------------------------------------------------------------------------
// EXTRACT RESPONSES FROM QUESTIONS #9 - #10
//------------------------------------------------------------------------------

// Recent response to the USAUDIT Question 9
define RecentUsauditQuestionNineResponses:
  (MostRecentResponseValues) RV
  where RV.id = 'usaudit-question-nine'
  return RV.answer.display.value

// Recent response to the AUDIT Question 9
define RecentAuditQuestionNineResponses:
  (MostRecentResponseValues) RV
  where RV.id = 'audit-question-nine'
  return RV.answer.display.value

define RespondedToQuestionNine:
  Exists(RecentUsauditQuestionNineResponses)
   or Exists(RecentAuditQuestionNineResponses)

define QuestionNineResponse:
  if RespondedToQuestionNine then (
    if AuditVariant = 'USAUDIT' then singleton from RecentUsauditQuestionNineResponses
    else if AuditVariant = 'AUDIT' then singleton from RecentAuditQuestionNineResponses
    else null
  ) else null

// Recent response to the USAUDIT Question 10
define RecentUsauditQuestionTenResponses:
  (MostRecentResponseValues) RV
  where RV.id = 'usaudit-question-ten'
  return RV.answer.display.value

// Recent response to the AUDIT Question 10
define RecentAuditQuestionTenResponses:
  (MostRecentResponseValues) RV
  where RV.id = 'audit-question-ten'
  return RV.answer.display.value

define RespondedToQuestionTen:
  Exists(RecentUsauditQuestionTenResponses)
   or Exists(RecentAuditQuestionTenResponses)

define QuestionTenResponse:
  if RespondedToQuestionTen then (
    if AuditVariant = 'USAUDIT' then singleton from RecentUsauditQuestionTenResponses
    else if AuditVariant = 'AUDIT' then singleton from RecentAuditQuestionTenResponses
    else null
  ) else null

//------------------------------------------------------------------------------
// DECISION AIDS
//------------------------------------------------------------------------------


// 0. General Guidance to Clinician
define GeneralGuidanceTitle:
  case
    when PregnantAndNotDrinking then 'Guidance for Pregnant Patients Not Drinking Alcohol'
    when PregnantAndDrinking then 'Guidance for Pregnant Patients that Drink Alcohol'
    when IsZoneOneDrinker then 'Guidance for Low-Risk Drinking (Zone I)'
    when IsZoneTwoDrinker then 'Guidance for Risky Drinking (Zone II)'
    when IsZoneThreeDrinker then 'Guidance for Harmful or Hazardous Drinking (Zone III)'
    when IsZoneFourDrinker then 'Guidance for Severe Drinking Levels (Zone IV)'
    else ''
  end

define GeneralGuidanceText:
  case
    when PregnantAndNotDrinking then 'For patients that are pregnant or trying to become pregnant whose screening response indicates they are not currently drinking alcohol, brief counseling interventions increase the likelihood that they will remain abstinent during pregnancy.  ACOG and several other organizations suggest the following talking points.'
    when PregnantAndDrinking then 'For patients that are pregnant or trying to become pregnant whose screening responses indicate they are currently drinking alcohol, ANY alcohol use is considered excessive. ACOG and several other organizations suggest the following talking points.'
    when IsZoneOneDrinker then 'For patients in Zone I, brief counseling can serve to reinforce low risk drinking, and could be effective if the patient underreported their drinking when responding to the screening questions, or might have had past problems with risky drinking.'
    when IsZoneTwoDrinker then 'For patients in Zone II, a brief intervention using simple advice on the reduction of drinking, engaging the patient in reflective motivational conversations, and providing patient education materials may be the most appropriate course of action.'
    when IsZoneThreeDrinker then 'For patients in Zone III,  a combination of feedback, brief counseling, and continued monitoring may be effective, with further diagnostic evaluation indicated if the patient fails to respond or is suspected of alcohol dependence.'
    when IsZoneFourDrinker then 'Patients in Zone IV, which suggests alcohol dependence, should be referred to a specialist for diagnostic evaluation and possible treatment.'
    else ''
  end

define AdditionalGuidanceOnBriefInterventionElements:
  '**Additional Guidance on Brief Intervention Elements:**\n'
    + '- Raise the subject\n'
    + '- Provide feedback about screening results\n'
    + '- Ask patients what they like and what they don’t like about their drinking (in that order)\n'
    + '- Ask if they would like your medical advice\n'
    + '- Listen for "change talk" to assess how ready the patient is to modify his or her behavior\n'
    + '- Provide options the patient can choose from to develop a plan\n'
    + '- Seek agreement for a follow‐up visit\n'
    + '- Thank patient\n'
    + '\n'
    + 'Reference:\n'
    + 'Centers for Disease Control and Prevention. (2014). Planning and Implementing Screening and Brief Intervention for Risky Alcohol Use: A Step-by-Step Guide for Primary Care Practices. Centers for Disease Control and Prevention, National Center on Birth Defects and Developmental Disabilities. Retrieved from https://www.cdc.gov/ncbddd/fasd/documents/AlcoholSBIImplementationGuide-P.pdf'

define GeneralGuidance:
  Tuple{
    title: GeneralGuidanceTitle,
    text: GeneralGuidanceText,
    additional: AdditionalGuidanceOnBriefInterventionElements
  }

// 1. Provide Feedback on Screening Results

define ProvideFeedbackInstructionsTitle:
  'Provide feedback on screening results'

define ProvideFeedbackInstructionsText:
  'Provide feedback to the patient on their screening results'

define ProvideFeedbackPatientTextPart1:
  case
    when PregnantAndNotDrinking then 'Your alcohol screening results indicate that you are not drinking alcohol. That\'s a great decision.\n\nNot drinking is important for your health and the health of your baby.'
    when PregnantAndDrinking then 'Your screening responses indicate you are drinking alcohol. Any alcohol use is considered excessive if you are pregnant or trying to become pregnant.'
    when IsZoneOneDrinker then 'Your screening responses and total score indicate that you do not drink alcohol, or drink in moderation.'
    when IsZoneTwoDrinker then 'Your screening responses and total score indicate that you are drinking above low-risk guidelines.'
    when IsZoneThreeDrinker then 'Your screening responses and total score indicate that you are drinking at harmful levels.'
    when IsZoneFourDrinker then 'Your screening responses and total score indicate that your drinking is at high-risk drinking levels.'
    else ''
  end

define YourZoneDescription:
  if IsZoneOneDrinker then 'low-risk drinking'
  else if IsZoneTwoDrinker then 'drinking in excess of the guidelines'
  else if IsZoneThreeDrinker then 'harmful or hazardous drinking'
  else if IsZoneFourDrinker then 'high-risk drinking'
  else ''

define PregnantAndDrinkingClause:
  if PregnantAndDrinking then 'for people that aren\'t pregnant '
  else ''

define ProvideFeedbackPatientTextPart2:
  if PregnantAndNotDrinking then
    ''
  else
    'Your screening score is **'
      + ToString(MostRecentScreeningScore as System.Integer)
      + '** (out of 40), and falls within **Zone '
      + ZoneRomanNumeral
      + '**, which ' + PregnantAndDrinkingClause + 'indicates **'
      + YourZoneDescription + '**.\n'

define DrinkingPyramidZoneI:
  '<svg width=\"1255px\" height=\"577px\" viewBox=\"0 0 1255 577\" version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\"><title>Zone I Arrow</title><g id=\"Zone-I-Arrow\" stroke=\"none\" stroke-width=\"1\" fill=\"none\" fill-rule=\"evenodd\"><rect fill=\"#FFFFFF\" x=\"0\" y=\"0\" width=\"1255\" height=\"577\"></rect><g id=\"Group-6\" transform=\"translate(4.000000, 20.000000)\"><g id=\"Triangle-2\" transform=\"translate(549.000000, 29.000000)\" fill=\"#D8D8D8\" stroke=\"#979797\"><path d=\"M300.5,0.969210829 L600.115235,498.5 L0.884765239,498.5 L300.5,0.969210829 Z\" id=\"Triangle\"></path><path d=\"M300.5,0.969210829 L600.115235,498.5 L0.884765239,498.5 L300.5,0.969210829 Z\" id=\"Triangle\"></path></g><path d=\"M849.5,28.9940559 L884.130508,88.5 L814.869492,88.5 L849.5,28.9940559 Z\" id=\"Triangle\" stroke=\"#000000\" fill-opacity=\"0.574287041\" fill=\"#E32525\"></path><rect id=\"Rectangle\" fill-opacity=\"0.153549941\" fill=\"#138E34\" x=\"189\" y=\"196\" width=\"1042\" height=\"344\"></rect><rect id=\"Rectangle\" fill-opacity=\"0.347697225\" fill=\"#F6EF54\" x=\"189\" y=\"142\" width=\"1042\" height=\"49\"></rect><rect id=\"Rectangle\" fill-opacity=\"0.265983528\" fill=\"#F94101\" x=\"189\" y=\"91\" width=\"1042\" height=\"45\"></rect><rect id=\"Rectangle\" fill-opacity=\"0.249839516\" fill=\"#E90404\" x=\"189\" y=\"0\" width=\"1042\" height=\"85\"></rect><path d=\"M882.966179,88.5 L916.024519,137.5 L782.973481,137.5 L816.031821,88.5 L882.966179,88.5 Z\" id=\"Combined-Shape\" stroke=\"#000000\" fill-opacity=\"0.63352102\" fill=\"#F5825B\"></path><path d=\"M915.394304,137.5 L944.58887,189.5 L755.40913,189.5 L784.603696,137.5 L915.394304,137.5 Z\" id=\"Combined-Shape\" stroke=\"#000000\" fill-opacity=\"0.65942895\" fill=\"#F6EF54\"></path><path d=\"M943.218955,189.5 L1151.10409,526.5 L545.895914,526.5 L753.781045,189.5 L943.218955,189.5 Z\" id=\"Combined-Shape\" stroke=\"#000000\" fill-opacity=\"0.467474664\" fill=\"#138E34\"></path><text id=\"Harmful\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"639.491211\" y=\"124\">Harmful</tspan></text><g id=\"Group\" transform=\"translate(448.000000, 26.000000)\" fill=\"#000000\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\"><text id=\"Severe\"><tspan x=\"189.467773\" y=\"35\">Severe</tspan></text><text id=\"Zone-IV\"><tspan x=\"0.46484375\" y=\"35\">Zone IV</tspan></text></g><text id=\"78-%\" font-family=\"Helvetica\" font-size=\"28\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"855.5\" y=\"203\"></tspan><tspan x=\"826.701904\" y=\"237\">78 </tspan><tspan x=\"865.625732\" y=\"237\" font-size=\"21\">%</tspan></text><text id=\"9-%\" font-family=\"Helvetica\" font-size=\"28\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"856\" y=\"141\"></tspan><tspan x=\"834.988037\" y=\"175\">9 </tspan><tspan x=\"858.3396\" y=\"175\" font-size=\"21\">%</tspan></text><text id=\"8-%\" font-family=\"Helvetica\" font-size=\"30\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"855\" y=\"91\"></tspan><tspan x=\"833.154053\" y=\"127\">8 </tspan><tspan x=\"858.173584\" y=\"127\" font-size=\"21\">%</tspan></text><text id=\"5%\" font-family=\"Helvetica\" font-size=\"28\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"853\" y=\"47\"></tspan><tspan x=\"835.877686\" y=\"81\">5</tspan><tspan x=\"851.449951\" y=\"81\" font-size=\"21\">%</tspan></text><text id=\"Zone-II\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"449.969727\" y=\"180\">Zone II </tspan></text><text id=\"Zone-III\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"448.46875\" y=\"124\">Zone III</tspan></text><text id=\"Zone-I\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"799.970703\" y=\"296\">Zone I </tspan></text><path d=\"M850.5,29.8563693 L1151.44768,526 L549.55232,526 L850.5,29.8563693 Z\" id=\"Triangle\" stroke=\"#000000\" stroke-width=\"4\"></path><g id=\"Group-5\" transform=\"translate(905.000000, 5.000000)\" fill=\"#000000\" font-family=\"Helvetica\" font-weight=\"normal\"><g id=\"Group-4\"><text id=\"AUDIT-score\" font-size=\"21\"><tspan x=\"58.0915527\" y=\"20\">AUDIT score</tspan></text><g id=\"Group-3\" transform=\"translate(127.000000, 28.000000)\" font-size=\"18\"><text id=\"Male-&lt;=65\"><tspan x=\"0.469726562\" y=\"40\">Male &lt;=65</tspan></text><text id=\"Female-or-Male-&gt;-65\"><tspan x=\"0.211425781\" y=\"18\">Female or Male &gt; 65</tspan></text></g><text id=\"16-19\" font-size=\"18\"><tspan x=\"66.9814453\" y=\"108\">16-19</tspan></text><text id=\"16-19\" font-size=\"18\"><tspan x=\"66.9814453\" y=\"129\">16-19</tspan></text><text id=\"20+\" font-size=\"18\"><tspan x=\"81.7333984\" y=\"42\">20+</tspan></text><text id=\"20+\" font-size=\"18\"><tspan x=\"81.7333984\" y=\"66\">20+</tspan></text><text id=\"8-15\" font-size=\"18\"><tspan x=\"75.9868164\" y=\"181\">8-15</tspan></text><text id=\"7-15\" font-size=\"18\"><tspan x=\"75.9868164\" y=\"158\">7-15</tspan></text><text id=\"0-7\" font-size=\"18\"><tspan x=\"90.9921875\" y=\"246\">0-7</tspan></text><text id=\"0-6\" font-size=\"18\"><tspan x=\"90.9921875\" y=\"223\">0-6</tspan></text><g id=\"Group-3\" transform=\"translate(127.000000, 141.000000)\" font-size=\"18\"><text id=\"Male-&lt;=65\"><tspan x=\"0.469726562\" y=\"40\">Male &lt;=65</tspan></text><text id=\"Female-or-Male-&gt;-65\"><tspan x=\"0.211425781\" y=\"18\">Female or Male &gt; 65</tspan></text></g></g><g id=\"Group-3\" transform=\"translate(127.000000, 87.000000)\" font-size=\"18\"><text id=\"Male-&lt;=65\"><tspan x=\"0.469726562\" y=\"40\">Male &lt;=65</tspan></text><text id=\"Female-or-Male-&gt;-65\"><tspan x=\"0.211425781\" y=\"18\">Female or Male &gt; 65</tspan></text></g><g id=\"Group-3\" transform=\"translate(127.000000, 206.000000)\" font-size=\"18\"><text id=\"Male-&lt;=65\"><tspan x=\"0.469726562\" y=\"40\">Male &lt;=65</tspan></text><text id=\"Female-or-Male-&gt;-65\"><tspan x=\"0.211425781\" y=\"18\">Female or Male &gt; 65</tspan></text></g></g><text id=\"Low-Risk-or-Abstain\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"781.980469\" y=\"360\">Low Risk </tspan><tspan x=\"774.94043\" y=\"403\">or Abstain</tspan></text><text id=\"Risky\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"641.001953\" y=\"178\">Risky</tspan></text><g id=\"Your-Drinking\" transform=\"translate(0.000000, 272.000000)\" fill=\"#000000\"><path id=\"Line-2\" d=\"M360.75958,21.986962 L414.5,49.5 L360.245318,75.9845132 L360.454,53.985 L151.952383,51.9997733 L146.95261,51.9521564 L147.047844,41.9526099 L152.047617,42.0002267 L360.55,43.986 L360.75958,21.986962 Z\" fill-rule=\"nonzero\"></path><text id=\"Your-drinking\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\"><tspan x=\"44.1308594\" y=\"35\">Your </tspan><tspan x=\"17.4648438\" y=\"78\">drinking</tspan></text></g></g></g></svg>'

define DrinkingPyramidZoneII:
  '<svg width=\"1255px\" height=\"577px\" viewBox=\"0 0 1255 577\" version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\"><title>Zone II Arrow</title><g id=\"Zone-II-Arrow\" stroke=\"none\" stroke-width=\"1\" fill=\"none\" fill-rule=\"evenodd\"><rect fill=\"#FFFFFF\" x=\"0\" y=\"0\" width=\"1255\" height=\"577\"></rect><g id=\"Group-6\" transform=\"translate(0.000000, 20.000000)\"><g id=\"Triangle-2\" transform=\"translate(552.000000, 29.000000)\" fill=\"#D8D8D8\" stroke=\"#979797\"><path d=\"M300.5,0.969210829 L600.115235,498.5 L0.884765239,498.5 L300.5,0.969210829 Z\" id=\"Triangle\"></path><path d=\"M300.5,0.969210829 L600.115235,498.5 L0.884765239,498.5 L300.5,0.969210829 Z\" id=\"Triangle\"></path></g><path d=\"M852.5,28.9940559 L887.130508,88.5 L817.869492,88.5 L852.5,28.9940559 Z\" id=\"Triangle\" stroke=\"#000000\" fill-opacity=\"0.574287041\" fill=\"#E32525\"></path><rect id=\"Rectangle\" fill-opacity=\"0.153549941\" fill=\"#138E34\" x=\"192\" y=\"196\" width=\"1042\" height=\"344\"></rect><rect id=\"Rectangle\" fill-opacity=\"0.347697225\" fill=\"#F6EF54\" x=\"192\" y=\"142\" width=\"1042\" height=\"49\"></rect><rect id=\"Rectangle\" fill-opacity=\"0.265983528\" fill=\"#F94101\" x=\"192\" y=\"91\" width=\"1042\" height=\"45\"></rect><rect id=\"Rectangle\" fill-opacity=\"0.249839516\" fill=\"#E90404\" x=\"192\" y=\"0\" width=\"1042\" height=\"85\"></rect><path d=\"M885.966179,88.5 L919.024519,137.5 L785.973481,137.5 L819.031821,88.5 L885.966179,88.5 Z\" id=\"Combined-Shape\" stroke=\"#000000\" fill-opacity=\"0.63352102\" fill=\"#F5825B\"></path><path d=\"M918.394304,137.5 L947.58887,189.5 L758.40913,189.5 L787.603696,137.5 L918.394304,137.5 Z\" id=\"Combined-Shape\" stroke=\"#000000\" fill-opacity=\"0.65942895\" fill=\"#F6EF54\"></path><path d=\"M946.218955,189.5 L1154.10409,526.5 L548.895914,526.5 L756.781045,189.5 L946.218955,189.5 Z\" id=\"Combined-Shape\" stroke=\"#000000\" fill-opacity=\"0.467474664\" fill=\"#138E34\"></path><text id=\"Harmful\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"642.491211\" y=\"124\">Harmful</tspan></text><g id=\"Group\" transform=\"translate(451.000000, 26.000000)\" fill=\"#000000\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\"><text id=\"Severe\"><tspan x=\"189.467773\" y=\"35\">Severe</tspan></text><text id=\"Zone-IV\"><tspan x=\"0.46484375\" y=\"35\">Zone IV</tspan></text></g><text id=\"78-%\" font-family=\"Helvetica\" font-size=\"28\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"858.5\" y=\"203\"></tspan><tspan x=\"829.701904\" y=\"237\">78 </tspan><tspan x=\"868.625732\" y=\"237\" font-size=\"21\">%</tspan></text><text id=\"9-%\" font-family=\"Helvetica\" font-size=\"28\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"859\" y=\"141\"></tspan><tspan x=\"837.988037\" y=\"175\">9 </tspan><tspan x=\"861.3396\" y=\"175\" font-size=\"21\">%</tspan></text><text id=\"8-%\" font-family=\"Helvetica\" font-size=\"30\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"858\" y=\"91\"></tspan><tspan x=\"836.154053\" y=\"127\">8 </tspan><tspan x=\"861.173584\" y=\"127\" font-size=\"21\">%</tspan></text><text id=\"5%\" font-family=\"Helvetica\" font-size=\"28\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"856\" y=\"47\"></tspan><tspan x=\"838.877686\" y=\"81\">5</tspan><tspan x=\"854.449951\" y=\"81\" font-size=\"21\">%</tspan></text><text id=\"Zone-II\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"452.969727\" y=\"180\">Zone II </tspan></text><text id=\"Zone-III\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"451.46875\" y=\"124\">Zone III</tspan></text><text id=\"Zone-I\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"802.970703\" y=\"296\">Zone I </tspan></text><path d=\"M853.5,29.8563693 L1154.44768,526 L552.55232,526 L853.5,29.8563693 Z\" id=\"Triangle\" stroke=\"#000000\" stroke-width=\"4\"></path><g id=\"Group-5\" transform=\"translate(908.000000, 5.000000)\" fill=\"#000000\" font-family=\"Helvetica\" font-weight=\"normal\"><g id=\"Group-4\"><text id=\"AUDIT-score\" font-size=\"21\"><tspan x=\"58.0915527\" y=\"20\">AUDIT score</tspan></text><g id=\"Group-3\" transform=\"translate(127.000000, 28.000000)\" font-size=\"18\"><text id=\"Male-&lt;=65\"><tspan x=\"0.469726562\" y=\"40\">Male &lt;=65</tspan></text><text id=\"Female-or-Male-&gt;-65\"><tspan x=\"0.211425781\" y=\"18\">Female or Male &gt; 65</tspan></text></g><text id=\"16-19\" font-size=\"18\"><tspan x=\"66.9814453\" y=\"108\">16-19</tspan></text><text id=\"16-19\" font-size=\"18\"><tspan x=\"66.9814453\" y=\"129\">16-19</tspan></text><text id=\"20+\" font-size=\"18\"><tspan x=\"81.7333984\" y=\"42\">20+</tspan></text><text id=\"20+\" font-size=\"18\"><tspan x=\"81.7333984\" y=\"66\">20+</tspan></text><text id=\"8-15\" font-size=\"18\"><tspan x=\"75.9868164\" y=\"181\">8-15</tspan></text><text id=\"7-15\" font-size=\"18\"><tspan x=\"75.9868164\" y=\"158\">7-15</tspan></text><text id=\"0-7\" font-size=\"18\"><tspan x=\"90.9921875\" y=\"246\">0-7</tspan></text><text id=\"0-6\" font-size=\"18\"><tspan x=\"90.9921875\" y=\"223\">0-6</tspan></text><g id=\"Group-3\" transform=\"translate(127.000000, 141.000000)\" font-size=\"18\"><text id=\"Male-&lt;=65\"><tspan x=\"0.469726562\" y=\"40\">Male &lt;=65</tspan></text><text id=\"Female-or-Male-&gt;-65\"><tspan x=\"0.211425781\" y=\"18\">Female or Male &gt; 65</tspan></text></g></g><g id=\"Group-3\" transform=\"translate(127.000000, 87.000000)\" font-size=\"18\"><text id=\"Male-&lt;=65\"><tspan x=\"0.469726562\" y=\"40\">Male &lt;=65</tspan></text><text id=\"Female-or-Male-&gt;-65\"><tspan x=\"0.211425781\" y=\"18\">Female or Male &gt; 65</tspan></text></g><g id=\"Group-3\" transform=\"translate(127.000000, 206.000000)\" font-size=\"18\"><text id=\"Male-&lt;=65\"><tspan x=\"0.469726562\" y=\"40\">Male &lt;=65</tspan></text><text id=\"Female-or-Male-&gt;-65\"><tspan x=\"0.211425781\" y=\"18\">Female or Male &gt; 65</tspan></text></g></g><text id=\"Low-Risk-or-Abstain\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"784.980469\" y=\"360\">Low Risk </tspan><tspan x=\"777.94043\" y=\"403\">or Abstain</tspan></text><text id=\"Risky\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"644.001953\" y=\"178\">Risky</tspan></text><g id=\"Your-Drinking\" transform=\"translate(0.000000, 123.000000)\" fill=\"#000000\"><path id=\"Line-2\" d=\"M361.75958,21.986962 L415.5,49.5 L361.245318,75.9845132 L361.454,53.985 L152.952383,51.9997733 L147.95261,51.9521564 L148.047844,41.9526099 L153.047617,42.0002267 L361.55,43.986 L361.75958,21.986962 Z\" fill-rule=\"nonzero\"></path><text id=\"Your-drinking\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\"><tspan x=\"44.1308594\" y=\"35\">Your </tspan><tspan x=\"17.4648438\" y=\"78\">drinking</tspan></text></g></g></g></svg>'

define DrinkingPyramidZoneIII:
  '<svg width=\"1255px\" height=\"577px\" viewBox=\"0 0 1255 577\" version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\"><title>Zone III Arrow</title><g id=\"Zone-III-Arrow\" stroke=\"none\" stroke-width=\"1\" fill=\"none\" fill-rule=\"evenodd\"><rect fill=\"#FFFFFF\" x=\"0\" y=\"0\" width=\"1255\" height=\"577\"></rect><g id=\"Group-6\" transform=\"translate(2.000000, 20.000000)\"><g id=\"Triangle-2\" transform=\"translate(551.000000, 29.000000)\" fill=\"#D8D8D8\" stroke=\"#979797\"><path d=\"M300.5,0.969210829 L600.115235,498.5 L0.884765239,498.5 L300.5,0.969210829 Z\" id=\"Triangle\"></path><path d=\"M300.5,0.969210829 L600.115235,498.5 L0.884765239,498.5 L300.5,0.969210829 Z\" id=\"Triangle\"></path></g><path d=\"M851.5,28.9940559 L886.130508,88.5 L816.869492,88.5 L851.5,28.9940559 Z\" id=\"Triangle\" stroke=\"#000000\" fill-opacity=\"0.574287041\" fill=\"#E32525\"></path><rect id=\"Rectangle\" fill-opacity=\"0.153549941\" fill=\"#138E34\" x=\"191\" y=\"196\" width=\"1042\" height=\"344\"></rect><rect id=\"Rectangle\" fill-opacity=\"0.347697225\" fill=\"#F6EF54\" x=\"191\" y=\"142\" width=\"1042\" height=\"49\"></rect><rect id=\"Rectangle\" fill-opacity=\"0.265983528\" fill=\"#F94101\" x=\"191\" y=\"91\" width=\"1042\" height=\"45\"></rect><rect id=\"Rectangle\" fill-opacity=\"0.249839516\" fill=\"#E90404\" x=\"191\" y=\"0\" width=\"1042\" height=\"85\"></rect><path d=\"M884.966179,88.5 L918.024519,137.5 L784.973481,137.5 L818.031821,88.5 L884.966179,88.5 Z\" id=\"Combined-Shape\" stroke=\"#000000\" fill-opacity=\"0.63352102\" fill=\"#F5825B\"></path><path d=\"M917.394304,137.5 L946.58887,189.5 L757.40913,189.5 L786.603696,137.5 L917.394304,137.5 Z\" id=\"Combined-Shape\" stroke=\"#000000\" fill-opacity=\"0.65942895\" fill=\"#F6EF54\"></path><path d=\"M945.218955,189.5 L1153.10409,526.5 L547.895914,526.5 L755.781045,189.5 L945.218955,189.5 Z\" id=\"Combined-Shape\" stroke=\"#000000\" fill-opacity=\"0.467474664\" fill=\"#138E34\"></path><text id=\"Harmful\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"641.491211\" y=\"124\">Harmful</tspan></text><g id=\"Group\" transform=\"translate(450.000000, 26.000000)\" fill=\"#000000\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\"><text id=\"Severe\"><tspan x=\"189.467773\" y=\"35\">Severe</tspan></text><text id=\"Zone-IV\"><tspan x=\"0.46484375\" y=\"35\">Zone IV</tspan></text></g><text id=\"78-%\" font-family=\"Helvetica\" font-size=\"28\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"857.5\" y=\"203\"></tspan><tspan x=\"828.701904\" y=\"237\">78 </tspan><tspan x=\"867.625732\" y=\"237\" font-size=\"21\">%</tspan></text><text id=\"9-%\" font-family=\"Helvetica\" font-size=\"28\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"858\" y=\"141\"></tspan><tspan x=\"836.988037\" y=\"175\">9 </tspan><tspan x=\"860.3396\" y=\"175\" font-size=\"21\">%</tspan></text><text id=\"8-%\" font-family=\"Helvetica\" font-size=\"30\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"857\" y=\"91\"></tspan><tspan x=\"835.154053\" y=\"127\">8 </tspan><tspan x=\"860.173584\" y=\"127\" font-size=\"21\">%</tspan></text><text id=\"5%\" font-family=\"Helvetica\" font-size=\"28\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"855\" y=\"47\"></tspan><tspan x=\"837.877686\" y=\"81\">5</tspan><tspan x=\"853.449951\" y=\"81\" font-size=\"21\">%</tspan></text><text id=\"Zone-II\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"451.969727\" y=\"180\">Zone II </tspan></text><text id=\"Zone-III\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"450.46875\" y=\"124\">Zone III</tspan></text><text id=\"Zone-I\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"801.970703\" y=\"296\">Zone I </tspan></text><path d=\"M852.5,29.8563693 L1153.44768,526 L551.55232,526 L852.5,29.8563693 Z\" id=\"Triangle\" stroke=\"#000000\" stroke-width=\"4\"></path><g id=\"Group-5\" transform=\"translate(907.000000, 5.000000)\" fill=\"#000000\" font-family=\"Helvetica\" font-weight=\"normal\"><g id=\"Group-4\"><text id=\"AUDIT-score\" font-size=\"21\"><tspan x=\"58.0915527\" y=\"20\">AUDIT score</tspan></text><g id=\"Group-3\" transform=\"translate(127.000000, 28.000000)\" font-size=\"18\"><text id=\"Male-&lt;=65\"><tspan x=\"0.469726562\" y=\"40\">Male &lt;=65</tspan></text><text id=\"Female-or-Male-&gt;-65\"><tspan x=\"0.211425781\" y=\"18\">Female or Male &gt; 65</tspan></text></g><text id=\"16-19\" font-size=\"18\"><tspan x=\"66.9814453\" y=\"108\">16-19</tspan></text><text id=\"16-19\" font-size=\"18\"><tspan x=\"66.9814453\" y=\"129\">16-19</tspan></text><text id=\"20+\" font-size=\"18\"><tspan x=\"81.7333984\" y=\"42\">20+</tspan></text><text id=\"20+\" font-size=\"18\"><tspan x=\"81.7333984\" y=\"66\">20+</tspan></text><text id=\"8-15\" font-size=\"18\"><tspan x=\"75.9868164\" y=\"181\">8-15</tspan></text><text id=\"7-15\" font-size=\"18\"><tspan x=\"75.9868164\" y=\"158\">7-15</tspan></text><text id=\"0-7\" font-size=\"18\"><tspan x=\"90.9921875\" y=\"246\">0-7</tspan></text><text id=\"0-6\" font-size=\"18\"><tspan x=\"90.9921875\" y=\"223\">0-6</tspan></text><g id=\"Group-3\" transform=\"translate(127.000000, 141.000000)\" font-size=\"18\"><text id=\"Male-&lt;=65\"><tspan x=\"0.469726562\" y=\"40\">Male &lt;=65</tspan></text><text id=\"Female-or-Male-&gt;-65\"><tspan x=\"0.211425781\" y=\"18\">Female or Male &gt; 65</tspan></text></g></g><g id=\"Group-3\" transform=\"translate(127.000000, 87.000000)\" font-size=\"18\"><text id=\"Male-&lt;=65\"><tspan x=\"0.469726562\" y=\"40\">Male &lt;=65</tspan></text><text id=\"Female-or-Male-&gt;-65\"><tspan x=\"0.211425781\" y=\"18\">Female or Male &gt; 65</tspan></text></g><g id=\"Group-3\" transform=\"translate(127.000000, 206.000000)\" font-size=\"18\"><text id=\"Male-&lt;=65\"><tspan x=\"0.469726562\" y=\"40\">Male &lt;=65</tspan></text><text id=\"Female-or-Male-&gt;-65\"><tspan x=\"0.211425781\" y=\"18\">Female or Male &gt; 65</tspan></text></g></g><text id=\"Low-Risk-or-Abstain\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"783.980469\" y=\"360\">Low Risk </tspan><tspan x=\"776.94043\" y=\"403\">or Abstain</tspan></text><text id=\"Risky\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"643.001953\" y=\"178\">Risky</tspan></text><g id=\"Your-Drinking\" transform=\"translate(0.000000, 62.000000)\" fill=\"#000000\"><path id=\"Line-2\" d=\"M361.75958,21.986962 L415.5,49.5 L361.245318,75.9845132 L361.454,53.985 L152.952383,51.9997733 L147.95261,51.9521564 L148.047844,41.9526099 L153.047617,42.0002267 L361.55,43.986 L361.75958,21.986962 Z\" fill-rule=\"nonzero\"></path><text id=\"Your-drinking\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\"><tspan x=\"44.1308594\" y=\"35\">Your </tspan><tspan x=\"17.4648438\" y=\"78\">drinking</tspan></text></g></g></g></svg>'

define DrinkingPyramidZoneIV:
  '<svg width=\"1255px\" height=\"577px\" viewBox=\"0 0 1255 577\" version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\"><title>Zone IV Arrow</title><g id=\"Zone-IV-Arrow\" stroke=\"none\" stroke-width=\"1\" fill=\"none\" fill-rule=\"evenodd\"><rect fill=\"#FFFFFF\" x=\"0\" y=\"0\" width=\"1255\" height=\"577\"></rect><g id=\"Group-6\" transform=\"translate(196.000000, 20.000000)\"><g id=\"Triangle-2\" transform=\"translate(360.000000, 29.000000)\" fill=\"#D8D8D8\" stroke=\"#979797\"><path d=\"M300.5,0.969210829 L600.115235,498.5 L0.884765239,498.5 L300.5,0.969210829 Z\" id=\"Triangle\"></path><path d=\"M300.5,0.969210829 L600.115235,498.5 L0.884765239,498.5 L300.5,0.969210829 Z\" id=\"Triangle\"></path></g><path d=\"M660.5,28.9940559 L695.130508,88.5 L625.869492,88.5 L660.5,28.9940559 Z\" id=\"Triangle\" stroke=\"#000000\" fill-opacity=\"0.574287041\" fill=\"#E32525\"></path><rect id=\"Rectangle\" fill-opacity=\"0.153549941\" fill=\"#138E34\" x=\"0\" y=\"196\" width=\"1042\" height=\"344\"></rect><rect id=\"Rectangle\" fill-opacity=\"0.347697225\" fill=\"#F6EF54\" x=\"0\" y=\"142\" width=\"1042\" height=\"49\"></rect><rect id=\"Rectangle\" fill-opacity=\"0.265983528\" fill=\"#F94101\" x=\"0\" y=\"91\" width=\"1042\" height=\"45\"></rect><rect id=\"Rectangle\" fill-opacity=\"0.249839516\" fill=\"#E90404\" x=\"0\" y=\"0\" width=\"1042\" height=\"85\"></rect><path d=\"M693.966179,88.5 L727.024519,137.5 L593.973481,137.5 L627.031821,88.5 L693.966179,88.5 Z\" id=\"Combined-Shape\" stroke=\"#000000\" fill-opacity=\"0.63352102\" fill=\"#F5825B\"></path><path d=\"M726.394304,137.5 L755.58887,189.5 L566.40913,189.5 L595.603696,137.5 L726.394304,137.5 Z\" id=\"Combined-Shape\" stroke=\"#000000\" fill-opacity=\"0.65942895\" fill=\"#F6EF54\"></path><path d=\"M754.218955,189.5 L962.104086,526.5 L356.895914,526.5 L564.781045,189.5 L754.218955,189.5 Z\" id=\"Combined-Shape\" stroke=\"#000000\" fill-opacity=\"0.467474664\" fill=\"#138E34\"></path><text id=\"Harmful\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"450.491211\" y=\"124\">Harmful</tspan></text><g id=\"Group\" transform=\"translate(259.000000, 26.000000)\" fill=\"#000000\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\"><text id=\"Severe\"><tspan x=\"189.467773\" y=\"35\">Severe</tspan></text><text id=\"Zone-IV\"><tspan x=\"0.46484375\" y=\"35\">Zone IV</tspan></text></g><text id=\"78-%\" font-family=\"Helvetica\" font-size=\"28\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"666.5\" y=\"203\"></tspan><tspan x=\"637.701904\" y=\"237\">78 </tspan><tspan x=\"676.625732\" y=\"237\" font-size=\"21\">%</tspan></text><text id=\"9-%\" font-family=\"Helvetica\" font-size=\"28\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"667\" y=\"141\"></tspan><tspan x=\"645.988037\" y=\"175\">9 </tspan><tspan x=\"669.3396\" y=\"175\" font-size=\"21\">%</tspan></text><text id=\"8-%\" font-family=\"Helvetica\" font-size=\"30\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"666\" y=\"91\"></tspan><tspan x=\"644.154053\" y=\"127\">8 </tspan><tspan x=\"669.173584\" y=\"127\" font-size=\"21\">%</tspan></text><text id=\"5%\" font-family=\"Helvetica\" font-size=\"28\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"664\" y=\"47\"></tspan><tspan x=\"646.877686\" y=\"81\">5</tspan><tspan x=\"662.449951\" y=\"81\" font-size=\"21\">%</tspan></text><text id=\"Zone-II\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"260.969727\" y=\"180\">Zone II </tspan></text><text id=\"Zone-III\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"259.46875\" y=\"124\">Zone III</tspan></text><text id=\"Zone-I\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"610.970703\" y=\"296\">Zone I </tspan></text><path d=\"M661.5,29.8563693 L962.44768,526 L360.55232,526 L661.5,29.8563693 Z\" id=\"Triangle\" stroke=\"#000000\" stroke-width=\"4\"></path><g id=\"Group-5\" transform=\"translate(716.000000, 5.000000)\" fill=\"#000000\" font-family=\"Helvetica\" font-weight=\"normal\"><g id=\"Group-4\"><text id=\"AUDIT-score\" font-size=\"21\"><tspan x=\"58.0915527\" y=\"20\">AUDIT score</tspan></text><g id=\"Group-3\" transform=\"translate(127.000000, 28.000000)\" font-size=\"18\"><text id=\"Male-&lt;=65\"><tspan x=\"0.469726562\" y=\"40\">Male &lt;=65</tspan></text><text id=\"Female-or-Male-&gt;-65\"><tspan x=\"0.211425781\" y=\"18\">Female or Male &gt; 65</tspan></text></g><text id=\"16-19\" font-size=\"18\"><tspan x=\"66.9814453\" y=\"108\">16-19</tspan></text><text id=\"16-19\" font-size=\"18\"><tspan x=\"66.9814453\" y=\"129\">16-19</tspan></text><text id=\"20+\" font-size=\"18\"><tspan x=\"81.7333984\" y=\"42\">20+</tspan></text><text id=\"20+\" font-size=\"18\"><tspan x=\"81.7333984\" y=\"66\">20+</tspan></text><text id=\"8-15\" font-size=\"18\"><tspan x=\"75.9868164\" y=\"181\">8-15</tspan></text><text id=\"7-15\" font-size=\"18\"><tspan x=\"75.9868164\" y=\"158\">7-15</tspan></text><text id=\"0-7\" font-size=\"18\"><tspan x=\"90.9921875\" y=\"246\">0-7</tspan></text><text id=\"0-6\" font-size=\"18\"><tspan x=\"90.9921875\" y=\"223\">0-6</tspan></text><g id=\"Group-3\" transform=\"translate(127.000000, 141.000000)\" font-size=\"18\"><text id=\"Male-&lt;=65\"><tspan x=\"0.469726562\" y=\"40\">Male &lt;=65</tspan></text><text id=\"Female-or-Male-&gt;-65\"><tspan x=\"0.211425781\" y=\"18\">Female or Male &gt; 65</tspan></text></g></g><g id=\"Group-3\" transform=\"translate(127.000000, 87.000000)\" font-size=\"18\"><text id=\"Male-&lt;=65\"><tspan x=\"0.469726562\" y=\"40\">Male &lt;=65</tspan></text><text id=\"Female-or-Male-&gt;-65\"><tspan x=\"0.211425781\" y=\"18\">Female or Male &gt; 65</tspan></text></g><g id=\"Group-3\" transform=\"translate(127.000000, 206.000000)\" font-size=\"18\"><text id=\"Male-&lt;=65\"><tspan x=\"0.469726562\" y=\"40\">Male &lt;=65</tspan></text><text id=\"Female-or-Male-&gt;-65\"><tspan x=\"0.211425781\" y=\"18\">Female or Male &gt; 65</tspan></text></g></g><text id=\"Low-Risk-or-Abstain\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"592.980469\" y=\"360\">Low Risk </tspan><tspan x=\"585.94043\" y=\"403\">or Abstain</tspan></text><text id=\"Risky\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\" fill=\"#000000\"><tspan x=\"452.001953\" y=\"178\">Risky</tspan></text></g><g id=\"Your-Drinking\" transform=\"translate(3.000000, 21.000000)\" fill=\"#000000\"><path id=\"Line-2\" d=\"M361.75958,21.986962 L415.5,49.5 L361.245318,75.9845132 L361.454,53.985 L152.952383,51.9997733 L147.95261,51.9521564 L148.047844,41.9526099 L153.047617,42.0002267 L361.55,43.986 L361.75958,21.986962 Z\" fill-rule=\"nonzero\"></path><text id=\"Your-drinking\" font-family=\"Helvetica\" font-size=\"36\" font-weight=\"normal\"><tspan x=\"44.1308594\" y=\"35\">Your </tspan><tspan x=\"17.4648438\" y=\"78\">drinking</tspan></text></g></g></svg>'

define ProvideFeedbackPatientTextPart3:
  case
    when PregnantAndNotDrinking then ''
    when IsZoneOneDrinker then DrinkingPyramidZoneI
    when IsZoneTwoDrinker then DrinkingPyramidZoneII
    when IsZoneThreeDrinker then DrinkingPyramidZoneIII
    when IsZoneFourDrinker then DrinkingPyramidZoneIV
    else ''
  end

define NeverDrinkerText:
  if QuestionOneResponse = 'Never' then 'never '
  else ''

define QuestionOneResponseText:
  if QuestionOneResponse = 'Never' then ''
  else QuestionOneResponse

define QuestionThreePrefix:
  if QuestionThreeResponse = 'Never' then '**You never** '
  else '**' + QuestionThreeResponse + '**, you '

define DrinkThreshold:
  if FemaleAtBirth
    or SexAtBirthUnknown
    or (MaleAtBirth and AgeInYears() > 65)
  then '4'
  else '5' // (SexAtBirth = 'Male' and AgeInYears <= 65)

define ProvideFeedbackPatientTextPart4:
  if PregnantAndNotDrinking then
    ''
  else
    '**Your responses to questions 1-3:**\n'
      + '1. You ' + NeverDrinkerText + 'have a drink containing alcohol '
      + '**' + QuestionOneResponseText + '**\n'
      + '2. On a typical day when drinking, you have '
      + '**' + QuestionTwoResponse + '** drinks' + '\n'
      + '3. ' +  QuestionThreePrefix +
      + 'have **' + DrinkThreshold + ' or more** drinks on one occasion.\n'

define ProvideFeedback:
  Tuple{
    instructions: Tuple{
      title: ProvideFeedbackInstructionsTitle,
      text: ProvideFeedbackInstructionsText
    },
    content: Tuple{
      part1: ProvideFeedbackPatientTextPart1,
      part2: ProvideFeedbackPatientTextPart2,
      part3: ProvideFeedbackPatientTextPart3,
      part4: ProvideFeedbackPatientTextPart4
    }
  }

// 2. Reinforce Key Information on Alcohol Use

define ReinforceKeyInformationInstructionsTitle:
  'Reinforce the following information with the patient'

define ReinforceKeyInformationInstructionsText:
  if (
    PregnantAndNotDrinking or
    PregnantAndDrinking
  ) then
    'Reinforce the impact of alcohol use on fetal development and outcomes'
  else
    'Reinforce standard drink size and recommended frequency and quantity of alcohol intake to stay within low-risk guidelines'

define ReinforcementIntroduction:
  if (
    PregnantAndNotDrinking or
    PregnantAndDrinking
  ) then
    'There is no known safe amount of alcohol use in pregnancy or while trying to become pregnant.\n'
      + '\n'
      + 'Alcohol use during pregnancy can cause birth defects and developmental disabilities, collectively known as fetal alcohol spectrum disorders (FASDs).\n'
      + '\n'
      + 'These are preventable if a developing baby is not exposed to alcohol before birth.\n'
      + '\n'
      + 'Alcohol use during pregnancy is also linked to other outcomes, such as miscarriage, stillbirth, preterm (early) birth, and sudden infant death syndrome (SIDS).'
  else if IsZoneFourDrinker then
    'Your level of drinking far exceeds safe guidelines, and specific problems related to drinking are already present.\n'
      + '\n'
      + 'You may have signs of alcohol dependence.\n'
      + '\n'
  else
    'Let\'s discuss a standard drink size'

define DrinkSizeGraphic:
  if (
    PregnantAndNotDrinking or
    PregnantAndDrinking or 
    IsZoneFourDrinker
  ) then 
    ''
  else 
    '<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" width=\"672\" height=\"377\" viewBox=\"0 0 672 377\"><defs><filter id=\"Path_127\" x=\"500\" y=\"250.966\" width=\"41\" height=\"54.534\" filterUnits=\"userSpaceOnUse\"><feOffset dy=\"3\" input=\"SourceAlpha\"/><feGaussianBlur stdDeviation=\"3\" result=\"blur\"/><feFlood flood-opacity=\"0.161\"/><feComposite operator=\"in\" in2=\"blur\"/><feComposite in=\"SourceGraphic\"/></filter><filter id=\"Path_128\" x=\"520\" y=\"237.965\" width=\"61.878\" height=\"67.535\" filterUnits=\"userSpaceOnUse\"><feOffset dy=\"3\" input=\"SourceAlpha\"/><feGaussianBlur stdDeviation=\"3\" result=\"blur-2\"/><feFlood flood-opacity=\"0.161\"/><feComposite operator=\"in\" in2=\"blur-2\"/><feComposite in=\"SourceGraphic\"/></filter><filter id=\"Union_4\" x=\"185.109\" y=\"158.5\" width=\"90.973\" height=\"145\" filterUnits=\"userSpaceOnUse\"><feOffset dy=\"3\" input=\"SourceAlpha\"/><feGaussianBlur stdDeviation=\"3\" result=\"blur-3\"/><feFlood flood-opacity=\"0.161\"/><feComposite operator=\"in\" in2=\"blur-3\"/><feComposite in=\"SourceGraphic\"/></filter><filter id=\"Exclusion_2\" x=\"186.946\" y=\"192.5\" width=\"85.576\" height=\"113\" filterUnits=\"userSpaceOnUse\"><feOffset dy=\"3\" input=\"SourceAlpha\"/><feGaussianBlur stdDeviation=\"3\" result=\"blur-4\"/><feFlood flood-opacity=\"0.161\"/><feComposite operator=\"in\" in2=\"blur-4\"/><feComposite in=\"SourceGraphic\"/></filter><filter id=\"Subtraction_1\" x=\"345.5\" y=\"272.343\" width=\"89\" height=\"34.157\" filterUnits=\"userSpaceOnUse\"><feOffset dy=\"3\" input=\"SourceAlpha\"/><feGaussianBlur stdDeviation=\"3\" result=\"blur-5\"/><feFlood flood-opacity=\"0.161\"/><feComposite operator=\"in\" in2=\"blur-5\"/><feComposite in=\"SourceGraphic\"/></filter><filter id=\"Union_3\" x=\"30.496\" y=\"154.5\" width=\"91.007\" height=\"151\" filterUnits=\"userSpaceOnUse\"><feOffset dy=\"3\" input=\"SourceAlpha\"/><feGaussianBlur stdDeviation=\"3\" result=\"blur-6\"/><feFlood flood-opacity=\"0.161\"/><feComposite operator=\"in\" in2=\"blur-6\"/><feComposite in=\"SourceGraphic\"/></filter><clipPath id=\"clip-IconReproduceColorDSGlass_3\"><rect width=\"672\" height=\"377\"/></clipPath></defs><g id=\"IconReproduceColorDSGlass_3\" data-name=\"IconReproduceColorDSGlass – 3\" clip-path=\"url(#clip-IconReproduceColorDSGlass_3)\"><rect width=\"672\" height=\"377\" fill=\"#fff\"/><text id=\"_12_fl_oz_of_regular_beer\" data-name=\"12 fl oz of regular beer\" transform=\"translate(20 33)\" fill=\"#707070\" font-size=\"24\" font-family=\"HelveticaNeue, Helvetica Neue\"><tspan x=\"3.344\" y=\"23\">12 fl oz of </tspan><tspan x=\"15.56\" y=\"52\" font-family=\"HelveticaNeue-Bold, Helvetica Neue\" font-weight=\"700\">regular </tspan><tspan x=\"30.224\" y=\"81\" font-family=\"HelveticaNeue-Bold, Helvetica Neue\" font-weight=\"700\">beer</tspan></text><text id=\"_8-9_fl_oz_of_malt_liquor_shown_in_a_12_oz_glass_\" data-name=\"8-9 fl oz of malt liquor (shown in a 12 oz glass)\" transform=\"translate(155.096 28)\" fill=\"#707070\" font-size=\"24\" font-family=\"HelveticaNeue, Helvetica Neue\"><tspan x=\"21.176\" y=\"23\">8-9 fl oz of</tspan><tspan font-family=\"HelveticaNeue-Bold, Helvetica Neue\" font-weight=\"700\"><tspan x=\"17.444\" y=\"52\">malt liquor </tspan></tspan><tspan font-size=\"18\"><tspan x=\"32.834\" y=\"75\">(shown in a </tspan><tspan x=\"30.674\" y=\"97\">12 oz glass)</tspan></tspan></text><text id=\"About_5_Alcohol_\" data-name=\"About 5% Alcohol \" transform=\"translate(76 331)\" fill=\"#707070\" font-size=\"16\" font-family=\"HelveticaNeue, Helvetica Neue\"><tspan x=\"-35.272\" y=\"0\">about 5%</tspan><tspan x=\"-28\" y=\"18\">alcohol </tspan></text><text id=\"About_7_Alcohol_\" data-name=\"About 7% Alcohol \" transform=\"translate(231 332)\" fill=\"#707070\" font-size=\"16\" font-family=\"HelveticaNeue, Helvetica Neue\"><tspan x=\"-35.272\" y=\"0\">about 7%</tspan><tspan x=\"-28\" y=\"18\">alcohol </tspan></text><text id=\"About_12_Alcohol_\" data-name=\"About 12% Alcohol \" transform=\"translate(390 332)\" fill=\"#707070\" font-size=\"16\" font-family=\"HelveticaNeue, Helvetica Neue\"><tspan x=\"-39.72\" y=\"0\">about 12%</tspan><tspan x=\"-28\" y=\"18\">alcohol </tspan></text><text id=\"_40_Alcohol_\" data-name=\"40% Alcohol \" transform=\"translate(544 332)\" fill=\"#707070\" font-size=\"16\" font-family=\"HelveticaNeue, Helvetica Neue\"><tspan x=\"-16.896\" y=\"0\">40%</tspan><tspan x=\"-28\" y=\"18\">alcohol </tspan></text><text id=\"_5_fl_oz_of_table_wine\" data-name=\"5 fl oz of table wine\" transform=\"translate(393 51)\" fill=\"#707070\" font-size=\"24\" font-family=\"HelveticaNeue, Helvetica Neue\"><tspan x=\"-45.984\" y=\"0\">5 fl oz of</tspan><tspan font-family=\"HelveticaNeue-Bold, Helvetica Neue\" font-weight=\"700\"><tspan x=\"-58.632\" y=\"29\">table wine</tspan></tspan></text><text id=\"_1.5_fl_oz_shot_of_80-proof_distilled_spirits\" data-name=\"1.5 fl oz shot of 80-proof distilled spirits\" transform=\"translate(464.592 122)\" fill=\"#707070\" font-size=\"24\" font-family=\"HelveticaNeue, Helvetica Neue\"><tspan x=\"10.832\" y=\"23\">1.5 fl oz shot of </tspan><tspan x=\"47.264\" y=\"52\">80-proof</tspan><tspan font-family=\"HelveticaNeue-Bold, Helvetica Neue\" font-weight=\"700\"><tspan x=\"10.256\" y=\"81\">distilled spirits</tspan></tspan></text><path id=\"Path_130\" data-name=\"Path 130\" d=\"M0,0V66.679\" transform=\"translate(601.201 205.466)\" fill=\"none\" stroke=\"#fff\" stroke-width=\"2\"/><g id=\"Group_284\" data-name=\"Group 284\" transform=\"translate(21.596 22)\"><rect id=\"Rectangle_25\" data-name=\"Rectangle 25\" width=\"3\" height=\"25\" transform=\"translate(504 228.5)\" fill=\"#fff\"/><g id=\"Group_267\" data-name=\"Group 267\" transform=\"translate(-116.596 5.966)\"><g transform=\"matrix(1, 0, 0, 1, 95, -27.97)\" filter=\"url(#Path_127)\"><g id=\"Path_127-2\" data-name=\"Path 127\" transform=\"translate(509 256.97)\" fill=\"#fff\"><path d=\"M 16.55470657348633 34.5341796875 L 6.288052082061768 34.5341796875 C 5.712080001831055 34.07328033447266 4.662561893463135 33.00835418701172 4.24312162399292 32.45539474487305 L 2.076209545135498 1.99999988079071 L 20.90143013000488 1.99999988079071 L 18.13913917541504 32.55117034912109 C 17.84582328796387 33.04850006103516 17.04531478881836 34.04358673095703 16.55470657348633 34.5341796875 Z\" stroke=\"none\"/><path d=\"M 4.22355842590332 4 L 6.191612243652344 31.66048812866211 C 6.444622039794922 31.93883323669434 6.762958526611328 32.26328277587891 7.048093795776367 32.5341796875 L 15.66534996032715 32.5341796875 C 15.85265636444092 32.30955505371094 16.04254150390625 32.06784057617188 16.19345283508301 31.86016654968262 L 18.71243667602539 4 L 4.22355842590332 4 M 1 0 L 22 0 C 22.55228042602539 0 23 0.4477195739746094 23 1 L 20.10712051391602 32.99547958374023 C 20.10712051391602 33.54777145385742 17.70932960510254 36.5341796875 17.15703964233398 36.5341796875 L 5.779720306396484 36.5341796875 C 5.227439880371094 36.5341796875 2.2764892578125 33.54777145385742 2.2764892578125 32.99547958374023 L 0 1 C 0 0.4477195739746094 0.4477195739746094 0 1 0 Z\" stroke=\"none\" fill=\"#707070\"/></g></g><g transform=\"matrix(1, 0, 0, 1, 95, -27.97)\" filter=\"url(#Path_128)\"><g id=\"Path_128-2\" data-name=\"Path 128\" transform=\"translate(529 243.97)\" fill=\"#fff\"><path d=\"M 38.79655075073242 47.53467559814453 L 6.6346435546875 47.53467559814453 L 2.204050064086914 2.000004053115845 L 41.74491500854492 2.000004053115845 L 38.79655075073242 47.53467559814453 Z\" stroke=\"none\"/><path d=\"M 4.408100128173828 3.999992370605469 L 8.449485778808594 45.53466415405273 L 36.9218635559082 45.53466415405273 L 39.61122512817383 3.999992370605469 L 4.408100128173828 3.999992370605469 M 0 -7.62939453125e-06 L 43.87860107421875 -7.62939453125e-06 L 40.67124176025391 49.53466415405273 L 4.819801330566406 49.53466415405273 L 0 -7.62939453125e-06 Z\" stroke=\"none\" fill=\"#707070\"/></g></g></g><g id=\"Ellipse_25\" data-name=\"Ellipse 25\" transform=\"translate(507.404 218.966)\" fill=\"#fff\" stroke=\"#707070\" stroke-width=\"1\"><ellipse cx=\"22\" cy=\"2.5\" rx=\"22\" ry=\"2.5\" stroke=\"none\"/><ellipse cx=\"22\" cy=\"2.5\" rx=\"21.5\" ry=\"2\" fill=\"none\"/></g><g id=\"Ellipse_26\" data-name=\"Ellipse 26\" transform=\"translate(487.404 232.966)\" fill=\"#fff\" stroke=\"#707070\" stroke-width=\"1\"><ellipse cx=\"11.5\" cy=\"3\" rx=\"11.5\" ry=\"3\" stroke=\"none\"/><ellipse cx=\"11.5\" cy=\"3\" rx=\"11\" ry=\"2.5\" fill=\"none\"/></g><g id=\"Rectangle_27\" data-name=\"Rectangle 27\" transform=\"translate(517.524 249.486) rotate(-25)\" fill=\"#fff\" stroke=\"#707070\" stroke-width=\"1\"><rect width=\"14\" height=\"12\" stroke=\"none\"/><rect x=\"0.5\" y=\"0.5\" width=\"13\" height=\"11\" fill=\"none\"/></g><line id=\"Line_9\" data-name=\"Line 9\" x2=\"35.25\" transform=\"translate(512.654 251.466)\" fill=\"none\" stroke=\"#707070\" stroke-width=\"3\"/><g id=\"Rectangle_28\" data-name=\"Rectangle 28\" transform=\"translate(529.215 256.683) rotate(-25)\" fill=\"#fff\" stroke=\"#707070\" stroke-width=\"1\"><rect width=\"11.281\" height=\"13.295\" stroke=\"none\"/><rect x=\"0.5\" y=\"0.5\" width=\"10.281\" height=\"12.295\" fill=\"none\"/></g></g><g id=\"Group_282\" data-name=\"Group 282\" transform=\"translate(92.987 20)\"><g transform=\"matrix(1, 0, 0, 1, -92.99, -20)\" filter=\"url(#Union_4)\"><g id=\"Union_4-2\" data-name=\"Union 4\" transform=\"translate(214.99 1109.5)\" fill=\"#fff\"><path d=\"M 41.20711898803711 -820.0001220703125 L -11.21973705291748 -820.0001220703125 C -11.3967981338501 -820.4407958984375 -11.57645893096924 -821.0009765625 -11.621994972229 -821.2732543945312 L -11.62408638000488 -821.3048095703125 L -15.78550434112549 -884.1320190429688 L -15.90921401977539 -885.9998168945312 L -15.95348739624023 -885.9998168945312 L -16.0837230682373 -888.630126953125 L -16.08454132080078 -888.6467895507812 L -16.08564949035645 -888.6634521484375 L -16.54341506958008 -895.5745849609375 L -16.43523216247559 -895.7293090820312 L -16.46908569335938 -896.4129638671875 L -18.77583122253418 -943 L 49.97128295898438 -943 L 46.53165817260742 -885.9998168945312 L 46.29771423339844 -885.9998168945312 L 46.16800308227539 -884.1388549804688 L 41.79216003417969 -821.3579711914062 C 41.71257019042969 -821.057373046875 41.4455451965332 -820.4420166015625 41.20711898803711 -820.0001220703125 Z\" stroke=\"none\"/><path d=\"M 39.83208465576172 -822.0001220703125 L 44.4322509765625 -887.9998168945312 L 44.64870834350586 -887.9998168945312 L 47.84695434570312 -941 L -16.67433738708496 -941 L -14.40381050109863 -895.1441650390625 L -14.50127506256104 -895.0047607421875 L -14.0861701965332 -888.7290649414062 L -14.0500602722168 -887.9998168945312 L -14.03730964660645 -887.9998168945312 L -9.665751457214355 -822.0001220703125 L 39.83208465576172 -822.0001220703125 M 42.07231140136719 -818.0001220703125 L -12.21479034423828 -818.0001220703125 C -12.76739025115967 -818.0001220703125 -13.61970996856689 -820.6199951171875 -13.61970996856689 -821.172607421875 L -17.78112983703613 -883.9998168945312 L -17.85688972473145 -883.9998168945312 L -18.08127021789551 -888.53125 L -18.57599067687988 -896.0004272460938 C -18.57599067687988 -896.1099853515625 -18.53562927246094 -896.2153930664062 -18.46663093566895 -896.3140869140625 L -20.87729072570801 -945 L 52.09561157226562 -945 L 48.41461181640625 -883.9998168945312 L 48.16315078735352 -883.9998168945312 L 43.78411102294922 -821.172607421875 C 43.78411102294922 -820.6199951171875 42.62490844726562 -818.0001220703125 42.07231140136719 -818.0001220703125 Z\" stroke=\"none\" fill=\"#707070\"/></g></g><line id=\"Line_10\" data-name=\"Line 10\" x2=\"62.25\" transform=\"translate(105.533 181.5)\" fill=\"none\" stroke=\"#707070\" stroke-width=\"4\"/><g transform=\"matrix(1, 0, 0, 1, -92.99, -20)\" filter=\"url(#Exclusion_2)\"><g id=\"Exclusion_2-2\" data-name=\"Exclusion 2\" transform=\"translate(214.52 1095.5)\" fill=\"#ecf08c\"><path d=\"M 41.10384368896484 -804.0001220703125 L -11.12658596038818 -804.0001220703125 C -11.34821128845215 -804.6287841796875 -11.58156871795654 -805.4931640625 -11.61970043182373 -805.8572998046875 L -11.61970043182373 -805.8702392578125 L -11.62272930145264 -805.9251708984375 L -15.78415775299072 -881.476806640625 L -16.08430099487305 -886.926025390625 L -16.52903747558594 -895.0003662109375 L 46.95001983642578 -895.0003662109375 L 46.1665153503418 -881.4825439453125 L 41.78745651245117 -805.930908203125 L 41.78745269775391 -805.9308471679688 C 41.71737670898438 -805.5422973632812 41.38805770874023 -804.620849609375 41.10384368896484 -804.0001220703125 Z\" stroke=\"none\"/><path d=\"M 39.7337760925293 -806.0001220703125 C 39.76041030883789 -806.0833129882812 39.78332901000977 -806.1598510742188 39.80120849609375 -806.2259521484375 L 44.83073806762695 -893.0003662109375 L -14.41584300994873 -893.0003662109375 L -9.627079010009766 -806.0589599609375 C -9.623849868774414 -806.0403442382812 -9.620217323303223 -806.020751953125 -9.61620044708252 -806.0001220703125 L 39.7337760925293 -806.0001220703125 M 42.07230758666992 -802.0001220703125 L -12.21480083465576 -802.0001220703125 C -12.75347709655762 -802.0001220703125 -13.61970806121826 -805.1343383789062 -13.61970806121826 -805.815185546875 L -18.57600021362305 -895.7979736328125 C -18.57600021362305 -895.92333984375 -18.53921508789062 -896.05029296875 -18.46663093566895 -896.1751708984375 C -18.19643020629883 -896.639892578125 -17.45639991760254 -897.0003662109375 -17.00009346008301 -897.0003662109375 L 47.99970626831055 -897.0003662109375 C 48.55104446411133 -897.0003662109375 48.99959945678711 -896.4609375 48.99959945678711 -895.7979736328125 L 43.78410720825195 -805.815185546875 C 43.78410720825195 -805.184326171875 42.63164520263672 -802.0001220703125 42.07230758666992 -802.0001220703125 Z\" stroke=\"none\" fill=\"#707070\"/></g></g></g><g id=\"Group_285\" data-name=\"Group 285\" transform=\"translate(26.986 22.019)\"><g id=\"Group_283\" data-name=\"Group 283\"><g id=\"Group_280\" data-name=\"Group 280\" transform=\"translate(131.514 -0.176)\"><g id=\"Group_263\" data-name=\"Group 263\" transform=\"translate(-39 -4.5)\"><g transform=\"matrix(1, 0, 0, 1, -119.5, -17.34)\" filter=\"url(#Subtraction_1)\"><path id=\"Subtraction_1-2\" data-name=\"Subtraction 1\" d=\"M69.265-931.843H.734A4.914,4.914,0,0,1,.5-933.332c0-1.71.912-3.369,2.711-4.93A23.908,23.908,0,0,1,10.6-942.29C17.12-944.682,25.783-946,35-946s17.88,1.318,24.4,3.71a23.9,23.9,0,0,1,7.394,4.028c1.8,1.561,2.711,3.22,2.711,4.93a4.917,4.917,0,0,1-.234,1.488Z\" transform=\"translate(355 1225.34)\" fill=\"#fff\" stroke=\"#707070\" stroke-width=\"2\"/></g><g id=\"Union_2\" data-name=\"Union 2\" transform=\"translate(252 1026)\" fill=\"#fff\"><path d=\"M 23.00031280517578 -764.000244140625 L 15.00040817260742 -764.000244140625 L 15.00040817260742 -828.2738647460938 L 15.00040817260742 -829.1454467773438 L 14.13702774047852 -829.2644653320312 C 6.186956405639648 -830.36083984375 -1.155877113342285 -834.8584594726562 -6.538853168487549 -841.9288940429688 C -11.99523448944092 -849.0958251953125 -15.00021076202393 -858.3545532226562 -15.00021076202393 -867.9996337890625 C -15.00021076202393 -868.6508178710938 -14.98642444610596 -869.309814453125 -14.9592342376709 -869.9584350585938 L -14.91554355621338 -871.0003051757812 L -15.00021076202393 -871.0003051757812 L -15.00021076202393 -944.9999389648438 L 51.00019454956055 -944.9999389648438 L 51.00019454956055 -871.0003051757812 L 50.91555023193359 -871.0003051757812 L 50.95924377441406 -869.9584350585938 C 50.98640823364258 -869.3101806640625 51.00019454956055 -868.6511840820312 51.00019454956055 -867.9996337890625 C 51.00019454956055 -863.2890014648438 50.29705047607422 -858.6845092773438 48.91031265258789 -854.3140258789062 C 47.57245635986328 -850.0975952148438 45.63679122924805 -846.2112426757812 43.15710067749023 -842.762939453125 C 40.70159912109375 -839.3482666015625 37.79729080200195 -836.479736328125 34.52478790283203 -834.237060546875 C 31.19188499450684 -831.9530029296875 27.58197975158691 -830.3927612304688 23.79533767700195 -829.5997314453125 L 23.00031280517578 -829.4332275390625 L 23.00031280517578 -828.6209716796875 L 23.00031280517578 -764.000244140625 Z\" stroke=\"none\"/><path d=\"M 22.00030326843262 -765.000244140625 L 22.00030326843262 -830.2454833984375 L 23.59035301208496 -830.5784912109375 C 27.24725341796875 -831.3443603515625 30.73592948913574 -832.8528442382812 33.95948028564453 -835.0619506835938 C 37.13617706298828 -837.239013671875 39.95752716064453 -840.0263671875 42.3452033996582 -843.3467407226562 C 44.76315307617188 -846.7091674804688 46.65127944946289 -850.5008544921875 47.9571533203125 -854.616455078125 C 49.31282806396484 -858.8890380859375 50.00020217895508 -863.3917846679688 50.00020217895508 -867.9996337890625 C 50.00020217895508 -868.6367797851562 49.98670196533203 -869.28173828125 49.96010208129883 -869.9165649414062 L 49.87277984619141 -872.0003051757812 L 50.00020217895508 -872.0003051757812 L 50.00020217895508 -943.9999389648438 L -14.00019645690918 -943.9999389648438 L -14.00019645690918 -872.0003051757812 L -13.87279605865479 -872.0003051757812 L -13.96012115478516 -869.9165649414062 C -13.98672103881836 -869.2821044921875 -14.00019645690918 -868.6371459960938 -14.00019645690918 -867.9996337890625 C -14.00019645690918 -858.5721435546875 -11.067795753479 -849.5285034179688 -5.7431960105896 -842.53466796875 C -0.5214712023735046 -835.676025390625 6.587278842926025 -831.3150634765625 14.2736291885376 -830.255126953125 L 16.00040435791016 -830.0169677734375 L 16.00040435791016 -765.000244140625 L 22.00030326843262 -765.000244140625 M 24.00030326843262 -763.000244140625 L 14.00040340423584 -763.000244140625 L 14.00040340423584 -828.2738647460938 C -2.891846179962158 -830.6033325195312 -16.00019645690918 -847.5006103515625 -16.00019645690918 -867.9996337890625 C -16.00019645690918 -868.6710815429688 -15.98617076873779 -869.3369750976562 -15.95837116241455 -870.0003051757812 L -16.00019645690918 -870.0003051757812 L -16.00019645690918 -945.9999389648438 L 52.00020217895508 -945.9999389648438 L 52.00020217895508 -870.0003051757812 L 51.95835494995117 -870.0003051757812 C 51.98615264892578 -869.3369750976562 52.00020217895508 -868.6710815429688 52.00020217895508 -867.9996337890625 C 52.00020217895508 -848.31640625 39.91687774658203 -831.954345703125 24.00030326843262 -828.6209716796875 L 24.00030326843262 -763.000244140625 Z\" stroke=\"none\" fill=\"#707070\"/></g></g><path id=\"Subtraction_2\" data-name=\"Subtraction 2\" d=\"M47.5,115a30.561,30.561,0,0,1-12.343-2.585A31.884,31.884,0,0,1,24.982,105.3a33.5,33.5,0,0,1-6.928-10.656A34.548,34.548,0,0,1,15.5,81.524c0-.564.014-1.133.04-1.689L15.628,78H15.5V41h64V78h-.128l.087,1.835c.027.556.04,1.124.04,1.689a34.548,34.548,0,0,1-2.554,13.12A33.505,33.505,0,0,1,70.018,105.3a31.891,31.891,0,0,1-10.175,7.115A30.568,30.568,0,0,1,47.5,115Z\" transform=\"translate(184.375 75.949)\" fill=\"#601717\" stroke=\"#707070\" stroke-width=\"4\"/></g></g></g><g id=\"Group_281\" data-name=\"Group 281\" transform=\"translate(27.501 22)\"><g transform=\"matrix(1, 0, 0, 1, -27.5, -22)\" filter=\"url(#Union_3)\"><g id=\"Union_3-2\" data-name=\"Union 3\" transform=\"translate(55.5 1103.5)\" fill=\"#e3e3d8\" stroke-linecap=\"square\" stroke-linejoin=\"round\"><path d=\"M 49.17959976196289 -812 L -6.46740198135376 -812 C -8.007511138916016 -812 -10.01192951202393 -812.6729125976562 -11.5739107131958 -813.7142944335938 C -13.09318351745605 -814.7271728515625 -14.00020217895508 -815.95556640625 -14.00020217895508 -817.000244140625 C -14.00020217895508 -817.244873046875 -14.00127506256104 -817.4866333007812 -14.00232887268066 -817.724853515625 C -14.00436592102051 -818.1821899414062 -14.00627422332764 -818.6141357421875 -14.00040149688721 -819.0253295898438 L -14.00020217895508 -819.0396118164062 L -14.00020217895508 -819.0538940429688 L -14.00020217895508 -926.9998168945312 L -12.68905639648438 -926.9998168945312 L -13.95243835449219 -929.8179321289062 C -14.00020217895508 -929.9244995117188 -14.00020217895508 -929.9810791015625 -14.00020217895508 -929.9996948242188 C -14.00020217895508 -930.013427734375 -13.99903869628906 -930.0280151367188 -13.99676513671875 -930.0429077148438 L -13.96145629882812 -930.2738037109375 L -13.98031139373779 -930.506591796875 C -13.99351119995117 -930.669677734375 -14.00020217895508 -930.8355102539062 -14.00020217895508 -930.9996337890625 L -14.00020217895508 -935.0001220703125 C -14.00020217895508 -938.30859375 -11.30856513977051 -941.000244140625 -8.000092506408691 -941.000244140625 L 48.99959945678711 -941.000244140625 C 52.30807113647461 -941.000244140625 54.99970626831055 -938.30859375 54.99970626831055 -935.0001220703125 L 54.99970626831055 -930.9996337890625 C 54.99970626831055 -930.8355102539062 54.99301528930664 -930.669677734375 54.97981643676758 -930.5066528320312 L 54.96096038818359 -930.2738647460938 L 54.99625396728516 -930.0430297851562 C 54.99854278564453 -930.0280151367188 54.99970626831055 -930.013427734375 54.99970626831055 -929.9996948242188 C 54.99970626831055 -929.9810791015625 54.99970626831055 -929.9244995117188 54.95192718505859 -929.81787109375 L 53.68872451782227 -926.9998168945312 L 54.99970626831055 -926.9998168945312 L 54.99970626831055 -818.9274291992188 L 54.99970626831055 -818.9151611328125 L 54.99985122680664 -818.90283203125 C 55.00465393066406 -818.5135498046875 55.00308990478516 -818.1072998046875 55.00143432617188 -817.67724609375 C 55.00057983398438 -817.4544067382812 54.99970626831055 -817.2285766601562 54.99970626831055 -817.000244140625 C 54.99970626831055 -815.3341064453125 53.89377975463867 -814.1334838867188 53.23456192016602 -813.5661010742188 C 52.09516143798828 -812.58544921875 50.57928848266602 -812 49.17959976196289 -812 Z\" stroke=\"none\"/><path d=\"M 49.17961120605469 -814 C 50.11458969116211 -814 51.14273071289062 -814.4044799804688 51.92991256713867 -815.0819702148438 C 52.25157165527344 -815.3588256835938 52.99971008300781 -816.0999145507812 52.99971008300781 -817.000244140625 C 52.99971008300781 -817.231201171875 53.00057220458984 -817.4595947265625 53.00144958496094 -817.6849365234375 C 53.00307083129883 -818.1067504882812 53.00458908081055 -818.505126953125 53.0000114440918 -818.8782958984375 C 52.99980926513672 -818.8946533203125 52.99971008300781 -818.9110717773438 52.99971008300781 -818.9274291992188 L 52.99971008300781 -927.683349609375 C 52.71316909790039 -928.5056762695312 52.70121383666992 -929.4052124023438 52.97463226318359 -930.2418823242188 C 52.97096252441406 -930.3838500976562 52.974853515625 -930.5260620117188 52.98633193969727 -930.6679077148438 C 52.99521255493164 -930.7776489257812 52.99971008300781 -930.8892211914062 52.99971008300781 -930.9996337890625 L 52.99971008300781 -935.0001220703125 C 52.99971008300781 -937.205810546875 51.20527267456055 -939.000244140625 48.99959182739258 -939.000244140625 L -8.000088691711426 -939.000244140625 C -10.20574951171875 -939.000244140625 -12.00018882751465 -937.205810546875 -12.00018882751465 -935.0001220703125 L -12.00018882751465 -930.9996337890625 C -12.00018882751465 -930.88916015625 -11.99568939208984 -930.7776489257812 -11.98682880401611 -930.6681518554688 C -11.97532844543457 -930.5262451171875 -11.97142887115479 -930.3839111328125 -11.9751033782959 -930.2418212890625 C -11.70168495178223 -929.4050903320312 -11.71364879608154 -928.5057373046875 -12.00018882751465 -927.6834106445312 L -12.00018882751465 -819.0538940429688 C -12.00018882751465 -819.0347900390625 -12.00032901763916 -819.0156860351562 -12.00058937072754 -818.9966430664062 C -12.00620937347412 -818.604248046875 -12.00432872772217 -818.1814575195312 -12.00234889984131 -817.7337646484375 C -12.00126934051514 -817.4926147460938 -12.00018882751465 -817.2479248046875 -12.00022888183594 -817.0020751953125 C -11.98752880096436 -816.8250732421875 -11.57782936096191 -816.0968017578125 -10.37110900878906 -815.3170776367188 C -8.963068962097168 -814.4072875976562 -7.395909309387207 -814 -6.467389106750488 -814 L 49.17961120605469 -814 M 49.17961120605469 -810 L -6.467389106750488 -810 C -10.33290958404541 -810 -16.00018882751465 -813.1338500976562 -16.00018882751465 -817.000244140625 C -16.00018882751465 -817.71484375 -16.00948905944824 -818.4043579101562 -16.00018882751465 -819.0538940429688 L -16.00018882751465 -928.9998168945312 L -15.77744960784912 -928.9998168945312 C -15.92460918426514 -929.328125 -16.00018882751465 -929.6617431640625 -16.00018882751465 -929.9996948242188 C -16.00018882751465 -930.1152954101562 -15.99128913879395 -930.230712890625 -15.97376918792725 -930.34521484375 C -15.99124908447266 -930.56103515625 -16.00018882751465 -930.779296875 -16.00018882751465 -930.9996337890625 L -16.00018882751465 -935.0001220703125 C -16.00018882751465 -939.418212890625 -12.41820907592773 -943.000244140625 -8.000088691711426 -943.000244140625 L 48.99959182739258 -943.000244140625 C 53.41860961914062 -943.000244140625 56.99971008300781 -939.418212890625 56.99971008300781 -935.0001220703125 L 56.99971008300781 -930.9996337890625 C 56.99971008300781 -930.779296875 56.99074935913086 -930.5609741210938 56.97328948974609 -930.34521484375 C 56.99081039428711 -930.2306518554688 56.99971008300781 -930.1152954101562 56.99971008300781 -929.9996948242188 C 56.99971008300781 -929.6617431640625 56.92411041259766 -929.328125 56.77695083618164 -928.9998168945312 L 56.99971008300781 -928.9998168945312 L 56.99971008300781 -818.9274291992188 C 57.00723266601562 -818.315185546875 56.99971008300781 -817.6686401367188 56.99971008300781 -817.000244140625 C 56.99971008300781 -813.1338500976562 53.04511260986328 -810 49.17961120605469 -810 Z\" stroke=\"none\" fill=\"#707070\"/></g></g><g id=\"Ellipse_22\" data-name=\"Ellipse 22\" transform=\"translate(14 138.5)\" fill=\"#fff\" stroke=\"#707070\" stroke-width=\"2\"><ellipse cx=\"34.5\" cy=\"3\" rx=\"34.5\" ry=\"3\" stroke=\"none\"/><ellipse cx=\"34.5\" cy=\"3\" rx=\"33.5\" ry=\"2\" fill=\"none\"/></g><path id=\"Path_122\" data-name=\"Path 122\" d=\"M69,1101.79c7.513.587,10.555,2.371,16.771,2.713,53.288,2.927,54.23-4.771,54.23-4.771\" transform=\"translate(-57 -948.5)\" fill=\"none\" stroke=\"#707070\" stroke-width=\"4\"/><text id=\"Beer\" transform=\"translate(47 199)\" fill=\"#6c6464\" font-size=\"26\" font-family=\"New York\"><tspan x=\"-27.212\" y=\"0\">Beer</tspan></text></g></g></svg>'

define DrinkingPeer:
  if MaleAtBirth and AgeInYears() <= 65 then Tuple {
    title: 'Low Risk Drinking Limits',
    group: 'men 65 years or younger',
    drinks_per_week: 14,
    drinks_per_day: 4
  }
  else if MaleAtBirth and AgeInYears() > 65 then {
    title: 'Low Risk Drinking Limits',
    group: 'men over 65 years of age',
    drinks_per_week: 7,
    drinks_per_day: 3
  }
  else Tuple {
    title: 'Low Risk Drinking Limits',
    group: 'women',
    drinks_per_week: 7,
    drinks_per_day: 3
  }

define DrinkingPeerText:
  if (
      PregnantAndNotDrinking or
      PregnantAndDrinking
    ) then ''
  else 'Here\'s how your drinking compares to recommended limits for low-risk drinking levels for '
    + DrinkingPeer.group

define DrinkFrequencyInterval:
  if AuditVariant = 'USAUDIT' then (
    if QuestionOneResponse = 'Never' then Interval[0, 0]
    else if QuestionOneResponse = 'Less than monthly' then Interval(0, 0.25)
    else if QuestionOneResponse = 'Monthly' then Interval[0.25, 0.25]
    else if QuestionOneResponse = 'Weekly' then Interval[1, 1]
    else if QuestionOneResponse = '2-3 times a week' then Interval[2, 3]
    else if QuestionOneResponse = '4-6 times a week' then Interval[4, 6]
    else if QuestionOneResponse = 'Daily' then Interval[7, 7]
    else Interval[0, 0]
  )
  else if AuditVariant = 'AUDIT' then (
    if QuestionOneResponse = 'Never' then Interval[0, 0]
    else if QuestionOneResponse = 'Monthly or less' then Interval(0, 0.25)
    else if QuestionOneResponse = '2-4 times a month' then Interval[0.5, 1]
    else if QuestionOneResponse = '2-3 times a week' then Interval[2, 3]
    else if QuestionOneResponse = '4 or more times a week' then Interval[4, 7]
    else Interval[0, 0]
  )
  else Interval[0, 0]

define TypicalDrinkingAmount:
  if AuditVariant = 'USAUDIT' then (
    if QuestionTwoResponse = '1 drink' then Interval[1, 1]
    else if QuestionTwoResponse = '2 drinks' then Interval[2, 2]
    else if QuestionTwoResponse = '3 drinks' then Interval[3, 3]
    else if QuestionTwoResponse = '4 drinks' then Interval[4, 4]
    else if QuestionTwoResponse = '5-6 drinks' then Interval[5, 6]
    else if QuestionTwoResponse = '7-8 drinks times a week' then Interval[7, 8]
    else if QuestionTwoResponse = '10 or more drinks' then Interval[10, 10]
    else Interval[0, 0]
  )
  else if AuditVariant = 'AUDIT' then (
    if QuestionTwoResponse = '1 or 2' then Interval[1, 2]
    else if QuestionTwoResponse = '3 or 4' then Interval[3, 4]
    else if QuestionTwoResponse = '5 or 6' then Interval[5, 6]
    else if QuestionTwoResponse = '7 to 9' then Interval[7, 9]
    else if QuestionTwoResponse = '10 or more' then Interval[10, 10]
    else Interval[0, 0]
  )
  else Interval[0, 0]
    
define DrinkingPeerTable:
  if (
      PregnantAndNotDrinking or
      PregnantAndDrinking
    ) then null
  else Tuple{
    you: Tuple{
      title: 'Your Drinking',
      drinks_per_week: Tuple {
        lower: start of TypicalDrinkingAmount * start of DrinkFrequencyInterval,
        upper: end of TypicalDrinkingAmount * end of DrinkFrequencyInterval
      },
      drinks_per_day: Tuple {
        lower: start of TypicalDrinkingAmount,
        upper: end of TypicalDrinkingAmount
      }
    },
    peer: DrinkingPeer
  }

define ReinforceKeyInformation:
  Tuple{
    instructions: Tuple{
      title: ReinforceKeyInformationInstructionsTitle,
      text: ReinforceKeyInformationInstructionsText
    },
    content: Tuple{
      part1: ReinforcementIntroduction,
      part2: DrinkSizeGraphic,
      part3: DrinkingPeerText,
      part4: DrinkingPeerTable
    }
  }

// 3. Discuss Patient Responses to Alcohol Screening

define DiscussResponsesInstructionsTitle:
  if (
    RespondedToQuestionFour or
    RespondedToQuestionFive or
    RespondedToQuestionSix or
    RespondedToQuestionSeven or
    RespondedToQuestionEight
  ) then 'Discuss the patient\'s responses to questions 4-10'
  else if (
    RespondedToQuestionNine or
    RespondedToQuestionTen
  ) then 'Discuss the patient\'s responses to questions 9-10'
  else ''

define DiscussResponsesInstructionsText:
  'Discuss the patient\'s response to any screening question that may indicate particular concern about alcohol dependence symptoms or past problems with alcohol. Ask the patient how they feel about their responses.'

define DiscussResponsesIntroduction:
  'Let\'s discuss your responses to these screening questions'

define Responses4to6:
  if (
    RespondedToQuestionFour or
    RespondedToQuestionFive or
    RespondedToQuestionSix
  ) then
    Tuple {
      response4: '**' + QuestionFourResponse + '** - found that you were not able to stop drinking once you started',
      response5: '**' + QuestionFiveResponse + '** - failed to do what was normally expected of you because of the drinking',
      response6: '**' + QuestionSixResponse + '** - needed a first drink in the morning to get yourself going after a heavy drinking session',
      context: 'The responses to these three questions could indicate serious issues with alcohol'
    }
  else
    null

define Responses7to8:
  if (
    RespondedToQuestionSeven or
    RespondedToQuestionEight
  ) then
    Tuple {
      response7: '**' + QuestionSevenResponse + '** - you had a feeling of guilt or remorse after drinking',
      response8: '**' + QuestionEightResponse + '** - been unable to remember what happened the night before because you had been drinking',
      context: ''
    }
  else
    null

define Responses9to10:
  if (
    RespondedToQuestionNine or
    RespondedToQuestionTen
  ) then
    Tuple {
      response9: '**' + QuestionNineResponse + '** - you or someone else been injured as a result of your drinking',
      response10: '**' + QuestionTenResponse + '** - a relative or friend, doctor or other health worker has been concerned about your drinking',
      context: 'The responses to these two questions could indicate past problems with alcohol'
    }
  else
    null

define OnlyRespondedToQuestions1to3:
  Responses4to6 is null and
  Responses7to8 is null and
  Responses9to10 is null

define DiscussResponses:
  if (
    PregnantAndNotDrinking or
    PregnantAndDrinking or
    OnlyRespondedToQuestions1to3
    ) then null
  else Tuple {
    instructions: Tuple {
      title: DiscussResponsesInstructionsTitle,
      text: DiscussResponsesInstructionsText
    },
    content: Tuple {
      part1: DiscussResponsesIntroduction,
      part2: Responses4to6,
      part3: Responses7to8,
      part4: Responses9to10
    }
  }

// 4. Provide Education on When To Avoid Alcohol

define ProvideEducationInstructionsTitle:
  'Provide education on when to avoid drinking alcohol'

define ProvideEducationInstructionsText:
  'Provide education regarding when the patient should avoid drinking alcohol, based on relevant patient factors.'

define ProvideEducationContent:
  '**You should avoid drinking alcohol if you are:**\n'
    + '- Taking medications that interact with alcohol\n'
    + '- Planning to drive or operate machinery\n'
    + '- Managing a medical condition that may be made worse by drinking\n'
    + '- Pregnant or trying to become pregnant'

define ProvideEducation:
  if (
    PregnantAndNotDrinking or
    PregnantAndDrinking
    ) then null
  else Tuple {
    instructions: Tuple {
      title: ProvideEducationInstructionsTitle,
      text: ProvideEducationInstructionsText
    },
    content: ProvideEducationContent
  }

// 5. Offer Appropriate Follow-Up

define AppropriateFollowUpInstructionsTitle:
  if IsZoneFourDrinker then
    'Discuss referral to specialist with the patient'
  else
    'Offer an appropriate follow-up visit with the patient'

define AppropriateFollowUpInstructionsText:
  if PregnantAndDrinking then
    'If you think the patient may be unable to reduce or eliminate their alcohol use, or may be dependent on alcohol, consider referring the patient for diagnostic evaluation and possible treatment of alcohol use disorder.'
  else if IsZoneFourDrinker then
    'Discuss the need for referral to a specialist with the patient, and encourage the patient to see a specialist. Consider offering a follow-up visit to the patient.'
  else if IsZoneThreeDrinker then
    'If you think the patient may be dependent on alcohol, consider referring the patient for diagnostic evaluation and possible treatment of alcohol use disorder.'
  else if PregnantAndNotDrinking or IsZoneOneDrinker or IsZoneTwoDrinker then
    ''
  else
    ''

define AppropriateFollowUpContent:
  if PregnantAndDrinking then
    '**I\'d like to follow-up with you [at your next visit; in 3 months; other preferred timeline].**\n'
      + '\n'
      + '**OR**\n'
      + '\n'
      + '**I\'d like you to consider seeing a specialist that can help you with your drinking.**'
  else if IsZoneFourDrinker then
    '**I\'d like you to consider seeing a specialist that can help you with your drinking.**\n'
      + '\n'
      + '**OR**\n'
      + '\n'
      + '**I\'d like to follow-up with you [at your next visit; in 3 months; other preferred timeline].**'
  else if IsZoneThreeDrinker then
    '**I\'d like to follow-up with you [at your next visit; in 3 months; other preferred timeline].**\n'
      + '\n'
      + '**OR**\n'
      + '\n'
      + '**I\'d like you to consider seeing a specialist that can help you with your drinking.**'
  else if PregnantAndNotDrinking or IsZoneOneDrinker or IsZoneTwoDrinker then
    'No follow-up indicated, based on your screening results.'
  else
    ''

define AppropriateFollowUp:
  Tuple {
    instructions: Tuple {
      title: AppropriateFollowUpInstructionsTitle,
      text: AppropriateFollowUpInstructionsText
    },
    content: AppropriateFollowUpContent
  }

// 6. Share Patient Education Resources

define ShareResourcesInstructionsTitle:
  'Share patient education resources'

define ShareResourcesInstructionsText:
  ''

define ShareResourcesContent:
  if PregnantAndDrinking then
    '**If you\'d like to learn more about the impact of drinking during pregnancy, this information can help:**\n'
      + '- 5 Things You Should Know About Drinking Alcohol During Pregnancy: [https://www.cdc.gov/ncbddd/fasd/women.html](https://www.cdc.gov/ncbddd/fasd/women.html)\n'
      + '- Alcohol Use in Pregnancy: [https://www.cdc.gov/ncbddd/fasd/alcohol-use.html](https://www.cdc.gov/ncbddd/fasd/alcohol-use.html)\n'
      + '- Fact Sheet on Fetal Alcohol Spectrum Disorders (FASDS): [https://www.cdc.gov/ncbddd/fasd/documents/fasd_english-508.pdf](https://www.cdc.gov/ncbddd/fasd/documents/fasd_english-508.pdf)\n'
      + '- An Alcohol-Free Pregnancy is the Best Choice for Your Baby (brochure): [https://www.cdc.gov/ncbddd/fasd/documents/FASDBrochure_final-508.pdf](https://www.cdc.gov/ncbddd/fasd/documents/FASDBrochure_final-508.pdf)'
  else if PregnantAndNotDrinking then
    '**If you\'d like to learn more about the impact of drinking during pregnancy, this information can help:**\n'
      + '- Find out more about “Alcohol Use in Pregnancy”: [https://www.cdc.gov/ncbddd/fasd/alcohol-use.html](https://www.cdc.gov/ncbddd/fasd/alcohol-use.html)\n'
      + '- Fact Sheet on Fetal Alcohol Spectrum Disorders (FASDS): [https://www.cdc.gov/ncbddd/fasd/documents/fasd_english-508.pdf](https://www.cdc.gov/ncbddd/fasd/documents/fasd_english-508.pdf)\n'
      + '- An Alcohol-Free Pregnancy is the Best Choice for Your Baby (brochure): [https://www.cdc.gov/ncbddd/fasd/documents/FASDBrochure_final-508.pdf](https://www.cdc.gov/ncbddd/fasd/documents/FASDBrochure_final-508.pdf)\n'
  else if IsZoneFourDrinker then
    '**You may want to explore these tools and information that could help you cut down on your drinking:**\n'
      + '- Treatment for Alcohol Problems: Finding and Getting Help: [https://www.niaaa.nih.gov/publications/brochures-and-fact-sheets/treatment-alcohol-problems-finding-and-getting-help](https://www.niaaa.nih.gov/publications/brochures-and-fact-sheets/treatment-alcohol-problems-finding-and-getting-help)\n'
      + '- Find Your Way to Alcohol Treatment (NIAAA Alcohol Treatment Navigator): [https://alcoholtreatment.niaaa.nih.gov/](https://alcoholtreatment.niaaa.nih.gov/)\n'
      + '- Find Treatment for Substance Use Disorder: [https://findtreatment.gov/](https://findtreatment.gov/)'
  else if IsZoneThreeDrinker then
    '**You may want to explore these tools and information that could help you cut down on your drinking:**\n'
      + '- Rethinking Drinking: Alcohol & Your Health: [https://www.rethinkingdrinking.niaaa.nih.gov/](https://www.rethinkingdrinking.niaaa.nih.gov/)\n'
      + '- Alcohol Use And Your Health: [https://www.cdc.gov/alcohol/fact-sheets/alcohol-use.htm](https://www.cdc.gov/alcohol/fact-sheets/alcohol-use.htm)\n'
      + '- Find Your Way to Alcohol Treatment (NIAAA Alcohol Treatment Navigator): [https://alcoholtreatment.niaaa.nih.gov/](https://alcoholtreatment.niaaa.nih.gov/)\n'
      + '- Find Treatment for Substance Use Disorder: [https://findtreatment.gov/](https://findtreatment.gov/)'
  else if IsZoneTwoDrinker then
    '**You may want to explore these tools and information about drinking alcohol:**\n'
      + '- Rethinking Drinking: Alcohol & Your Health: [https://www.rethinkingdrinking.niaaa.nih.gov/](https://www.rethinkingdrinking.niaaa.nih.gov/)\n'
      + '- Alcohol Use And Your Health: [https://www.cdc.gov/alcohol/fact-sheets/alcohol-use.htm](https://www.cdc.gov/alcohol/fact-sheets/alcohol-use.htm)'
  else if IsZoneOneDrinker then
    '**You may want to explore these tools and information about drinking alcohol:**\n'
      + '- What Is A Standard Drink?: [https://www.niaaa.nih.gov/alcohols-effects-health/overview-alcohol-consumption/what-standard-drink](https://www.niaaa.nih.gov/alcohols-effects-health/overview-alcohol-consumption/what-standard-drink)\n'
      + '- Alcohol Use And Your Health: [https://www.cdc.gov/alcohol/fact-sheets/alcohol-use.htm](https://www.cdc.gov/alcohol/fact-sheets/alcohol-use.htm)'
  else
    ''

define ShareResources:
  Tuple {
    instructions: Tuple {
      title: ShareResourcesInstructionsTitle,
      text: ShareResourcesInstructionsText
    },
    content: ShareResourcesContent
  }

define EvidenceBasedBriefIntervention:
  Tuple {
    general_guidance: GeneralGuidance,
    provide_feedback: ProvideFeedback,
    reinforce_key_information: ReinforceKeyInformation,
    discuss_responses: DiscussResponses,
    provide_education: ProvideEducation,
    appropriate_follow_up: AppropriateFollowUp,
    share_resources: ShareResources
  }

define AlcoholTreatmentReferralSuggested:
  if DisplayNotification and (IsZoneThreeDrinker or IsZoneFourDrinker or PregnantAndDrinking) then true
  else false

//------------------------------------------------------------------------------
// NON-ALCOHOL-RELATED NIDA QS RESULTS
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
  where QT.id = RV.id 
    and (RV.answer as FHIR.Coding).display is not null
    and QT.question is not null
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
// NON-ALCOHOL-RELATED COUNSELING SUGGESTIONS
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
// NON-ALCOHOL-RELATED PATIENT EDUCATION RESOURCES
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