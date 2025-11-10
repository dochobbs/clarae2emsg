# PsychEval - Setup Guide

Complete guide to setting up the psychoeducational evaluation platform for development and production.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Local Development Setup](#local-development-setup)
- [Google OAuth Configuration](#google-oauth-configuration)
- [Anthropic Claude API Setup](#anthropic-claude-api-setup)
- [Database Configuration](#database-configuration)
- [Environment Variables](#environment-variables)
- [Running the Application](#running-the-application)
- [Production Deployment](#production-deployment)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software
- **Node.js** 18.17.0 or higher
- **npm** 9.0.0 or higher
- **PostgreSQL** 14.0 or higher
- **Git** (for version control)

### Required Accounts
- Google Cloud Platform account (for OAuth)
- Anthropic account (for Claude API)
- AWS or Google Cloud account (for production deployment)

## Local Development Setup

### 1. Clone and Install

```bash
# Clone the repository
git clone <repository-url>
cd psych-eval

# Install dependencies
npm install
```

### 2. Verify Installation

```bash
# Check Node version
node --version  # Should be 18.17.0+

# Check npm version
npm --version   # Should be 9.0.0+

# Check PostgreSQL
psql --version  # Should be 14.0+
```

## Google OAuth Configuration

### Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Select a project" → "New Project"
3. Name it "PsychEval" (or your preferred name)
4. Click "Create"

### Step 2: Enable Google+ API

1. In your project, go to "APIs & Services" → "Library"
2. Search for "Google+ API"
3. Click "Enable"

### Step 3: Configure OAuth Consent Screen

1. Go to "APIs & Services" → "OAuth consent screen"
2. Select "External" (unless you have Google Workspace)
3. Fill in the required fields:
   - App name: "PsychEval"
   - User support email: your email
   - Developer contact: your email
4. Add scopes:
   - `../auth/userinfo.email`
   - `../auth/userinfo.profile`
   - `openid`
5. Add test users (for development)
6. Save and continue

### Step 4: Create OAuth Credentials

1. Go to "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "OAuth 2.0 Client ID"
3. Application type: "Web application"
4. Name: "PsychEval Web Client"
5. Authorized JavaScript origins:
   - `http://localhost:3000` (development)
   - Your production URL (when deploying)
6. Authorized redirect URIs:
   - `http://localhost:3000/api/auth/callback/google` (development)
   - `https://yourdomain.com/api/auth/callback/google` (production)
7. Click "Create"
8. **Copy the Client ID and Client Secret** - you'll need these!

### Step 5: Domain Verification (Production Only)

1. Go to "APIs & Services" → "Domain verification"
2. Add your production domain
3. Follow verification steps

## Anthropic Claude API Setup

### Step 1: Create Account

1. Go to [Anthropic Console](https://console.anthropic.com/)
2. Sign up for an account
3. Verify your email

### Step 2: Generate API Key

1. Log in to Anthropic Console
2. Go to "API Keys"
3. Click "Create Key"
4. Name it "PsychEval Development" (or "Production")
5. **Copy the API key** - you won't see it again!

### Step 3: Set Up Billing

1. Go to "Billing"
2. Add payment method
3. Set usage limits (recommended: start with $50/month)

### Step 4: Business Associate Agreement (Production)

**CRITICAL for HIPAA compliance:**

1. Contact Anthropic sales team
2. Request Business Associate Agreement (BAA)
3. Review and sign BAA
4. Wait for confirmation
5. Use BAA-covered API key in production

**Do NOT use production data without a signed BAA!**

## Database Configuration

### Option 1: Local PostgreSQL

#### Install PostgreSQL (macOS)
```bash
brew install postgresql@14
brew services start postgresql@14
```

#### Install PostgreSQL (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

#### Create Database
```bash
# Switch to postgres user
sudo -u postgres psql

# In PostgreSQL prompt:
CREATE DATABASE psych_eval;
CREATE USER psych_user WITH ENCRYPTED PASSWORD 'your-secure-password';
GRANT ALL PRIVILEGES ON DATABASE psych_eval TO psych_user;
\q
```

### Option 2: Docker PostgreSQL

```bash
# Pull and run PostgreSQL
docker run --name psych-eval-db \
  -e POSTGRES_PASSWORD=your-secure-password \
  -e POSTGRES_USER=psych_user \
  -e POSTGRES_DB=psych_eval \
  -p 5432:5432 \
  -d postgres:14

# Verify it's running
docker ps
```

### Option 3: Cloud Database (Production)

#### AWS RDS PostgreSQL
1. Go to AWS RDS Console
2. Create database
3. Choose PostgreSQL 14+
4. Select instance size (t3.micro for dev, t3.medium+ for prod)
5. Enable encryption at rest
6. Enable automated backups
7. Set Multi-AZ for production
8. Note the endpoint URL

#### Google Cloud SQL
1. Go to Cloud SQL Console
2. Create instance
3. Choose PostgreSQL 14+
4. Configure machine type
5. Enable encryption
6. Enable automated backups
7. Note the connection name

## Environment Variables

### 1. Create `.env` File

```bash
cp .env.example .env
```

If `.env.example` doesn't exist, create `.env`:

```env
# Database
DATABASE_URL="postgresql://psych_user:your-secure-password@localhost:5432/psych_eval?schema=public"

# NextAuth
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="generate-a-secure-random-string-here"

# Google OAuth
GOOGLE_CLIENT_ID="your-google-client-id-here"
GOOGLE_CLIENT_SECRET="your-google-client-secret-here"

# Anthropic Claude API
ANTHROPIC_API_KEY="your-anthropic-api-key-here"

# Encryption (generate a secure 32-character string)
ENCRYPTION_KEY="your-32-character-encryption-key"

# File Storage
UPLOAD_DIR="./public/uploads"
MAX_FILE_SIZE="10485760"

# Session
SESSION_TIMEOUT="900000"
```

### 2. Generate Secure Keys

```bash
# Generate NEXTAUTH_SECRET (32+ random characters)
openssl rand -base64 32

# Generate ENCRYPTION_KEY (exactly 32 characters)
openssl rand -hex 16
```

### 3. Update Values

Replace all placeholder values with actual credentials from previous steps.

## Running the Application

### 1. Set Up Database Schema

```bash
# Generate Prisma Client
npx prisma generate

# Run migrations
npx prisma migrate dev --name init

# Optional: Seed database with sample data
npx prisma db seed
```

### 2. Start Development Server

```bash
npm run dev
```

The app will be available at `http://localhost:3000`

### 3. Test the Application

1. Open browser to `http://localhost:3000`
2. Click "Sign In with Google"
3. Authenticate with Google account
4. You should be redirected to the dashboard

### 4. Create First Student

1. Go to Dashboard
2. Click "Add New Student"
3. Fill in student information
4. Save

## Production Deployment

### AWS Deployment

#### 1. Set Up RDS Database

```bash
# Create database
aws rds create-db-instance \
  --db-instance-identifier psych-eval-prod \
  --db-instance-class db.t3.medium \
  --engine postgres \
  --master-username admin \
  --master-user-password <SECURE-PASSWORD> \
  --allocated-storage 20 \
  --storage-encrypted \
  --backup-retention-period 7 \
  --multi-az \
  --vpc-security-group-ids <SECURITY-GROUP-ID>
```

#### 2. Deploy Application

Using AWS Elastic Beanstalk:

```bash
# Install EB CLI
pip install awsebcli

# Initialize
eb init -p node.js psych-eval

# Create environment
eb create psych-eval-prod

# Deploy
eb deploy
```

#### 3. Set Environment Variables

```bash
eb setenv \
  DATABASE_URL="postgresql://..." \
  NEXTAUTH_URL="https://yourdomain.com" \
  NEXTAUTH_SECRET="..." \
  GOOGLE_CLIENT_ID="..." \
  GOOGLE_CLIENT_SECRET="..." \
  ANTHROPIC_API_KEY="..." \
  ENCRYPTION_KEY="..."
```

#### 4. Set Up S3 for File Storage

```bash
# Create bucket
aws s3 mb s3://psych-eval-documents

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket psych-eval-documents \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

#### 5. Configure SSL/TLS

Use AWS Certificate Manager to provision SSL certificate.

### Google Cloud Deployment

```bash
# Build for production
npm run build

# Deploy to Cloud Run
gcloud run deploy psych-eval \
  --image gcr.io/PROJECT_ID/psych-eval \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

## Troubleshooting

### Common Issues

#### Database Connection Error

```
Error: Can't reach database server at localhost:5432
```

**Solution:**
- Check if PostgreSQL is running: `pg_isready`
- Verify DATABASE_URL in `.env`
- Check firewall settings

#### OAuth Error: redirect_uri_mismatch

**Solution:**
- Check Google Cloud Console → Credentials
- Verify redirect URI matches exactly: `http://localhost:3000/api/auth/callback/google`
- No trailing slashes!

#### Prisma Client Error

```
Error: @prisma/client did not initialize yet
```

**Solution:**
```bash
npx prisma generate
npm run dev
```

#### Encryption Key Error

```
Error: ENCRYPTION_KEY not set
```

**Solution:**
- Generate key: `openssl rand -hex 16`
- Add to `.env`: `ENCRYPTION_KEY="..."`
- Restart server

#### Claude API Rate Limit

```
Error: 429 Too Many Requests
```

**Solution:**
- Check Anthropic Console for usage limits
- Increase rate limits or add retry logic
- Consider upgrading plan

### Getting Help

1. Check logs:
```bash
# Application logs
npm run dev

# Database logs
tail -f /usr/local/var/postgres/server.log  # macOS
sudo tail -f /var/log/postgresql/postgresql-14-main.log  # Linux
```

2. Verify environment:
```bash
# Check all environment variables are set
cat .env

# Test database connection
npx prisma db pull
```

3. Common commands:
```bash
# Reset database
npx prisma migrate reset

# View database in browser
npx prisma studio

# Check types
npx tsc --noEmit
```

## Security Checklist

Before going live:

- [ ] Change all default passwords
- [ ] Use strong, unique encryption keys
- [ ] Enable database encryption at rest
- [ ] Configure automated backups
- [ ] Set up SSL/TLS certificates
- [ ] Sign BAAs with all vendors
- [ ] Enable audit logging
- [ ] Set up monitoring and alerts
- [ ] Review HIPAA compliance checklist
- [ ] Conduct security audit
- [ ] Train all users

## Next Steps

1. ✅ Set up development environment
2. ✅ Test core features
3. Add your first student
4. Record some assessments
5. Generate a test report
6. Review AI-generated content
7. Customize for your workflow
8. Deploy to production (when ready)

---

**Need Help?** Check the main [README.md](README.md) and [PLANNING.md](../PLANNING.md) for additional guidance.
