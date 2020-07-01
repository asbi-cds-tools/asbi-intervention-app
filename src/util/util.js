
export function getCurrentISODate() {
  let now = new Date(Date.now()); // Date.now() returns [millisecods]
  let timeZoneCorrection = now.getTimezoneOffset() * 60 * 1000; // [minutes] * [seconds/minutes] * [milliseconds/second]
  let correctedDate = new Date(now.getTime() - timeZoneCorrection);
  return correctedDate.toISOString().split('T')[0]; // just the date portion
}

export function getObservationCategories() {
  return [
    'social-history',
    'vital-signs',
    'imaging',
    'laboratory',
    'procedure',
    'survey',
    'exam',
    'therapy',
    'activity'
  ]
}
