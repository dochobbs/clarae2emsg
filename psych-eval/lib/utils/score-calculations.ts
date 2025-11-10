/**
 * Score calculation utilities for psychoeducational assessments
 * Implements normative data lookups and standard score conversions
 */

export interface RawScore {
  subtest: string;
  rawScore: number;
}

export interface StandardScore {
  subtest: string;
  rawScore: number;
  standardScore: number;
  percentile: number;
  confidenceInterval?: [number, number];
  descriptiveCategory: string;
}

export interface CompositeScore {
  name: string;
  standardScore: number;
  percentile: number;
  confidenceInterval?: [number, number];
  descriptiveCategory: string;
}

/**
 * Get descriptive category from standard score
 */
export function getDescriptiveCategory(standardScore: number): string {
  if (standardScore >= 130) return 'Very Superior';
  if (standardScore >= 120) return 'Superior';
  if (standardScore >= 110) return 'High Average';
  if (standardScore >= 90) return 'Average';
  if (standardScore >= 80) return 'Low Average';
  if (standardScore >= 70) return 'Borderline';
  return 'Extremely Low';
}

/**
 * Calculate percentile from standard score (mean=100, SD=15)
 */
export function standardScoreToPercentile(standardScore: number): number {
  // Using approximation of normal distribution
  const z = (standardScore - 100) / 15;
  const percentile = normCdf(z) * 100;
  return Math.round(percentile);
}

/**
 * Calculate confidence interval for standard score
 */
export function calculateConfidenceInterval(
  standardScore: number,
  sem: number = 5,
  confidenceLevel: number = 0.95
): [number, number] {
  // For 95% CI, z-score is 1.96
  // For 90% CI, z-score is 1.645
  const zScore = confidenceLevel === 0.95 ? 1.96 : 1.645;
  const margin = Math.round(zScore * sem);

  return [
    Math.max(40, standardScore - margin),
    Math.min(160, standardScore + margin),
  ];
}

/**
 * Normal cumulative distribution function (CDF)
 * Approximation using error function
 */
function normCdf(z: number): number {
  // Using Abramowitz and Stegun approximation
  const t = 1 / (1 + 0.2316419 * Math.abs(z));
  const d = 0.3989423 * Math.exp(-z * z / 2);
  const prob = d * t * (0.3193815 + t * (-0.3565638 + t * (1.781478 + t * (-1.821256 + t * 1.330274))));

  return z > 0 ? 1 - prob : prob;
}

/**
 * Calculate WISC-V composite scores from subtests
 */
export function calculateWISCComposites(subtestScores: Record<string, number>): CompositeScore[] {
  const composites: CompositeScore[] = [];

  // Verbal Comprehension Index (VCI)
  if (subtestScores['Similarities'] && subtestScores['Vocabulary']) {
    const vciSum = (subtestScores['Similarities'] || 0) +
                   (subtestScores['Vocabulary'] || 0) +
                   (subtestScores['Information'] || 0);
    const vciStandard = convertSumToComposite(vciSum, 'VCI');
    composites.push({
      name: 'Verbal Comprehension Index (VCI)',
      standardScore: vciStandard,
      percentile: standardScoreToPercentile(vciStandard),
      confidenceInterval: calculateConfidenceInterval(vciStandard),
      descriptiveCategory: getDescriptiveCategory(vciStandard),
    });
  }

  // Visual Spatial Index (VSI)
  if (subtestScores['Block Design'] && subtestScores['Visual Puzzles']) {
    const vsiSum = (subtestScores['Block Design'] || 0) + (subtestScores['Visual Puzzles'] || 0);
    const vsiStandard = convertSumToComposite(vsiSum, 'VSI');
    composites.push({
      name: 'Visual Spatial Index (VSI)',
      standardScore: vsiStandard,
      percentile: standardScoreToPercentile(vsiStandard),
      confidenceInterval: calculateConfidenceInterval(vsiStandard),
      descriptiveCategory: getDescriptiveCategory(vsiStandard),
    });
  }

  // Fluid Reasoning Index (FRI)
  if (subtestScores['Matrix Reasoning'] && subtestScores['Figure Weights']) {
    const friSum = (subtestScores['Matrix Reasoning'] || 0) + (subtestScores['Figure Weights'] || 0);
    const friStandard = convertSumToComposite(friSum, 'FRI');
    composites.push({
      name: 'Fluid Reasoning Index (FRI)',
      standardScore: friStandard,
      percentile: standardScoreToPercentile(friStandard),
      confidenceInterval: calculateConfidenceInterval(friStandard),
      descriptiveCategory: getDescriptiveCategory(friStandard),
    });
  }

  // Working Memory Index (WMI)
  if (subtestScores['Digit Span'] && subtestScores['Picture Span']) {
    const wmiSum = (subtestScores['Digit Span'] || 0) + (subtestScores['Picture Span'] || 0);
    const wmiStandard = convertSumToComposite(wmiSum, 'WMI');
    composites.push({
      name: 'Working Memory Index (WMI)',
      standardScore: wmiStandard,
      percentile: standardScoreToPercentile(wmiStandard),
      confidenceInterval: calculateConfidenceInterval(wmiStandard),
      descriptiveCategory: getDescriptiveCategory(wmiStandard),
    });
  }

  // Processing Speed Index (PSI)
  if (subtestScores['Coding'] && subtestScores['Symbol Search']) {
    const psiSum = (subtestScores['Coding'] || 0) + (subtestScores['Symbol Search'] || 0);
    const psiStandard = convertSumToComposite(psiSum, 'PSI');
    composites.push({
      name: 'Processing Speed Index (PSI)',
      standardScore: psiStandard,
      percentile: standardScoreToPercentile(psiStandard),
      confidenceInterval: calculateConfidenceInterval(psiStandard),
      descriptiveCategory: getDescriptiveCategory(psiStandard),
    });
  }

  // Full Scale IQ (FSIQ) - requires at least 3 primary subtests per index for most accurate
  const coreSubtests = [
    'Similarities', 'Vocabulary', 'Block Design', 'Visual Puzzles',
    'Matrix Reasoning', 'Figure Weights', 'Digit Span', 'Coding'
  ];
  const coreSum = coreSubtests.reduce((sum, test) => sum + (subtestScores[test] || 0), 0);

  if (coreSum > 0) {
    const fsiqStandard = convertSumToComposite(coreSum, 'FSIQ');
    composites.push({
      name: 'Full Scale IQ (FSIQ)',
      standardScore: fsiqStandard,
      percentile: standardScoreToPercentile(fsiqStandard),
      confidenceInterval: calculateConfidenceInterval(fsiqStandard, 3),
      descriptiveCategory: getDescriptiveCategory(fsiqStandard),
    });
  }

  return composites;
}

/**
 * Convert sum of scaled scores to composite standard score
 * This is a simplified lookup - real implementation would use actual normative tables
 */
function convertSumToComposite(sum: number, compositeType: string): number {
  // Simplified conversion (actual would use age-normed tables)
  // Each subtest has mean=10, SD=3
  // Composite has mean=100, SD=15

  const expectedSubtests = getExpectedSubtestsCount(compositeType);
  const expectedMean = expectedSubtests * 10;
  const expectedSD = Math.sqrt(expectedSubtests) * 3;

  const zScore = (sum - expectedMean) / expectedSD;
  const composite = Math.round(100 + (zScore * 15));

  // Clamp to valid range
  return Math.max(40, Math.min(160, composite));
}

function getExpectedSubtestsCount(compositeType: string): number {
  switch (compositeType) {
    case 'VCI': return 3;
    case 'VSI': return 2;
    case 'FRI': return 2;
    case 'WMI': return 2;
    case 'PSI': return 2;
    case 'FSIQ': return 7;
    default: return 2;
  }
}

/**
 * Calculate age from date of birth
 */
export function calculateAge(dob: Date, testDate: Date = new Date()): { years: number; months: number } {
  let years = testDate.getFullYear() - dob.getFullYear();
  let months = testDate.getMonth() - dob.getMonth();

  if (months < 0) {
    years--;
    months += 12;
  }

  return { years, months };
}

/**
 * Analyze score scatter (variability across subtests)
 */
export function analyzeScoreScatter(scores: number[]): {
  range: number;
  mean: number;
  sd: number;
  isSignificantScatter: boolean;
} {
  if (scores.length === 0) {
    return { range: 0, mean: 0, sd: 0, isSignificantScatter: false };
  }

  const mean = scores.reduce((a, b) => a + b, 0) / scores.length;
  const variance = scores.reduce((sum, score) => sum + Math.pow(score - mean, 2), 0) / scores.length;
  const sd = Math.sqrt(variance);
  const range = Math.max(...scores) - Math.min(...scores);

  // Significant scatter if range > 4-5 points (1+ SD for scaled scores)
  const isSignificantScatter = range >= 5;

  return { range, mean, sd, isSignificantScatter };
}
