import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth/auth.config';
import { prisma } from '@/lib/db/prisma';
import { createAuditLog } from '@/lib/utils/audit';
import { encrypt, decrypt } from '@/lib/encryption/crypto';
import { z } from 'zod';

const studentSchema = z.object({
  firstName: z.string().min(1),
  lastName: z.string().min(1),
  dateOfBirth: z.string(),
  grade: z.string().optional(),
  school: z.string().optional(),
  pronouns: z.string().optional(),
  studentId: z.string().optional(),
  parentGuardianName: z.string().optional(),
  parentPhone: z.string().optional(),
  parentEmail: z.string().email().optional().or(z.literal('')),
  emergencyContact: z.string().optional(),
  emergencyPhone: z.string().optional(),
  previousSchools: z.string().optional(),
  hasIEP: z.boolean().optional(),
  has504Plan: z.boolean().optional(),
  medicalHistory: z.string().optional(),
  developmentalHistory: z.string().optional(),
  currentMedications: z.string().optional(),
  diagnoses: z.string().optional(),
  status: z.string().optional(),
});

// GET /api/students/[id] - Get single student
export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const student = await prisma.student.findFirst({
      where: {
        id: params.id,
        psychologistId: session.user.id,
      },
      include: {
        referrals: {
          orderBy: { createdAt: 'desc' },
          take: 5,
        },
        assessments: {
          orderBy: { testDate: 'desc' },
          take: 10,
        },
        reports: {
          orderBy: { createdAt: 'desc' },
          take: 5,
        },
        timeline: {
          orderBy: { eventDate: 'desc' },
          take: 20,
        },
      },
    });

    if (!student) {
      return NextResponse.json({ error: 'Student not found' }, { status: 404 });
    }

    // Decrypt sensitive fields
    const decryptedStudent = {
      ...student,
      medicalHistory: student.medicalHistory ? decrypt(student.medicalHistory) : null,
      developmentalHistory: student.developmentalHistory ? decrypt(student.developmentalHistory) : null,
      currentMedications: student.currentMedications ? decrypt(student.currentMedications) : null,
    };

    // Log access
    await createAuditLog({
      userId: session.user.id,
      action: 'view',
      resourceType: 'student',
      resourceId: student.id,
    });

    return NextResponse.json({ student: decryptedStudent });
  } catch (error) {
    console.error('Error fetching student:', error);
    return NextResponse.json(
      { error: 'Failed to fetch student' },
      { status: 500 }
    );
  }
}

// PUT /api/students/[id] - Update student
export async function PUT(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Verify ownership
    const existing = await prisma.student.findFirst({
      where: {
        id: params.id,
        psychologistId: session.user.id,
      },
    });

    if (!existing) {
      return NextResponse.json({ error: 'Student not found' }, { status: 404 });
    }

    const body = await request.json();
    const validatedData = studentSchema.parse(body);

    // Encrypt sensitive fields
    const updateData: any = {
      ...validatedData,
      dateOfBirth: new Date(validatedData.dateOfBirth),
    };

    if (validatedData.medicalHistory !== undefined) {
      updateData.medicalHistory = validatedData.medicalHistory
        ? encrypt(validatedData.medicalHistory)
        : null;
    }

    if (validatedData.developmentalHistory !== undefined) {
      updateData.developmentalHistory = validatedData.developmentalHistory
        ? encrypt(validatedData.developmentalHistory)
        : null;
    }

    if (validatedData.currentMedications !== undefined) {
      updateData.currentMedications = validatedData.currentMedications
        ? encrypt(validatedData.currentMedications)
        : null;
    }

    const student = await prisma.student.update({
      where: { id: params.id },
      data: updateData,
    });

    // Log update
    await createAuditLog({
      userId: session.user.id,
      action: 'update',
      resourceType: 'student',
      resourceId: student.id,
      details: {
        name: `${student.firstName} ${student.lastName}`,
      },
    });

    return NextResponse.json({ student });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { error: 'Validation failed', details: error.errors },
        { status: 400 }
      );
    }

    console.error('Error updating student:', error);
    return NextResponse.json(
      { error: 'Failed to update student' },
      { status: 500 }
    );
  }
}

// DELETE /api/students/[id] - Delete (archive) student
export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Verify ownership
    const existing = await prisma.student.findFirst({
      where: {
        id: params.id,
        psychologistId: session.user.id,
      },
    });

    if (!existing) {
      return NextResponse.json({ error: 'Student not found' }, { status: 404 });
    }

    // Soft delete by setting status to archived
    const student = await prisma.student.update({
      where: { id: params.id },
      data: { status: 'archived' },
    });

    // Log deletion
    await createAuditLog({
      userId: session.user.id,
      action: 'delete',
      resourceType: 'student',
      resourceId: student.id,
      details: {
        name: `${student.firstName} ${student.lastName}`,
      },
    });

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Error deleting student:', error);
    return NextResponse.json(
      { error: 'Failed to delete student' },
      { status: 500 }
    );
  }
}
