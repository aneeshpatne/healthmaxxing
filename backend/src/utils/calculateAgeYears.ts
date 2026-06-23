export function calculateAgeYears(
  dateOfBirth: string,
  referenceDate: Date = new Date(),
): number {
  const birthDate = new Date(dateOfBirth);
  let age = referenceDate.getUTCFullYear() - birthDate.getUTCFullYear();
  const birthdayThisYear = new Date(
    Date.UTC(
      referenceDate.getUTCFullYear(),
      birthDate.getUTCMonth(),
      birthDate.getUTCDate(),
    ),
  );

  if (referenceDate < birthdayThisYear) {
    age -= 1;
  }

  return age;
}
