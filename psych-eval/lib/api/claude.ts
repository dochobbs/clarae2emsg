import Anthropic from '@anthropic-ai/sdk';

const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY || '',
});

export interface ReportGenerationParams {
  studentInfo: {
    name: string;
    age: number;
    grade: string;
    dateOfBirth: string;
  };
  referralReason: string;
  assessmentResults: Array<{
    testName: string;
    scores: any;
    observations: string;
  }>;
  backgroundInfo?: string;
  reportType: string;
}

/**
 * Generate report section using Claude API
 * NOTE: This uses de-identified data and client-provided data
 * Ensure BAA is in place with Anthropic
 */
export async function generateReportSection(
  section: string,
  params: ReportGenerationParams,
  context?: string
): Promise<string> {
  try {
    const prompt = buildPromptForSection(section, params, context);

    const message = await anthropic.messages.create({
      model: 'claude-3-5-sonnet-20241022',
      max_tokens: 4096,
      temperature: 0.7,
      messages: [
        {
          role: 'user',
          content: prompt,
        },
      ],
    });

    const content = message.content[0];
    if (content.type === 'text') {
      return content.text;
    }

    return '';
  } catch (error) {
    console.error('Claude API error:', error);
    throw new Error('Failed to generate report section');
  }
}

/**
 * Build prompts for different report sections
 */
function buildPromptForSection(
  section: string,
  params: ReportGenerationParams,
  context?: string
): string {
  const baseContext = `You are an expert school psychologist writing a ${params.reportType}.
Write in a professional, objective, and strength-based tone. Focus on clinical interpretation and educational implications.`;

  switch (section) {
    case 'background':
      return `${baseContext}

Write the "Background Information" section for this evaluation:

Student: ${params.studentInfo.name}, ${params.studentInfo.age} years old, Grade ${params.studentInfo.grade}
Reason for Referral: ${params.referralReason}
${params.backgroundInfo ? `Additional Background: ${params.backgroundInfo}` : ''}

Write 2-3 paragraphs covering relevant developmental, educational, and social-emotional history. ${context || ''}`;

    case 'observations':
      return `${baseContext}

Write the "Behavioral Observations" section based on these observations:

${params.assessmentResults.map(r => `${r.testName}: ${r.observations}`).join('\n')}

Synthesize these observations into 1-2 cohesive paragraphs describing the student's test-taking behavior, engagement, attention, and rapport.`;

    case 'interpretation':
      return `${baseContext}

Write a detailed interpretation of these assessment results:

${JSON.stringify(params.assessmentResults, null, 2)}

For each assessment:
1. Describe the scores in clinical terms
2. Explain what they mean for the student's functioning
3. Note any significant patterns or discrepancies
4. Discuss educational implications

Write in narrative form, organized by cognitive domain (e.g., Cognitive Ability, Academic Achievement, Social-Emotional Functioning).`;

    case 'summary':
      return `${baseContext}

Write a comprehensive "Summary" section that synthesizes these findings:

Referral Reason: ${params.referralReason}
Assessment Results: ${JSON.stringify(params.assessmentResults, null, 2)}

Provide:
1. Brief overview of reason for evaluation
2. Key findings across all domains
3. Pattern analysis (strengths and areas of concern)
4. Response to referral question
5. Clinical impressions

Write 2-4 paragraphs in narrative form.`;

    case 'diagnostic_impressions':
      return `${baseContext}

Based on these assessment results, provide diagnostic impressions:

${JSON.stringify(params.assessmentResults, null, 2)}

Consider DSM-5-TR criteria when relevant. If data suggests a specific diagnosis, explain the evidence. If data is insufficient or doesn't meet criteria, state that clearly.

Format:
1. List diagnostic impressions with justification
2. Rule out any differential diagnoses
3. Note any areas requiring further evaluation

Be conservative and evidence-based. Only suggest diagnoses supported by the data.`;

    case 'recommendations':
      return `${baseContext}

Generate comprehensive, specific recommendations based on these results:

Student Profile: ${params.studentInfo.age} years, Grade ${params.studentInfo.grade}
Assessment Results: ${JSON.stringify(params.assessmentResults, null, 2)}

Provide recommendations in these categories:
1. Academic Interventions (specific strategies)
2. Classroom Accommodations (504/IEP eligible)
3. Social-Emotional Supports
4. Parent/Family Strategies
5. Further Evaluation (if needed)

Make each recommendation:
- Specific and actionable
- Evidence-based
- Age-appropriate
- Aligned with identified needs

Format as bullet points within each category.`;

    default:
      return `${baseContext}\n\nGenerate content for: ${section}\n\n${context || ''}`;
  }
}

/**
 * Generate suggestions for appropriate assessments based on referral
 */
export async function suggestAssessments(referralReason: string, age: number, grade: string): Promise<string[]> {
  try {
    const message = await anthropic.messages.create({
      model: 'claude-3-5-sonnet-20241022',
      max_tokens: 1024,
      temperature: 0.5,
      messages: [
        {
          role: 'user',
          content: `As a school psychologist, suggest appropriate assessment tools for this referral:

Age: ${age} years
Grade: ${grade}
Referral Concern: ${referralReason}

List 5-7 specific, commonly-used assessment instruments that would be appropriate. Include cognitive, achievement, and social-emotional measures as relevant.

Format your response as a simple list, one test per line, with just the test name (e.g., "WISC-V", "WIAT-4").`,
        },
      ],
    });

    const content = message.content[0];
    if (content.type === 'text') {
      // Parse the response into an array
      return content.text
        .split('\n')
        .map(line => line.trim())
        .filter(line => line && !line.includes(':'));
    }

    return [];
  } catch (error) {
    console.error('Assessment suggestion error:', error);
    return [];
  }
}

/**
 * Generate complete report in one call (alternative approach)
 */
export async function generateCompleteReport(params: ReportGenerationParams): Promise<{
  background: string;
  observations: string;
  interpretation: string;
  summary: string;
  diagnosticImpressions: string;
  recommendations: string;
}> {
  // Generate all sections in parallel for efficiency
  const [background, observations, interpretation, summary, diagnosticImpressions, recommendations] =
    await Promise.all([
      generateReportSection('background', params),
      generateReportSection('observations', params),
      generateReportSection('interpretation', params),
      generateReportSection('summary', params),
      generateReportSection('diagnostic_impressions', params),
      generateReportSection('recommendations', params),
    ]);

  return {
    background,
    observations,
    interpretation,
    summary,
    diagnosticImpressions,
    recommendations,
  };
}
