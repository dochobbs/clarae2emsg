-- Supabase Database Schema for E2E Encrypted Messaging
-- This schema supports Signal Protocol encryption between iOS apps

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (extends Supabase auth.users)
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    user_type TEXT NOT NULL CHECK (user_type IN ('parent', 'provider')),
    full_name TEXT NOT NULL,
    email TEXT NOT NULL,
    apple_user_id TEXT UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Device keys for Signal Protocol
-- Each user can have multiple devices
CREATE TABLE public.device_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    device_id TEXT NOT NULL, -- Unique device identifier

    -- Signal Protocol keys (stored as base64)
    identity_key TEXT NOT NULL, -- Long-term identity key (public)
    signed_prekey TEXT NOT NULL, -- Signed pre-key (public)
    signed_prekey_signature TEXT NOT NULL,
    one_time_prekeys JSONB DEFAULT '[]'::jsonb, -- Array of one-time pre-keys

    -- APNs device token for push notifications
    apns_token TEXT,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(user_id, device_id)
);

-- Conversations (between parent and provider)
CREATE TABLE public.conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Ensure one conversation per parent-provider pair
    UNIQUE(parent_id, provider_id)
);

-- Messages (encrypted)
CREATE TABLE public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,

    -- Encrypted content (base64 encoded)
    -- Each recipient device gets a separately encrypted copy
    encrypted_content TEXT NOT NULL,

    -- Message metadata (not encrypted for delivery purposes)
    sender_device_id TEXT NOT NULL,
    recipient_device_id TEXT NOT NULL,

    -- Message status
    status TEXT NOT NULL DEFAULT 'sent' CHECK (status IN ('sent', 'delivered', 'read')),

    -- Timestamps
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    delivered_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Conversation metadata (for UI display)
CREATE TABLE public.conversation_metadata (
    conversation_id UUID PRIMARY KEY REFERENCES public.conversations(id) ON DELETE CASCADE,
    last_message_id UUID REFERENCES public.messages(id),
    last_message_at TIMESTAMP WITH TIME ZONE,

    -- Unread counts per user
    parent_unread_count INTEGER DEFAULT 0,
    provider_unread_count INTEGER DEFAULT 0,

    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_device_keys_user_id ON public.device_keys(user_id);
CREATE INDEX idx_conversations_parent_id ON public.conversations(parent_id);
CREATE INDEX idx_conversations_provider_id ON public.conversations(provider_id);
CREATE INDEX idx_messages_conversation_id ON public.messages(conversation_id);
CREATE INDEX idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX idx_messages_recipient_id ON public.messages(recipient_id);
CREATE INDEX idx_messages_created_at ON public.messages(created_at DESC);

-- Row Level Security (RLS) Policies

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_metadata ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can read all profiles but only update their own
CREATE POLICY "Public profiles are viewable by authenticated users"
    ON public.profiles FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    TO authenticated
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
    ON public.profiles FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = id);

-- Device keys: Users can manage their own device keys, others can read for encryption
CREATE POLICY "Device keys are viewable by authenticated users"
    ON public.device_keys FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Users can manage own device keys"
    ON public.device_keys FOR ALL
    TO authenticated
    USING (auth.uid() = user_id);

-- Conversations: Users can see conversations they're part of
CREATE POLICY "Users can view own conversations"
    ON public.conversations FOR SELECT
    TO authenticated
    USING (auth.uid() = parent_id OR auth.uid() = provider_id);

CREATE POLICY "Users can create conversations"
    ON public.conversations FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = parent_id OR auth.uid() = provider_id);

-- Messages: Users can see messages in their conversations
CREATE POLICY "Users can view messages in their conversations"
    ON public.messages FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.conversations
            WHERE id = conversation_id
            AND (parent_id = auth.uid() OR provider_id = auth.uid())
        )
    );

CREATE POLICY "Users can send messages in their conversations"
    ON public.messages FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid() = sender_id
        AND EXISTS (
            SELECT 1 FROM public.conversations
            WHERE id = conversation_id
            AND (parent_id = auth.uid() OR provider_id = auth.uid())
        )
    );

CREATE POLICY "Recipients can update message status"
    ON public.messages FOR UPDATE
    TO authenticated
    USING (auth.uid() = recipient_id)
    WITH CHECK (auth.uid() = recipient_id);

-- Conversation metadata: Users can view their own conversation metadata
CREATE POLICY "Users can view own conversation metadata"
    ON public.conversation_metadata FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.conversations
            WHERE id = conversation_id
            AND (parent_id = auth.uid() OR provider_id = auth.uid())
        )
    );

CREATE POLICY "Users can update conversation metadata"
    ON public.conversation_metadata FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.conversations
            WHERE id = conversation_id
            AND (parent_id = auth.uid() OR provider_id = auth.uid())
        )
    );

-- Functions and Triggers

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_device_keys_updated_at BEFORE UPDATE ON public.device_keys
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_conversations_updated_at BEFORE UPDATE ON public.conversations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update conversation metadata when a message is sent
CREATE OR REPLACE FUNCTION update_conversation_metadata()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.conversation_metadata (conversation_id, last_message_id, last_message_at)
    VALUES (NEW.conversation_id, NEW.id, NEW.sent_at)
    ON CONFLICT (conversation_id)
    DO UPDATE SET
        last_message_id = NEW.id,
        last_message_at = NEW.sent_at,
        parent_unread_count = CASE
            WHEN NEW.recipient_id = (SELECT parent_id FROM public.conversations WHERE id = NEW.conversation_id)
            THEN public.conversation_metadata.parent_unread_count + 1
            ELSE public.conversation_metadata.parent_unread_count
        END,
        provider_unread_count = CASE
            WHEN NEW.recipient_id = (SELECT provider_id FROM public.conversations WHERE id = NEW.conversation_id)
            THEN public.conversation_metadata.provider_unread_count + 1
            ELSE public.conversation_metadata.provider_unread_count
        END,
        updated_at = NOW();

    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_conversation_metadata_on_message
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_metadata();

-- Function to reset unread count
CREATE OR REPLACE FUNCTION reset_unread_count(p_conversation_id UUID, p_user_id UUID)
RETURNS VOID AS $$
DECLARE
    v_user_type TEXT;
BEGIN
    SELECT user_type INTO v_user_type FROM public.profiles WHERE id = p_user_id;

    IF v_user_type = 'parent' THEN
        UPDATE public.conversation_metadata
        SET parent_unread_count = 0, updated_at = NOW()
        WHERE conversation_id = p_conversation_id;
    ELSIF v_user_type = 'provider' THEN
        UPDATE public.conversation_metadata
        SET provider_unread_count = 0, updated_at = NOW()
        WHERE conversation_id = p_conversation_id;
    END IF;
END;
$$ language 'plpgsql' SECURITY DEFINER;
