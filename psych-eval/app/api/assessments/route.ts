import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth/auth.config';
import { prisma } from '@/lib/db/prisma';
import { createAuditLog } from '@/lib/utils/audit';
import { z } from 'zod';
import {
  calculateWISCComposites,
  calculateAge,
  standardScoreToPercentile,
  getDescriptiveCategory,
} from '@/lib/utils/score-calculations';

const assessmentSchema = z.object({
  studentId: z.string(),
  testType: z.string(),
  testDate: z.string(),
  testDomain: z.string(),
  scores: z.any(), // Will be validated based on test type
  observations: z.string().optional(),
  rapport: z.string().optional(),
  attention: z.string().optional(),
  engagement: z.string().optional(),
  completed: z.boolean().optional(),
});

// GET /api/assessments?studentId=xxx
export async function GET(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const studentId = searchParams.get('studentId');

    if (!studentId) {
      return NextResponse.json(
        { error: 'Student ID required' },
        { status: 400 }
      );
    }

    // Verify student belongs to user
    const student = await prisma.student.findFirst({
      where: {
        id: studentId,
        psychologistId: session.user.id,
      },
    });

    if (!student) {
      return NextResponse.json({ error: 'Student not found' }, { status: 404 });
    }

    const assessments = await prisma.assessment.findMany({
      where: {
        studentId,
      },
      orderBy: {
        testDate: 'desc',
      },
    });

    // Parse scores from JSON
    const formattedAssessments = assessments.map(a => ({
      ...a,
      scores: a.scores ? JSON.parse(a.scores) : {},
    }));

    await createAuditLog({
      userId: session.user.id,
      action: 'view',
      resourceType: 'student',
      resourceId: studentId,
      details: { action: 'view_assessments' },
    });

    return NextResponse.json({ assessments: formattedAssessments });
  } catch (error) {
    console.error('Error fetching assessments:', error);
    return NextResponse.json(
      { error: 'Failed to fetch assessments' },
      { status: 500 }
    );
  }
}

// POST /api/assessments
export async function POST(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await request.json();
    const validatedData = assessmentSchema.parse(body);

    // Verify student belongs to user
    const student = await prisma.student.findFirst({
      where: {
        id: validatedData.studentId,
        psychologistId: session.user.id,
      },
    });

    if (!student) {
      return NextResponse.json({ error: 'Student not found' }, { status: 404 });
    }

    // Process scores based on test type
    let processedScores = validatedData.scores;

    if (validatedData.testType === 'WISC-V' && validatedData.scores.subtests) {
      // Calculate composite scores for WISC-V
      const subtestScores: Record<string, number> = {};
      validatedData.scores.subtests.forEach((st: any) => {
        subtestScores[st.name] = st.scaledScore;
      });

      const composites = calculateWISCComposites(subtestScores);

      processedScores = {
        ...validatedData.scores,
        composites,
        calculatedAt: new Date().toISOString(),
      };
    }

    // Create assessment
    const assessment = await prisma.assessment.create({
      data: {
        studentId: validatedData.studentId,
        testType: validatedData.testType,
        testDate: new Date(validatedData.testDate),
        testDomain: validatedData.testDomain,
        scores: JSON.stringify(processedScores),
        observations: validatedData.observations || null,
        rapport: validatedData.rapport || null,
        attention: validatedData.attention || null,
        engagement: validatedData.engagement || null,
        completed: validatedData.completed || false,
      },
    });

    // Create timeline event
    await prisma.timelineEvent.create({
      data: {
        studentId: validatedData.studentId,
        eventType: 'testing-completed',
        title: `${validatedData.testType} Administered`,
        description: validatedData.testType,
        eventDate: new Date(validatedData.testDate),
      },
    });

    await createAuditLog({
      userId: session.user.id,
      action: 'create',
      resourceType: 'assessment',
      resourceId: assessment.id,
      details: {
        studentId: validatedData.studentId,
        testType: validatedData.testType,
      },
    });

    return NextResponse.json({
      assessment: {
        ...assessment,
        scores: processedScores,
      },
    }, { status: 201 });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { error: 'Validation failed', details: error.errors },
        { status: 400 }
      );
    }

    console.error('Error creating assessment:', error);
    return NextResponse.json(
      { error: 'Failed to create assessment' },
      { status: 500 }
    );
  }
}
