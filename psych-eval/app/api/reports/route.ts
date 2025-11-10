import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth/auth.config';
import { prisma } from '@/lib/db/prisma';
import { createAuditLog } from '@/lib/utils/audit';
import { generateCompleteReport, ReportGenerationParams } from '@/lib/api/claude';
import { calculateAge } from '@/lib/utils/score-calculations';
import { z } from 'zod';

const reportSchema = z.object({
  studentId: z.string(),
  reportType: z.string(),
  title: z.string(),
  reasonForReferral: z.string().optional(),
  backgroundInfo: z.string().optional(),
  behavioralObs: z.string().optional(),
  assessmentResults: z.string().optional(),
  summary: z.string().optional(),
  diagnosticImpressions: z.string().optional(),
  recommendations: z.string().optional(),
  status: z.string().optional(),
});

// GET /api/reports?studentId=xxx
export async function GET(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const studentId = searchParams.get('studentId');

    if (studentId) {
      // Get reports for specific student
      const student = await prisma.student.findFirst({
        where: {
          id: studentId,
          psychologistId: session.user.id,
        },
      });

      if (!student) {
        return NextResponse.json({ error: 'Student not found' }, { status: 404 });
      }

      const reports = await prisma.report.findMany({
        where: { studentId },
        orderBy: { createdAt: 'desc' },
        include: {
          student: {
            select: {
              firstName: true,
              lastName: true,
            },
          },
        },
      });

      await createAuditLog({
        userId: session.user.id,
        action: 'view',
        resourceType: 'student',
        resourceId: studentId,
        details: { action: 'view_reports' },
      });

      return NextResponse.json({ reports });
    }

    // Get all reports for psychologist
    const reports = await prisma.report.findMany({
      where: {
        psychologistId: session.user.id,
      },
      orderBy: { createdAt: 'desc' },
      include: {
        student: {
          select: {
            firstName: true,
            lastName: true,
          },
        },
      },
      take: 50,
    });

    return NextResponse.json({ reports });
  } catch (error) {
    console.error('Error fetching reports:', error);
    return NextResponse.json(
      { error: 'Failed to fetch reports' },
      { status: 500 }
    );
  }
}

// POST /api/reports
export async function POST(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await request.json();
    const validatedData = reportSchema.parse(body);

    // Verify student belongs to user
    const student = await prisma.student.findFirst({
      where: {
        id: validatedData.studentId,
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

    const report = await prisma.report.create({
      data: {
        studentId: validatedData.studentId,
        psychologistId: session.user.id,
        reportType: validatedData.reportType,
        title: validatedData.title,
        reasonForReferral: validatedData.reasonForReferral || null,
        backgroundInfo: validatedData.backgroundInfo || null,
        behavioralObs: validatedData.behavioralObs || null,
        assessmentResults: validatedData.assessmentResults || null,
        summary: validatedData.summary || null,
        diagnosticImpressions: validatedData.diagnosticImpressions || null,
        recommendations: validatedData.recommendations || null,
        status: validatedData.status || 'draft',
      },
    });

    // Create timeline event
    await prisma.timelineEvent.create({
      data: {
        studentId: validatedData.studentId,
        eventType: 'report-created',
        title: 'Report Created',
        description: `${validatedData.reportType}: ${validatedData.title}`,
        eventDate: new Date(),
      },
    });

    await createAuditLog({
      userId: session.user.id,
      action: 'create',
      resourceType: 'report',
      resourceId: report.id,
      details: {
        studentId: validatedData.studentId,
        reportType: validatedData.reportType,
      },
    });

    return NextResponse.json({ report }, { status: 201 });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { error: 'Validation failed', details: error.errors },
        { status: 400 }
      );
    }

    console.error('Error creating report:', error);
    return NextResponse.json(
      { error: 'Failed to create report' },
      { status: 500 }
    );
  }
}
