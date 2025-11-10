# PsychEval - Psychoeducational Evaluation Platform

A comprehensive, HIPAA-compliant web application for psychologists to manage psychoeducational evaluations, assessments, and report generation with AI assistance.

## 🎯 Features

- **Student Management** - Complete student profiles with encrypted PHI
- **Assessment Tools** - Auto-calculating scores for WISC-V, WIAT-4, BASC-3, and more
- **AI-Assisted Reports** - Generate professional reports using Claude AI
- **HIPAA Compliant** - AES-256 encryption, audit logging, secure authentication
- **Case Management** - Track referrals, timelines, and workflows
- **Document Storage** - Secure storage for consents and records

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- PostgreSQL database
- Google Cloud account (OAuth)
- Anthropic API key

### Installation

1. **Install dependencies:**
```bash
npm install
```

2. **Configure environment variables:**
```bash
cp .env.example .env
# Edit .env with your credentials
```

3. **Set up database:**
```bash
npx prisma generate
npx prisma migrate dev
```

4. **Run development server:**
```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000)

## 📋 Environment Variables

Create a `.env` file:

```env
DATABASE_URL="postgresql://user:password@localhost:5432/psych_eval"
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="your-secret-key"
GOOGLE_CLIENT_ID="your-google-client-id"
GOOGLE_CLIENT_SECRET="your-google-client-secret"
ANTHROPIC_API_KEY="your-anthropic-api-key"
ENCRYPTION_KEY="your-32-char-encryption-key"
```

## 🏗️ Project Structure

```
psych-eval/
├── app/              # Next.js app directory
│   ├── api/         # API routes
│   └── dashboard/   # Protected pages
├── components/       # React components
├── lib/
│   ├── api/         # Claude API client
│   ├── auth/        # NextAuth config
│   ├── db/          # Prisma client
│   ├── encryption/  # Crypto utilities
│   └── utils/       # Helper functions
├── prisma/          # Database schema
└── public/          # Static assets
```

## 🔐 Security & HIPAA Compliance

### Implemented Features
- ✅ AES-256-GCM encryption for PHI
- ✅ TLS 1.3 for data in transit
- ✅ Comprehensive audit logging
- ✅ 15-minute session timeout
- ✅ Secure password hashing
- ✅ Role-based access control

### Before Production
- [ ] Sign BAAs with all vendors (AWS/GCP, Anthropic, etc.)
- [ ] Enable database encryption at rest
- [ ] Configure automated backups
- [ ] Conduct security audit
- [ ] Implement disaster recovery
- [ ] Train users on HIPAA compliance

## 📚 Key Features

### Student Management
- Demographics and contact information
- Medical and developmental history (encrypted)
- IEP/504 plan tracking
- Document attachments

### Assessment System
- Support for major tests (WISC-V, WIAT-4, BASC-3, Vineland-3)
- Auto-calculate standard scores and percentiles
- Composite score computation
- Visual score profiles

### AI Report Generation
- Background information synthesis
- Assessment interpretation
- Diagnostic impressions
- Evidence-based recommendations
- Customizable templates

### Case Management
- Referral tracking
- Timeline visualization
- Deadline management
- Workflow automation

## 🤖 AI Integration (Claude API)

The system uses Anthropic's Claude API to:
- Generate report sections based on assessment data
- Interpret scores with clinical context
- Suggest appropriate accommodations
- Create strength-based narratives

**Important:** All AI-generated content should be reviewed by qualified professionals.

## 📖 Usage

### 1. Add a Student
- Navigate to Dashboard → Add New Student
- Enter demographics and background
- Sensitive fields are automatically encrypted

### 2. Record Assessments
- Select student → Add Assessment
- Choose test type (e.g., WISC-V)
- Enter scores → System auto-calculates composites

### 3. Generate Reports
- Select student → Generate Report
- Use AI to generate sections
- Review and edit content
- Export to PDF

## 🛠️ Tech Stack

- **Frontend:** Next.js 14, React, TypeScript, Tailwind CSS
- **Backend:** Next.js API Routes, Prisma ORM
- **Database:** PostgreSQL
- **Auth:** NextAuth.js + Google OAuth
- **AI:** Anthropic Claude API
- **Security:** crypto (AES-256), bcrypt, JWT

## 🗄️ Database Schema

Main models:
- `User` - Psychologist accounts
- `Student` - Student profiles (PHI encrypted)
- `Assessment` - Test data and scores
- `Report` - Generated reports
- `AuditLog` - HIPAA audit trail
- `Document` - File storage
- `Referral` - Referral tracking

## 🚢 Deployment

### AWS Deployment (Recommended)

1. **RDS PostgreSQL** - Enable encryption, automated backups
2. **ECS/Elastic Beanstalk** - Application hosting
3. **S3** - File storage with encryption
4. **Secrets Manager** - Environment variables
5. **Certificate Manager** - SSL/TLS certificates
6. **Sign AWS BAA** - Required for HIPAA

See [PLANNING.md](../PLANNING.md) for detailed deployment guide.

## 🧪 Development

```bash
# Type checking
npx tsc --noEmit

# Linting
npm run lint

# Database migrations
npx prisma migrate dev

# Reset database
npx prisma migrate reset
```

## 📝 API Endpoints

### Students
- `GET /api/students` - List students
- `POST /api/students` - Create student
- `GET /api/students/[id]` - Get student
- `PUT /api/students/[id]` - Update student

### Assessments
- `GET /api/assessments?studentId=xxx` - List assessments
- `POST /api/assessments` - Create assessment

### Reports
- `GET /api/reports?studentId=xxx` - List reports
- `POST /api/reports` - Create report
- `POST /api/reports/generate` - AI generate content

## ⚠️ Important Notes

- **HIPAA Compliance:** Requires proper configuration and BAAs
- **AI Review:** Always review AI-generated content
- **Normative Data:** Current implementation uses simplified calculations
- **Production:** Additional security measures required

## 🤝 Support

For questions or issues:
- Review documentation in `/PLANNING.md`
- Check `.env.example` for configuration
- Consult API documentation in source files

## 📄 License

Proprietary - All rights reserved

## ⚖️ Disclaimer

This software assists with psychoeducational evaluations but does not replace professional judgment. Users are responsible for:
- HIPAA compliance in deployment
- Obtaining necessary BAAs
- Validating AI-generated content
- Following professional ethics

---

**Version:** 1.0.0 MVP
**Built with:** Next.js, Claude AI, PostgreSQL
**Status:** Development/Testing
