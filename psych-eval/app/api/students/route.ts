import { NextRequest, NextResponse } from 'next/server';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth/auth.config';
import { prisma } from '@/lib/db/prisma';
import { createAuditLog } from '@/lib/utils/audit';
import { encrypt } from '@/lib/encryption/crypto';
import { z } from 'zod';

// Validation schema
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
});

// GET /api/students - List all students for current user
export async function GET(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const search = searchParams.get('search') || '';
    const status = searchParams.get('status') || 'active';

    const students = await prisma.student.findMany({
      where: {
        psychologistId: session.user.id,
        status,
        ...(search && {
          OR: [
            { firstName: { contains: search, mode: 'insensitive' } },
            { lastName: { contains: search, mode: 'insensitive' } },
          ],
        }),
      },
      orderBy: [
        { lastName: 'asc' },
        { firstName: 'asc' },
      ],
      select: {
        id: true,
        firstName: true,
        lastName: true,
        dateOfBirth: true,
        grade: true,
        school: true,
        status: true,
        hasIEP: true,
        has504Plan: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    // Log access
    await createAuditLog({
      userId: session.user.id,
      action: 'view',
      resourceType: 'student',
      resourceId: 'list',
      details: { count: students.length, search, status },
    });

    return NextResponse.json({ students });
  } catch (error) {
    console.error('Error fetching students:', error);
    return NextResponse.json(
      { error: 'Failed to fetch students' },
      { status: 500 }
    );
  }
}

// POST /api/students - Create new student
export async function POST(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions);
    if (!session?.user?.id) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await request.json();
    const validatedData = studentSchema.parse(body);

    // Encrypt sensitive fields
    const encryptedData = {
      ...validatedData,
      dateOfBirth: new Date(validatedData.dateOfBirth),
      medicalHistory: validatedData.medicalHistory
        ? encrypt(validatedData.medicalHistory)
        : null,
      developmentalHistory: validatedData.developmentalHistory
        ? encrypt(validatedData.developmentalHistory)
        : null,
      currentMedications: validatedData.currentMedications
        ? encrypt(validatedData.currentMedications)
        : null,
      previousSchools: validatedData.previousSchools || null,
      diagnoses: validatedData.diagnoses || null,
      psychologistId: session.user.id,
    };

    const student = await prisma.student.create({
      data: encryptedData,
    });

    // Log creation
    await createAuditLog({
      userId: session.user.id,
      action: 'create',
      resourceType: 'student',
      resourceId: student.id,
      details: {
        name: `${student.firstName} ${student.lastName}`,
      },
    });

    return NextResponse.json({ student }, { status: 201 });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { error: 'Validation failed', details: error.errors },
        { status: 400 }
      );
    }

    console.error('Error creating student:', error);
    return NextResponse.json(
      { error: 'Failed to create student' },
      { status: 500 }
    );
  }
}
