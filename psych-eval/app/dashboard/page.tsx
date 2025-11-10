'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import Link from 'next/link';

interface DashboardStats {
  totalStudents: number;
  activeReports: number;
  recentAssessments: number;
  upcomingDeadlines: number;
}

export default function DashboardPage() {
  const router = useRouter();
  const [stats, setStats] = useState<DashboardStats>({
    totalStudents: 0,
    activeReports: 0,
    recentAssessments: 0,
    upcomingDeadlines: 0,
  });
  const [recentStudents, setRecentStudents] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchDashboardData();
  }, []);

  async function fetchDashboardData() {
    try {
      const response = await fetch('/api/students');
      if (response.ok) {
        const data = await response.json();
        setRecentStudents(data.students.slice(0, 5));
        setStats({
          totalStudents: data.students.length,
          activeReports: 0,
          recentAssessments: 0,
          upcomingDeadlines: 0,
        });
      }
    } catch (error) {
      console.error('Error fetching dashboard data:', error);
    } finally {
      setLoading(false);
    }
  }

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <div className="text-lg">Loading...</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white border-b border-gray-200">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="flex h-16 items-center justify-between">
            <h1 className="text-2xl font-bold text-blue-600">PsychEval</h1>
            <div className="flex items-center gap-4">
              <Link href="/dashboard/students">
                <Button variant="outline">Students</Button>
              </Link>
              <Link href="/api/auth/signout">
                <Button variant="ghost">Sign Out</Button>
              </Link>
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <h2 className="text-3xl font-bold text-gray-900">Dashboard</h2>
          <p className="mt-2 text-gray-600">Welcome back! Here's an overview of your caseload.</p>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4 mb-8">
          <Card>
            <CardHeader>
              <CardDescription>Total Students</CardDescription>
              <CardTitle className="text-3xl">{stats.totalStudents}</CardTitle>
            </CardHeader>
          </Card>

          <Card>
            <CardHeader>
              <CardDescription>Active Reports</CardDescription>
              <CardTitle className="text-3xl">{stats.activeReports}</CardTitle>
            </CardHeader>
          </Card>

          <Card>
            <CardHeader>
              <CardDescription>Recent Assessments</CardDescription>
              <CardTitle className="text-3xl">{stats.recentAssessments}</CardTitle>
            </CardHeader>
          </Card>

          <Card>
            <CardHeader>
              <CardDescription>Upcoming Deadlines</CardDescription>
              <CardTitle className="text-3xl">{stats.upcomingDeadlines}</CardTitle>
            </CardHeader>
          </Card>
        </div>

        {/* Quick Actions */}
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-2 mb-8">
          <Card>
            <CardHeader>
              <CardTitle>Quick Actions</CardTitle>
              <CardDescription>Common tasks and workflows</CardDescription>
            </CardHeader>
            <CardContent className="space-y-2">
              <Link href="/dashboard/students/new">
                <Button className="w-full justify-start" variant="outline">
                  + Add New Student
                </Button>
              </Link>
              <Link href="/dashboard/reports/new">
                <Button className="w-full justify-start" variant="outline">
                  + Create Report
                </Button>
              </Link>
              <Link href="/dashboard/assessments/new">
                <Button className="w-full justify-start" variant="outline">
                  + Record Assessment
                </Button>
              </Link>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Recent Students</CardTitle>
              <CardDescription>Recently updated student records</CardDescription>
            </CardHeader>
            <CardContent>
              {recentStudents.length === 0 ? (
                <p className="text-sm text-gray-500">No students yet. Add your first student to get started!</p>
              ) : (
                <div className="space-y-3">
                  {recentStudents.map((student) => (
                    <div
                      key={student.id}
                      className="flex items-center justify-between p-3 border border-gray-200 rounded-lg hover:bg-gray-50 cursor-pointer"
                      onClick={() => router.push(`/dashboard/students/${student.id}`)}
                    >
                      <div>
                        <p className="font-medium text-gray-900">
                          {student.firstName} {student.lastName}
                        </p>
                        <p className="text-sm text-gray-500">
                          Grade {student.grade || 'N/A'} • {student.school || 'No school'}
                        </p>
                      </div>
                      <div className="text-sm text-gray-500">
                        {student.hasIEP && <span className="text-blue-600 font-medium">IEP</span>}
                        {student.has504Plan && <span className="text-purple-600 font-medium ml-2">504</span>}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        {/* Getting Started Guide */}
        {stats.totalStudents === 0 && (
          <Card>
            <CardHeader>
              <CardTitle>Getting Started</CardTitle>
              <CardDescription>Set up your first psychoeducational evaluation</CardDescription>
            </CardHeader>
            <CardContent>
              <ol className="space-y-4">
                <li className="flex items-start">
                  <span className="flex h-6 w-6 items-center justify-center rounded-full bg-blue-600 text-white text-sm font-medium mr-3">
                    1
                  </span>
                  <div>
                    <p className="font-medium">Add a Student</p>
                    <p className="text-sm text-gray-600">Create a student profile with demographics and background information.</p>
                  </div>
                </li>
                <li className="flex items-start">
                  <span className="flex h-6 w-6 items-center justify-center rounded-full bg-blue-600 text-white text-sm font-medium mr-3">
                    2
                  </span>
                  <div>
                    <p className="font-medium">Record Assessments</p>
                    <p className="text-sm text-gray-600">Enter test scores - the system will automatically calculate standard scores and composites.</p>
                  </div>
                </li>
                <li className="flex items-start">
                  <span className="flex h-6 w-6 items-center justify-center rounded-full bg-blue-600 text-white text-sm font-medium mr-3">
                    3
                  </span>
                  <div>
                    <p className="font-medium">Generate Report</p>
                    <p className="text-sm text-gray-600">Use AI-assisted report generation to create professional psychoeducational reports.</p>
                  </div>
                </li>
              </ol>
              <div className="mt-6">
                <Link href="/dashboard/students/new">
                  <Button>Add Your First Student</Button>
                </Link>
              </div>
            </CardContent>
          </Card>
        )}
      </main>
    </div>
  );
}
