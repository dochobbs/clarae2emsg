import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth/auth.config';
import { prisma } from '@/lib/db/prisma';
import { createAuditLog } from '@/lib/utils/audit';
import { generateCompleteReport, generateReportSection } from '@/lib/api/claude';
import { calculateAge } from '@/lib/utils/score-calculations';

// POST /api/reports/generate
export async function POST(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await request.json();
    const { studentId, reportType, section } = body;

    if (!studentId || !reportType) {
      return NextResponse.json(
        { error: 'studentId and reportType required' },
        { status: 400 }
      );
    }

    // Verify student belongs to user and get data
    const student = await prisma.student.findFirst({
      where: {
        id: studentId,
        psychologistId: session.user.id,
      },
      include: {
        assessments: {
          orderBy: { testDate: 'desc' },
        },
        referrals: {
          orderBy: { createdAt: 'desc' },
          take: 1,
        },
      },
    });

    if (!student) {
      return NextResponse.json({ error: 'Student not found' }, { status: 404 });
    }

    // Calculate age
    const age = calculateAge(new Date(student.dateOfBirth));

    // Prepare assessment results
    const assessmentResults = student.assessments.map(assessment => ({
      testName: assessment.testType,
      scores: assessment.scores ? JSON.parse(assessment.scores) : {},
      observations: assessment.observations || '',
    }));

    const params = {
      studentInfo: {
        name: `${student.firstName} ${student.lastName}`,
        age: age.years,
        grade: student.grade || '',
        dateOfBirth: student.dateOfBirth.toISOString().split('T')[0],
      },
      referralReason: student.referrals[0]?.reason || 'Not specified',
      assessmentResults,
      backgroundInfo: body.backgroundInfo || '',
      reportType,
    };

    // Generate specific section or complete report
    let result;
    if (section) {
      const generatedSection = await generateReportSection(section, params, body.context);
      result = { [section]: generatedSection };
    } else {
      result = await generateCompleteReport(params);
    }

    // Log AI usage for compliance
    await createAuditLog({
      userId: session.user.id,
      action: 'create',
      resourceType: 'report',
      resourceId: studentId,
      details: {
        action: 'ai_generation',
        section: section || 'complete',
        reportType,
      },
    });

    return NextResponse.json({
      success: true,
      generated: result,
      studentInfo: params.studentInfo,
    });
  } catch (error) {
    console.error('Error generating report:', error);
    return NextResponse.json(
      { error: 'Failed to generate report content', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
