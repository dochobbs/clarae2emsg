import { NextAuthOptions } from 'next-auth';
import GoogleProvider from 'next-auth/providers/google';
import { PrismaAdapter } from '@auth/prisma-adapter';
import { prisma } from '@/lib/db/prisma';
import { createAuditLog } from '@/lib/utils/audit';

export const authOptions: NextAuthOptions = {
  adapter: PrismaAdapter(prisma) as any,
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
      authorization: {
        params: {
          prompt: 'consent',
          access_type: 'offline',
          response_type: 'code',
        },
      },
    }),
  ],
  session: {
    strategy: 'jwt',
    maxAge: 15 * 60, // 15 minutes for HIPAA compliance
  },
  pages: {
    signIn: '/auth/signin',
    signOut: '/auth/signout',
    error: '/auth/error',
  },
  callbacks: {
    async signIn({ user, account }) {
      // Log authentication attempt
      if (user.id) {
        await createAuditLog({
          userId: user.id,
          action: 'login',
          resourceType: 'system',
          resourceId: 'auth',
          details: {
            provider: account?.provider,
          },
        });
      }
      return true;
    },
    async session({ session, token }) {
      if (session.user && token.sub) {
        session.user.id = token.sub;
      }
      return session;
    },
    async jwt({ token, user, account }) {
      if (user) {
        token.id = user.id;
      }
      return token;
    },
  },
  events: {
    async signOut({ token }) {
      // Log logout
      if (token.sub) {
        await createAuditLog({
          userId: token.sub,
          action: 'logout',
          resourceType: 'system',
          resourceId: 'auth',
        });
      }
    },
  },
};
