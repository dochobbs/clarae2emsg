# Psychoeducational Evaluation Webapp - Planning Document

## Overview
A HIPAA-compliant web application to streamline psychoeducational evaluations, special education assessments, and psychological reports for school psychologists.

---

## Core Features & Functionality

### 1. Client/Student Management
- **Student Profiles**
  - Demographics (name, DOB, grade, school, pronouns)
  - Parent/guardian information
  - Emergency contacts
  - Consent tracking (assessment consent, release of information)
  - Educational history (previous schools, IEPs, 504 plans)
  - Medical/developmental history
  - Current medications
  - Previous assessments/diagnoses

- **Case Management**
  - Referral tracking (reason, date, source)
  - Timeline tracking (consent received, testing dates, report due dates)
  - Status dashboard (pending, in-progress, completed)
  - Document organization by student

### 2. Assessment Tools & Data Entry

- **Common Assessment Batteries**
  - Cognitive: WISC-V, WPPSI-IV, SB-5, KABC-II
  - Achievement: WIAT-4, WJ-IV, KTEA-3
  - Adaptive: Vineland-3, ABAS-3
  - Social-Emotional: BASC-3, Conners 4, CBCL, SDQ
  - Executive Function: BRIEF-2, CEFI
  - Autism: ADOS-2, ADI-R, GARS-3
  - Early Childhood: Bayley-4, Battelle

- **Smart Score Entry**
  - Auto-calculation of standard scores, percentiles, age/grade equivalents
  - Confidence intervals
  - Score validation (flag unusual patterns)
  - Subtest scatter analysis
  - Index score calculations
  - Normative data lookup tables

- **Behavioral Observations**
  - Structured observation templates
  - Attention tracking
  - Engagement levels
  - Test-taking behaviors
  - Rapport quality

### 3. AI-Assisted Report Generation (Claude API)

- **Intelligent Report Writing**
  - Auto-generate background sections from student data
  - Interpret test scores with clinical context
  - Generate hypothesis-driven analysis
  - Suggest appropriate diagnoses based on data patterns
  - Create data-driven recommendations
  - Maintain consistent professional tone
  - Reference DSM-5-TR/diagnostic criteria when relevant

- **Report Sections**
  - Reason for referral
  - Background information (auto-populated from student profile)
  - Behavioral observations (AI-enhanced from notes)
  - Assessment results by domain with interpretation
  - Summary and diagnostic impressions
  - Recommendations (educational, therapeutic, medical, accommodations)

- **Smart Features**
  - Suggest relevant test batteries based on referral question
  - Flag score discrepancies that need explanation
  - Recommend additional assessments if needed
  - Generate strength-based narrative
  - Auto-populate IEP/504 recommendations

### 4. Report Templates & Customization

- **Template Library**
  - Psychoeducational evaluation
  - Special education (initial/triennial)
  - Diagnostic assessment
  - Progress monitoring report
  - Brief consultation report
  - Bilingual assessment report

- **Customizable Elements**
  - Letterhead/logo
  - Report structure
  - Section headers
  - Standard disclaimers
  - Signature blocks
  - District-specific requirements

### 5. Recommendation Library

- **Categorized Recommendations**
  - Academic interventions
  - Classroom accommodations
  - Testing modifications
  - Behavioral supports
  - Social-emotional strategies
  - Executive function supports
  - Assistive technology
  - Related services (OT, SLP, counseling)
  - Parent strategies

- **Smart Suggestions**
  - AI suggests relevant recommendations based on findings
  - Tag by diagnosis, age, setting
  - Evidence-based practice indicators
  - Searchable and filterable

### 6. Document Management

- **Secure Storage**
  - Upload consent forms, school records, medical records
  - Organize by student and document type
  - Version control for reports (drafts, revisions, final)
  - OCR for scanned documents
  - Tagging and search

- **Export & Sharing**
  - PDF generation with encryption
  - Secure link sharing (time-limited, password-protected)
  - Email integration (encrypted)
  - Digital signature support
  - Print-optimized formats

### 7. Scheduling & Workflow

- **Appointment Management**
  - Testing session scheduling
  - Parent interview scheduling
  - Teacher consultation tracking
  - Observation scheduling
  - Calendar integration
  - Automated reminders

- **Workflow Automation**
  - Checklists for each evaluation type
  - Deadline tracking
  - Status updates
  - Time tracking per case

### 8. Data Visualization & Analytics

- **Score Visualization**
  - Standard score profiles (bell curves)
  - Composite/index comparison charts
  - Subtest scatter graphs
  - Growth charts over time
  - Percentile ranks visualization

- **Practice Analytics**
  - Caseload dashboard
  - Referral patterns
  - Time-to-completion metrics
  - Diagnostic trends
  - Productivity tracking

### 9. Collaboration Tools

- **Secure Messaging**
  - Communication with parents (HIPAA-compliant)
  - Teacher rating scale requests
  - Consultation notes
  - Audit trail

- **Team Collaboration**
  - Multi-disciplinary teams
  - Review and approval workflows
  - Comment threads on reports
  - Role-based access (if working with assistants/interns)

### 10. Additional Features

- **Billing & Time Tracking**
  - Session time logging
  - Billing codes (CPT codes for private practice)
  - Invoice generation
  - Insurance tracking

- **Progress Monitoring**
  - Track intervention implementation
  - Follow-up assessments
  - Response to intervention (RTI) data

- **Research & Compliance**
  - De-identified data export for research
  - FERPA compliance logging
  - Audit trails for all data access

---

## Technical Architecture

### Frontend
- **Framework**: Next.js 14+ (React)
  - Server-side rendering for security
  - TypeScript for type safety
  - Tailwind CSS for styling
  - shadcn/ui component library

- **Key Libraries**
  - React Hook Form (form management)
  - Zod (validation)
  - Recharts (data visualization)
  - PDF generation: react-pdf or Puppeteer
  - Rich text editor: Tiptap or Lexical
  - Date/time: date-fns

### Backend
- **API**: Next.js API Routes or separate Express.js
  - RESTful API design
  - Rate limiting
  - Request validation
  - Error handling

- **Authentication**
  - NextAuth.js with Google OAuth provider
  - Session management
  - Role-based access control (RBAC)
  - Multi-factor authentication (MFA) option

### Database
- **Primary Database**: PostgreSQL
  - Encrypted at rest (AES-256)
  - Row-level security
  - Backup and recovery
  - Point-in-time recovery

- **Schema Design**
  - Users (psychologists)
  - Students (encrypted PHI)
  - Assessments
  - Reports
  - Documents
  - Audit logs
  - Templates
  - Recommendations library

- **ORM**: Prisma or Drizzle
  - Type-safe queries
  - Migration management
  - Connection pooling

### File Storage
- **Solution**: AWS S3 or equivalent with encryption
  - Bucket policies for access control
  - Versioning enabled
  - Lifecycle policies
  - Server-side encryption (SSE-KMS)
  - Signed URLs for temporary access

### AI Integration
- **Claude API (Anthropic)**
  - Business Associate Agreement (BAA) required
  - No training on customer data
  - Secure API calls (HTTPS)
  - No PHI in logs
  - Rate limiting and error handling

### Security & Compliance

#### HIPAA Requirements
1. **Access Controls**
   - Unique user identification
   - Emergency access procedures
   - Automatic logoff
   - Encryption and decryption

2. **Audit Controls**
   - Log all access to ePHI
   - Log all modifications
   - Log authentication events
   - Regular audit log review

3. **Integrity Controls**
   - Data validation
   - Error checking
   - Version control
   - Checksums for files

4. **Transmission Security**
   - TLS 1.3 for all connections
   - VPN for admin access
   - Encrypted email
   - Encrypted file transfers

5. **Data Encryption**
   - At rest: AES-256
   - In transit: TLS 1.3
   - Database-level encryption
   - Application-level encryption for sensitive fields
   - Key management (AWS KMS or similar)

#### Additional Security Measures
- Penetration testing
- Vulnerability scanning
- Security incident response plan
- Regular security training
- Password policies (complexity, expiration)
- Session timeout
- IP whitelisting (optional)
- CSRF protection
- XSS prevention
- SQL injection prevention

---

## Required Services & Setup

### 1. Google Cloud Platform
- **Purpose**: Google OAuth authentication
- **Setup Required**:
  - Create project in Google Cloud Console
  - Enable Google+ API
  - Configure OAuth consent screen
  - Create OAuth 2.0 credentials (Client ID & Secret)
  - Add authorized redirect URIs
  - Domain verification
- **HIPAA Note**: Google Workspace can provide BAA for G Suite, but OAuth itself doesn't handle PHI

### 2. Anthropic Claude API
- **Purpose**: AI-assisted report generation
- **Setup Required**:
  - Anthropic account
  - Request and sign Business Associate Agreement (BAA)
  - API key generation
  - Rate limit configuration
  - Cost monitoring setup
- **HIPAA**: Anthropic provides BAA for enterprise customers

### 3. Database Hosting (HIPAA-Compliant)
**Options:**
- **AWS RDS for PostgreSQL**
  - Enable encryption at rest
  - Enable encryption in transit
  - VPC configuration
  - Sign AWS BAA
  - Automated backups
  - Multi-AZ deployment

- **Google Cloud SQL**
  - Enable encryption
  - Private IP
  - Sign Google Cloud BAA
  - Automated backups

- **Supabase** (with proper configuration)
  - PostgreSQL-based
  - Check HIPAA compliance tier
  - May need self-hosted for full compliance

### 4. Application Hosting (HIPAA-Compliant)
**Options:**
- **AWS (Elastic Beanstalk, ECS, or EC2)**
  - Sign AWS BAA
  - VPC configuration
  - Security groups
  - WAF (Web Application Firewall)
  - CloudWatch for monitoring
  - Auto-scaling

- **Google Cloud Platform (App Engine, Cloud Run, GKE)**
  - Sign Google Cloud BAA
  - VPC configuration
  - Cloud Armor
  - Cloud Monitoring

- **Vercel** (check HIPAA compliance - may not be suitable)
  - Popular for Next.js
  - May require custom enterprise agreement
  - Consider self-hosting instead

### 5. File Storage (HIPAA-Compliant)
**Options:**
- **AWS S3**
  - Enable default encryption (SSE-KMS)
  - Bucket policies
  - Versioning
  - Access logging
  - Sign AWS BAA

- **Google Cloud Storage**
  - Customer-managed encryption keys
  - IAM policies
  - Versioning
  - Sign Google Cloud BAA

### 6. SSL/TLS Certificates
- **Options**:
  - Let's Encrypt (free, automated)
  - AWS Certificate Manager (if using AWS)
  - Google-managed certificates (if using GCP)
- **Requirement**: TLS 1.3, strong cipher suites

### 7. Email Service (HIPAA-Compliant)
**Purpose**: Notifications, password resets, secure communication
**Options:**
- **AWS SES** (with BAA)
- **Paubox** (HIPAA-compliant email API)
- **SendGrid** (with BAA)
- **Mailgun** (check HIPAA compliance)

### 8. Backup & Disaster Recovery
- **Database backups**
  - Automated daily backups
  - Point-in-time recovery
  - Cross-region replication
  - Regular restore testing

- **File backups**
  - S3 versioning
  - Glacier for long-term storage
  - Backup verification

### 9. Monitoring & Logging (HIPAA-Compliant)
**Requirements:**
- No PHI in logs
- Centralized logging
- Audit trail retention (6 years)
- Alerting for security events

**Options:**
- **AWS CloudWatch** + **CloudTrail**
- **Google Cloud Logging** + **Audit Logs**
- **Datadog** (with BAA)
- **Sentry** (error tracking, check HIPAA compliance)

### 10. Domain & DNS
- **Domain registrar**: Namecheap, Google Domains, AWS Route 53
- **DNS**: Cloudflare (with appropriate security), AWS Route 53, Google Cloud DNS
- **Requirements**: DNSSEC, DDoS protection

### 11. Payment Processing (if billing features)
- **Stripe** (with BAA for healthcare)
- **Square** (healthcare-compliant tier)
- **Requirements**: PCI DSS compliance + HIPAA BAA

### 12. Development & Deployment Tools
- **Version Control**: GitHub (private repositories)
- **CI/CD**: GitHub Actions, AWS CodePipeline, or Google Cloud Build
- **Environment Management**: Docker, Kubernetes (if scaling)
- **Secrets Management**: AWS Secrets Manager, Google Secret Manager, HashiCorp Vault

---

## HIPAA Compliance Checklist

### Business Associate Agreements (BAAs) Required With:
- [ ] Cloud hosting provider (AWS/GCP)
- [ ] Database provider
- [ ] File storage provider
- [ ] Anthropic (Claude API)
- [ ] Email service provider
- [ ] Monitoring/logging service
- [ ] Payment processor (if applicable)
- [ ] Any third-party service that handles PHI

### Technical Safeguards:
- [ ] Encryption at rest (AES-256)
- [ ] Encryption in transit (TLS 1.3)
- [ ] Automatic session timeout (15 minutes idle)
- [ ] Unique user authentication
- [ ] Multi-factor authentication option
- [ ] Role-based access control
- [ ] Audit logging (all access, modifications, deletions)
- [ ] Audit log retention (6 years minimum)
- [ ] Regular backups with encryption
- [ ] Disaster recovery plan
- [ ] Incident response plan

### Administrative Safeguards:
- [ ] Security risk assessment
- [ ] Workforce training on HIPAA
- [ ] Access management policies
- [ ] Password policies
- [ ] Breach notification procedures
- [ ] Designated Privacy Officer
- [ ] Designated Security Officer

### Physical Safeguards:
- [ ] Data center security (handled by cloud provider)
- [ ] Workstation security policies
- [ ] Device and media controls

### Documentation:
- [ ] Privacy policies
- [ ] Security policies
- [ ] Breach notification templates
- [ ] BAA templates
- [ ] User agreements
- [ ] Data retention policies
- [ ] Data disposal procedures

---

## Implementation Plan

### Phase 1: Foundation & Setup (Weeks 1-2)
**Goal**: Set up infrastructure and authentication

- [ ] Set up project repository structure
- [ ] Initialize Next.js project with TypeScript
- [ ] Set up PostgreSQL database (local dev + cloud staging)
- [ ] Configure Google OAuth in Google Cloud Console
- [ ] Implement NextAuth.js with Google provider
- [ ] Set up database schema with Prisma/Drizzle
- [ ] Implement basic user model and authentication flow
- [ ] Set up development environment variables
- [ ] Configure TLS/SSL for development
- [ ] Set up CI/CD pipeline basics

**Deliverables**:
- Working authentication system
- Database schema v1
- Dev environment running locally
- Cloud infrastructure provisioned

### Phase 2: Core Data Models (Weeks 3-4)
**Goal**: Build student management and assessment data structures

- [ ] Design and implement Student profile schema
- [ ] Create CRUD operations for students
- [ ] Build Assessment schema (flexible for multiple test types)
- [ ] Implement test score normative data tables
- [ ] Create Document storage schema
- [ ] Build audit logging system
- [ ] Implement encryption for sensitive fields
- [ ] Create basic UI for student management
- [ ] Build forms for student data entry
- [ ] Implement file upload for documents

**Deliverables**:
- Student management system
- Document upload working
- Audit logs capturing all PHI access

### Phase 3: Assessment Tools (Weeks 5-7)
**Goal**: Build assessment data entry and score calculation

- [ ] Create assessment test library (WISC-V, WIAT-4, etc.)
- [ ] Implement score entry forms
- [ ] Build auto-calculation engine (standard scores, percentiles)
- [ ] Create normative data lookup system
- [ ] Implement behavioral observation templates
- [ ] Build score visualization components
- [ ] Create assessment dashboard
- [ ] Implement data validation and error checking
- [ ] Build subtest scatter analysis
- [ ] Create score profile charts

**Deliverables**:
- Functional assessment data entry
- Auto-calculating scores
- Visual score profiles

### Phase 4: Claude API Integration (Weeks 8-10)
**Goal**: Implement AI-assisted report generation

- [ ] Set up Anthropic Claude API account and BAA
- [ ] Design prompt engineering system for reports
- [ ] Implement Claude API client with error handling
- [ ] Build report generation service layer
- [ ] Create section-by-section generation
- [ ] Implement score interpretation logic
- [ ] Build recommendation suggestion system
- [ ] Create AI-assisted diagnostic impression generation
- [ ] Implement report review/editing interface
- [ ] Build prompt templates for different report types
- [ ] Add rate limiting and cost controls
- [ ] Create fallback for API failures

**Deliverables**:
- Working AI report generation
- Editable report interface
- Cost monitoring in place

### Phase 5: Report System (Weeks 11-13)
**Goal**: Complete report creation, editing, and export

- [ ] Build rich text editor for report writing
- [ ] Create report template system
- [ ] Implement report versioning (draft, revision, final)
- [ ] Build PDF generation system
- [ ] Create customizable letterhead/branding
- [ ] Implement digital signature support
- [ ] Build report preview system
- [ ] Create print-optimized layouts
- [ ] Implement report sharing (secure links)
- [ ] Build recommendation library
- [ ] Create searchable recommendation database

**Deliverables**:
- Complete report writing system
- PDF export working
- Template system functional

### Phase 6: Workflow & Scheduling (Weeks 14-15)
**Goal**: Build case management and scheduling tools

- [ ] Create case dashboard
- [ ] Implement referral tracking
- [ ] Build timeline/deadline system
- [ ] Create appointment scheduling
- [ ] Implement workflow checklists
- [ ] Build time tracking system
- [ ] Create notification system
- [ ] Implement reminder emails (HIPAA-compliant)
- [ ] Build status tracking
- [ ] Create analytics dashboard

**Deliverables**:
- Case management system
- Scheduling functional
- Dashboard with analytics

### Phase 7: Security Hardening (Weeks 16-17)
**Goal**: Ensure HIPAA compliance and security

- [ ] Implement comprehensive audit logging
- [ ] Add session timeout and management
- [ ] Set up MFA option
- [ ] Implement role-based access control
- [ ] Add encryption for all PHI fields
- [ ] Set up automated backups
- [ ] Implement disaster recovery procedures
- [ ] Create security incident response plan
- [ ] Conduct security audit
- [ ] Perform penetration testing
- [ ] Review and sign all BAAs
- [ ] Document security policies
- [ ] Create user training materials

**Deliverables**:
- HIPAA-compliant security measures
- All BAAs signed
- Security documentation complete

### Phase 8: Testing & Refinement (Weeks 18-19)
**Goal**: Comprehensive testing and bug fixes

- [ ] Unit testing (>80% coverage)
- [ ] Integration testing
- [ ] End-to-end testing
- [ ] Performance testing
- [ ] Load testing
- [ ] Accessibility testing (WCAG 2.1 AA)
- [ ] Cross-browser testing
- [ ] Mobile responsiveness testing
- [ ] User acceptance testing with psychologist
- [ ] Bug fixes and refinements
- [ ] Documentation updates

**Deliverables**:
- Fully tested application
- Bug-free core features
- User documentation

### Phase 9: Deployment & Launch (Week 20)
**Goal**: Production deployment and go-live

- [ ] Set up production environment
- [ ] Configure production database
- [ ] Set up production monitoring
- [ ] Configure production backups
- [ ] Set up error tracking
- [ ] Performance monitoring
- [ ] Deploy to production
- [ ] Verify all integrations
- [ ] Conduct final security review
- [ ] Create onboarding flow
- [ ] User training session
- [ ] Go-live!

**Deliverables**:
- Live production application
- Monitoring in place
- User trained and onboarded

### Phase 10: Post-Launch (Ongoing)
**Goal**: Monitor, maintain, and enhance

- [ ] Monitor performance and errors
- [ ] Collect user feedback
- [ ] Prioritize feature requests
- [ ] Regular security updates
- [ ] Quarterly security audits
- [ ] Backup testing
- [ ] Disaster recovery drills
- [ ] Feature enhancements
- [ ] Performance optimization

---

## Estimated Costs (Monthly)

### Infrastructure:
- Database (AWS RDS): $50-200/month
- Application hosting (AWS/GCP): $50-150/month
- File storage (S3): $20-100/month
- Domain + SSL: $2-5/month
- Email service: $10-50/month

### Services:
- Claude API: $50-500/month (usage-based)
- Monitoring/logging: $20-100/month
- Backup storage: $10-50/month

### Total Estimated: $200-1,200/month
(Depending on usage volume)

---

## Tech Stack Summary

**Frontend:**
- Next.js 14+ (React, TypeScript)
- Tailwind CSS + shadcn/ui
- React Hook Form + Zod
- Recharts
- Tiptap (rich text)

**Backend:**
- Next.js API Routes
- Prisma ORM
- PostgreSQL
- Node.js

**Authentication:**
- NextAuth.js
- Google OAuth

**AI:**
- Anthropic Claude API

**Infrastructure:**
- AWS or Google Cloud Platform
- PostgreSQL (RDS or Cloud SQL)
- S3 or Cloud Storage
- CloudWatch or Cloud Logging

**Development:**
- GitHub
- GitHub Actions (CI/CD)
- Docker (optional)
- Jest + React Testing Library

---

## Next Steps

1. **Review this plan** - Discuss priorities and any missing features
2. **Choose infrastructure provider** - AWS vs GCP vs hybrid
3. **Set up accounts** - Google Cloud Console, Anthropic, cloud provider
4. **Sign BAAs** - Critical for HIPAA compliance
5. **Begin Phase 1** - Foundation and authentication

---

## Questions to Consider

1. **Private practice or school-employed?**
   - Affects billing features needed
   - May affect data ownership

2. **Number of users?**
   - Just your partner, or potential for other psychologists?
   - Affects multi-tenancy design

3. **Mobile access priority?**
   - Full mobile app vs responsive web?
   - Offline capabilities needed?

4. **Integration with school systems?**
   - Import data from student information systems?
   - Export to IEP platforms?

5. **Bilingual assessments?**
   - Spanish language support?
   - Multiple language reports?

6. **Telehealth/remote testing?**
   - Virtual testing session support?
   - Video conferencing integration?

7. **Budget constraints?**
   - Influences infrastructure choices
   - May affect feature prioritization

---

## Risk Considerations

1. **HIPAA Violations**: Most critical risk - requires careful implementation
2. **Data Loss**: Mitigated by robust backups and disaster recovery
3. **API Costs**: Claude API usage could become expensive - need cost controls
4. **Vendor Lock-in**: Choose portable technologies where possible
5. **Performance**: Large reports/documents could slow down - need optimization
6. **User Adoption**: Interface must be intuitive and save time vs current process
7. **Maintenance**: Ongoing updates and security patches required

---

*This is a living document - update as requirements evolve*
