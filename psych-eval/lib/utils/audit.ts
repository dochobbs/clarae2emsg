import { prisma } from '@/lib/db/prisma';

export type AuditAction = 'view' | 'create' | 'update' | 'delete' | 'export' | 'login' | 'logout';
export type ResourceType = 'student' | 'assessment' | 'report' | 'document' | 'user' | 'system';

interface AuditLogParams {
  userId: string;
  action: AuditAction;
  resourceType: ResourceType;
  resourceId: string;
  ipAddress?: string;
  userAgent?: string;
  details?: Record<string, any>;
}

/**
 * Creates an audit log entry for HIPAA compliance
 * All access to PHI must be logged
 */
export async function createAuditLog(params: AuditLogParams): Promise<void> {
  try {
    await prisma.auditLog.create({
      data: {
        userId: params.userId,
        action: params.action,
        resourceType: params.resourceType,
        resourceId: params.resourceId,
        ipAddress: params.ipAddress || null,
        userAgent: params.userAgent || null,
        details: params.details ? JSON.stringify(params.details) : null,
      },
    });
  } catch (error) {
    // Log to external monitoring service in production
    console.error('Failed to create audit log:', error);
    // Don't throw - audit logging failure shouldn't break the application
    // But should be monitored closely
  }
}

/**
 * Get audit logs for a specific resource
 */
export async function getAuditLogs(
  resourceType: ResourceType,
  resourceId: string,
  limit: number = 50
) {
  return await prisma.auditLog.findMany({
    where: {
      resourceType,
      resourceId,
    },
    include: {
      user: {
        select: {
          id: true,
          name: true,
          email: true,
        },
      },
    },
    orderBy: {
      createdAt: 'desc',
    },
    take: limit,
  });
}

/**
 * Get recent audit logs for a user
 */
export async function getUserAuditLogs(userId: string, limit: number = 50) {
  return await prisma.auditLog.findMany({
    where: {
      userId,
    },
    orderBy: {
      createdAt: 'desc',
    },
    take: limit,
  });
}

/**
 * Get audit logs within a date range for compliance reporting
 */
export async function getAuditLogsInRange(startDate: Date, endDate: Date) {
  return await prisma.auditLog.findMany({
    where: {
      createdAt: {
        gte: startDate,
        lte: endDate,
      },
    },
    include: {
      user: {
        select: {
          id: true,
          name: true,
          email: true,
        },
      },
    },
    orderBy: {
      createdAt: 'desc',
    },
  });
}
