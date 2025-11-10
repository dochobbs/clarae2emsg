import { redirect } from 'next/navigation';
import { getServerSession } from 'next-auth';
import { authOptions } from '@/lib/auth/auth.config';
import { Button } from '@/components/ui/button';
import Link from 'next/link';

export default async function Home() {
  const session = await getServerSession(authOptions);

  // If logged in, redirect to dashboard
  if (session) {
    redirect('/dashboard');
  }

  return (
    <div className="flex min-h-screen flex-col">
      {/* Header */}
      <header className="border-b border-gray-200 bg-white">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
          <div className="flex h-16 items-center justify-between">
            <div className="flex items-center">
              <h1 className="text-2xl font-bold text-blue-600">PsychEval</h1>
            </div>
            <div>
              <Link href="/api/auth/signin">
                <Button>Sign In with Google</Button>
              </Link>
            </div>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <main className="flex-1">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-24">
          <div className="text-center">
            <h2 className="text-4xl font-bold tracking-tight text-gray-900 sm:text-6xl">
              Psychoeducational Evaluations
              <br />
              <span className="text-blue-600">Made Simple</span>
            </h2>
            <p className="mt-6 text-lg leading-8 text-gray-600 max-w-2xl mx-auto">
              Streamline your psychoeducational assessments with AI-assisted report generation,
              automated score calculations, and HIPAA-compliant data management.
            </p>
            <div className="mt-10 flex items-center justify-center gap-x-6">
              <Link href="/api/auth/signin">
                <Button size="lg">Get Started</Button>
              </Link>
            </div>
          </div>

          {/* Features */}
          <div className="mt-24 grid grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-3">
            <div className="bg-white p-6 rounded-lg border border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">AI-Assisted Reports</h3>
              <p className="mt-2 text-gray-600">
                Generate comprehensive, professional reports using Claude AI with your assessment data.
              </p>
            </div>
            <div className="bg-white p-6 rounded-lg border border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">Auto-Calculate Scores</h3>
              <p className="mt-2 text-gray-600">
                Automatic standard score calculations, percentiles, and composite scores for major tests.
              </p>
            </div>
            <div className="bg-white p-6 rounded-lg border border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">HIPAA Compliant</h3>
              <p className="mt-2 text-gray-600">
                Bank-grade encryption, audit logging, and secure data storage for student information.
              </p>
            </div>
            <div className="bg-white p-6 rounded-lg border border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">Case Management</h3>
              <p className="mt-2 text-gray-600">
                Track referrals, timelines, and workflows all in one organized dashboard.
              </p>
            </div>
            <div className="bg-white p-6 rounded-lg border border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">Document Storage</h3>
              <p className="mt-2 text-gray-600">
                Securely store consent forms, school records, and assessment documents.
              </p>
            </div>
            <div className="bg-white p-6 rounded-lg border border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">Report Templates</h3>
              <p className="mt-2 text-gray-600">
                Customizable templates for different evaluation types and report formats.
              </p>
            </div>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="border-t border-gray-200 bg-white">
        <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 py-8">
          <p className="text-center text-sm text-gray-600">
            © 2024 PsychEval. HIPAA-Compliant Psychoeducational Evaluation Platform.
          </p>
        </div>
      </footer>
    </div>
  );
}
