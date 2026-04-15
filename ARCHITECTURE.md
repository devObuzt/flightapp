# CheckinCheckOut — System Architecture

**Version:** 1.0
**Date:** March 14, 2026
**Status:** Approved — Phase 1 Scoped

---

## Table of Contents

1. [Overview](#1-overview)
2. [Final Tech Stack Decision](#2-final-tech-stack-decision)
3. [High-Level System Diagram](#3-high-level-system-diagram)
4. [Repository Structure](#4-repository-structure)
5. [Frontend — Flutter (iOS & Android)](#5-frontend--flutter-ios--android)
6. [Frontend — Next.js (Web)](#6-frontend--nextjs-web)
7. [Backend — Python FastAPI](#7-backend--python-fastapi)
8. [AI Agent Architecture](#8-ai-agent-architecture)
9. [Voice Pipeline](#9-voice-pipeline)
10. [Data Layer](#10-data-layer)
11. [API Integration Layer](#11-api-integration-layer)
12. [Infrastructure & Deployment](#12-infrastructure--deployment)
13. [Security Model](#13-security-model)
14. [SEO Strategy (Web)](#14-seo-strategy-web)
15. [Phase 1 Roadmap](#15-phase-1-roadmap)
16. [Architecture Decision Record](#16-architecture-decision-record)

---

## 1. Overview

**CheckinCheckOut** is a multi-product travel booking platform powered by a conversational AI travel agent. Users interact via iOS, Android, or web — speaking or typing in their native language to an AI that searches, compares, recommends, and books travel products on their behalf.

### Product Scope

| Product | Phase 1 | Phase 2+ |
|---|---|---|
| Flights | Active (search + book) | — |
| Hotels | UI placeholder | Active |
| Car Rental | UI placeholder | Active |
| Events | UI placeholder | Active |
| Sport Games | UI placeholder | Active |
| Local Agents | UI placeholder | Active |
| All-Inclusive Packages | UI placeholder | Active |

### Core Design Principles

- **AI-first** — Every product interaction is routed through the AI agent, not just raw search forms
- **Voice-native** — Designed for voice-first interaction from the ground up, not as an afterthought
- **Provider abstraction** — All third-party APIs (Amadeus, Kaspi, future providers) sit behind a unified adapter layer
- **SEO-first web** — Next.js handles all web traffic; Flutter handles all native mobile
- **Multi-language** — AI agent detects and responds in the user's language (Arabic, Kazakh, Russian, English, and more)
- **Multi-currency** — All prices stored in original currency; display conversion at presentation layer

---

## 2. Final Tech Stack Decision

| Layer | Technology | Reason |
|---|---|---|
| iOS App | Flutter (Dart) | Native performance, shared codebase with Android |
| Android App | Flutter (Dart) | Single codebase with iOS, pixel-perfect UI |
| Web App | Next.js 15 (TypeScript) | SSR/SSG for SEO, real HTML, fast load |
| Backend API | Python — FastAPI | Best-in-class for AI/LLM work, async streaming |
| Background Jobs | Python — Celery + Redis | Async booking confirmations, notifications |
| AI Agent | Anthropic Claude API (Python SDK) | Tool use, streaming, multilingual |
| STT | Deepgram Nova-3 | Best accuracy for Arabic/Kazakh/Russian, streaming |
| TTS | ElevenLabs (app) / AWS Polly (phone) | Quality for app, economics for phone calls |
| Phone Calls | Twilio | CIS + MENA coverage, Media Streams WebSocket |
| Flight Data | Amadeus | Industry standard, covers CIS + MENA routes |
| Payment (KZ) | Kaspi Pay | Dominant fintech in Kazakhstan |
| Payment (Global) | Stripe | Card payments for non-KZ users |
| Database | PostgreSQL (Supabase) | Managed, RLS, Realtime, regional hosting |
| Cache | Redis (Upstash) | Serverless pricing, session + offer caching |
| File Storage | Cloudflare R2 | S3-compatible, zero egress fees |
| Email | Resend | Transactional email, React Email templates |
| SMS | Twilio | OTP + booking alerts |
| Push Notifications | Firebase (FCM + APNs) | Flutter-native via `firebase_messaging` |
| Error Tracking | Sentry | Flutter + Next.js + Python |
| CI/CD | GitHub Actions | Build, test, deploy all platforms |

---

## 3. High-Level System Diagram

```
                    ┌────────────────────────────────────────────────────────┐
                    │                     CLIENT LAYER                       │
                    │                                                        │
                    │  ┌─────────────────┐  ┌───────────────────────────┐   │
                    │  │  Flutter App    │  │     Next.js Web App       │   │
                    │  │  iOS + Android  │  │  (SSR + SSG + API Routes) │   │
                    │  │                 │  │                           │   │
                    │  │  - AI Chat UI   │  │  - SEO flight pages       │   │
                    │  │  - Voice input  │  │  - Server-side search     │   │
                    │  │  - Booking flow │  │  - Open Graph / meta      │   │
                    │  │  - Push notifs  │  │  - Sitemap / robots.txt   │   │
                    │  └────────┬────────┘  └─────────────┬─────────────┘   │
                    └──────────┼───────────────────────────┼────────────────┘
                               │                           │
                               └─────────────┬─────────────┘
                                             │ HTTPS / WSS
                               ┌─────────────▼─────────────┐
                               │   API GATEWAY             │
                               │   (Nginx / Caddy)         │
                               │   Rate Limit · SSL · Auth │
                               └─────────────┬─────────────┘
                                             │
              ┌──────────────────────────────┼──────────────────────────────┐
              │                              │                              │
   ┌──────────▼──────────┐      ┌────────────▼────────────┐    ┌───────────▼──────────┐
   │   AUTH SERVICE      │      │   AI AGENT SERVICE      │    │   BOOKING SERVICE    │
   │   FastAPI           │      │   FastAPI + Claude API  │    │   FastAPI            │
   │   JWT + OTP         │      │   Tools · SSE Stream    │    │   Flights → Products │
   └──────────┬──────────┘      └────────────┬────────────┘    └───────────┬──────────┘
              │                              │                              │
   ┌──────────▼──────────┐      ┌────────────▼────────────┐    ┌───────────▼──────────┐
   │   USER SERVICE      │      │   CONVERSATION STORE    │    │   INTEGRATION LAYER  │
   │   Profile · Prefs   │      │   Redis (active)        │    │   Amadeus · Kaspi    │
   └─────────────────────┘      │   Postgres (history)    │    │   Adapters           │
                                └────────────┬────────────┘    └──────────────────────┘
                                             │
              ┌──────────────────────────────┼──────────────────────────────┐
              │                              │                              │
   ┌──────────▼──────────┐      ┌────────────▼────────────┐    ┌───────────▼──────────┐
   │  NOTIFICATION SVC   │      │   SEARCH SERVICE        │    │   PAYMENT SERVICE    │
   │  FCM · Email · SMS  │      │   Flight search         │    │   Kaspi + Stripe     │
   └─────────────────────┘      │   (Phase 2: hotel, car) │    │   Webhooks           │
                                └─────────────────────────┘    └──────────────────────┘
                                             │
                                ┌────────────▼────────────┐
                                │   VOICE PIPELINE        │
                                │   Deepgram STT          │
                                │   ElevenLabs / Polly TTS│
                                │   Twilio Phone          │
                                └─────────────────────────┘

                    ┌────────────────────────────────────────────────────────┐
                    │                     DATA LAYER                         │
                    │   PostgreSQL (Supabase)  │  Redis (Upstash)  │  R2    │
                    └────────────────────────────────────────────────────────┘
```

---

## 4. Repository Structure

Two separate repositories (or a monorepo with clear boundaries):

```
checkincheckout/
│
├── apps/
│   ├── mobile/                      # Flutter app (iOS + Android)
│   │   ├── lib/
│   │   │   ├── main.dart
│   │   │   ├── core/                # Shared logic across features
│   │   │   │   ├── api/             # API client (Dio + Retrofit)
│   │   │   │   ├── models/          # Dart data models (Flight, Booking, etc.)
│   │   │   │   ├── services/        # Auth, storage, notification services
│   │   │   │   └── theme/           # Design tokens, colors, typography
│   │   │   ├── features/
│   │   │   │   ├── agent/           # AI chat + voice interface
│   │   │   │   ├── flights/         # Flight search + results + detail
│   │   │   │   ├── booking/         # Booking flow + passenger form
│   │   │   │   ├── payment/         # Kaspi / Stripe checkout
│   │   │   │   ├── bookings/        # Booking history + e-ticket
│   │   │   │   ├── profile/         # User settings, language, currency
│   │   │   │   └── (placeholders)/  # Hotels, cars, events (Phase 2)
│   │   │   └── router.dart          # Go Router navigation
│   │   ├── pubspec.yaml
│   │   └── README.md
│   │
│   ├── web/                         # Next.js 15 web app
│   │   ├── app/
│   │   │   ├── (marketing)/         # Public pages (SEO-optimized)
│   │   │   │   ├── page.tsx         # Homepage
│   │   │   │   ├── flights/
│   │   │   │   │   ├── page.tsx     # /flights — flight search landing
│   │   │   │   │   └── [route]/     # /flights/almaty-to-dubai — SEO pages
│   │   │   │   └── about/
│   │   │   ├── (app)/               # Authenticated app shell
│   │   │   │   ├── agent/           # AI chat interface
│   │   │   │   ├── flights/         # Search results + booking
│   │   │   │   ├── bookings/        # Booking history
│   │   │   │   └── profile/
│   │   │   └── api/                 # Next.js API routes (BFF layer)
│   │   │       ├── auth/
│   │   │       ├── agent/           # Proxies to Python API + handles streaming
│   │   │       ├── flights/
│   │   │       └── payments/
│   │   ├── components/
│   │   ├── lib/
│   │   ├── next.config.ts
│   │   └── package.json
│   │
│   └── api/                         # Python FastAPI backend
│       ├── app/
│       │   ├── main.py
│       │   ├── core/
│       │   │   ├── config.py        # Settings (pydantic-settings)
│       │   │   ├── database.py      # Async SQLAlchemy + Supabase
│       │   │   ├── redis.py         # Redis client
│       │   │   ├── security.py      # JWT, password hashing
│       │   │   └── dependencies.py  # FastAPI dependency injection
│       │   ├── models/              # SQLAlchemy ORM models
│       │   │   ├── user.py
│       │   │   ├── booking.py
│       │   │   ├── conversation.py
│       │   │   └── payment.py
│       │   ├── schemas/             # Pydantic request/response schemas
│       │   ├── routers/             # FastAPI routers
│       │   │   ├── auth.py
│       │   │   ├── users.py
│       │   │   ├── agent.py
│       │   │   ├── flights.py
│       │   │   ├── bookings.py
│       │   │   ├── payments.py
│       │   │   └── voice.py
│       │   ├── services/            # Business logic
│       │   │   ├── agent/
│       │   │   │   ├── session.py
│       │   │   │   ├── tools.py
│       │   │   │   ├── memory.py
│       │   │   │   └── streaming.py
│       │   │   ├── flight/
│       │   │   ├── payment/
│       │   │   └── notification/
│       │   ├── integrations/        # Third-party adapters
│       │   │   ├── amadeus/
│       │   │   ├── kaspi/
│       │   │   ├── deepgram/
│       │   │   ├── elevenlabs/
│       │   │   └── twilio/
│       │   └── workers/             # Celery background tasks
│       │       ├── celery_app.py
│       │       ├── booking_tasks.py
│       │       ├── notification_tasks.py
│       │       └── payment_tasks.py
│       ├── alembic/                 # DB migrations
│       ├── tests/
│       ├── requirements.txt
│       ├── Dockerfile
│       └── README.md
│
└── docs/
    ├── ARCHITECTURE.md              # This file
    ├── API.md                       # API reference
    └── DEPLOYMENT.md
```

---

## 5. Frontend — Flutter (iOS & Android)

### State Management
**Riverpod** — best-in-class for Flutter, supports async providers natively, testable.

```
lib/features/agent/
├── agent_screen.dart            # Full-screen chat + voice UI
├── providers/
│   ├── agent_session_provider.dart   # Current session state
│   ├── messages_provider.dart        # Message list, streaming
│   └── voice_provider.dart           # Recording, playback state
├── widgets/
│   ├── message_bubble.dart
│   ├── flight_card_widget.dart       # Rich tool result card
│   ├── voice_button.dart             # Push-to-talk / VAD
│   └── typing_indicator.dart
└── services/
    ├── agent_api_service.dart        # SSE streaming client
    └── voice_service.dart            # Audio record + playback
```

### Key Flutter Packages

| Package | Use |
|---|---|
| `flutter_riverpod` | State management |
| `go_router` | Navigation + deep links |
| `dio` | HTTP client |
| `web_socket_channel` | Voice WebSocket |
| `record` | Microphone recording |
| `just_audio` | TTS audio playback |
| `firebase_messaging` | Push notifications |
| `flutter_secure_storage` | JWT token storage |
| `local_auth` | Biometric re-auth |
| `flutter_localizations` | i18n (Arabic RTL support) |
| `cached_network_image` | Airline logo caching |
| `shimmer` | Loading skeletons |

### Navigation Structure (Go Router)

```
/                         → Agent chat (home)
/agent/:sessionId         → Resume conversation
/flights/search           → Manual search (power user fallback)
/flights/results          → Search results
/flights/:offerId         → Flight detail
/flights/:offerId/book    → Booking checkout
/bookings                 → Booking history
/bookings/:bookingId      → Booking detail + e-ticket
/profile                  → Settings, language, currency
/auth/login
/auth/register
```

### Arabic / RTL Support

Flutter has native RTL support. The app sets text direction based on the user's language preference:

```dart
MaterialApp(
  locale: userLocale,
  supportedLocales: [
    Locale('en'), Locale('ar'), Locale('ru'), Locale('kk'),
  ],
  localizationsDelegates: [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,  // handles RTL layout
  ],
)
```

---

## 6. Frontend — Next.js (Web)

### Why Next.js for Web (Not Flutter Web)

Flutter Web renders to Canvas — not HTML. This means:
- Google cannot index pages → zero organic search traffic
- "Cheap flights Almaty to Dubai" won't rank
- Screen readers and accessibility tools fail
- Initial load is ~2MB CanvasKit bundle

For a travel product, **SEO = revenue**. Next.js renders real semantic HTML.

### App Router Structure

```
app/
├── (marketing)/                     # Public, fully server-rendered, SEO-optimized
│   ├── page.tsx                     # Homepage — meta, OG image, hero
│   ├── flights/
│   │   ├── page.tsx                 # /flights — search landing page
│   │   └── [origin]-to-[dest]/
│   │       └── page.tsx             # /flights/almaty-to-dubai — programmatic SEO
│   ├── sitemap.ts                   # Dynamic sitemap generator
│   └── robots.ts
│
├── (app)/                           # Authenticated shell — client-side
│   ├── layout.tsx                   # Auth guard + global providers
│   ├── agent/
│   │   ├── page.tsx                 # AI chat interface
│   │   └── [sessionId]/page.tsx
│   ├── flights/
│   │   ├── search/page.tsx
│   │   ├── results/page.tsx
│   │   └── [offerId]/
│   │       ├── page.tsx
│   │       └── book/page.tsx
│   ├── bookings/
│   │   ├── page.tsx
│   │   └── [bookingId]/page.tsx
│   └── profile/page.tsx
│
└── api/                             # BFF — proxies to Python API
    ├── auth/[...route]/route.ts
    ├── agent/
    │   ├── chat/route.ts            # Streams SSE from Python to browser
    │   └── voice/route.ts
    ├── flights/
    │   ├── search/route.ts
    │   └── book/route.ts
    └── payments/
        ├── initiate/route.ts
        └── webhook/route.ts         # Kaspi / Stripe webhook receiver
```

### SEO Features

#### Programmatic Flight Route Pages
```typescript
// app/(marketing)/flights/[route]/page.tsx
// Generates: /flights/almaty-to-dubai, /flights/nur-sultan-to-istanbul, etc.

export async function generateStaticParams() {
  const popularRoutes = await getPopularRoutes(); // from DB
  return popularRoutes.map(r => ({ route: `${r.origin}-to-${r.destination}` }));
}

export async function generateMetadata({ params }) {
  return {
    title: `Cheap Flights ${params.origin} to ${params.destination} | CheckinCheckOut`,
    description: `Find and book the best flights from ${params.origin} to ${params.destination}. Compare prices, airlines, and schedules.`,
    openGraph: { ... },
    alternates: {
      languages: { 'ar': '/ar/flights/...', 'ru': '/ru/flights/...' }
    }
  };
}
```

#### Structured Data (Schema.org)
```typescript
// Flight search pages include JSON-LD for Google rich results
const structuredData = {
  "@context": "https://schema.org",
  "@type": "Flight",
  "departureAirport": { "@type": "Airport", "iataCode": "ALA" },
  "arrivalAirport": { "@type": "Airport", "iataCode": "DXB" },
}
```

#### Next.js SEO Checklist
- `generateMetadata()` on all public pages
- `sitemap.ts` — dynamic, covers all route pages
- `robots.ts` — allow public, block auth pages
- `next/image` — optimized images, correct aspect ratios
- Core Web Vitals optimized (LCP, CLS, FID)
- `hreflang` tags for multi-language pages (`/en/`, `/ar/`, `/ru/`)
- Canonical URLs on all pages
- Open Graph + Twitter Card metadata

### State Management (Web)

```
TanStack Query     → server state (flight search, bookings, conversations)
Zustand            → ephemeral UI state (search form, agent status, voice)
SSE / ReadableStream → AI agent token streaming
```

---

## 7. Backend — Python FastAPI

### Service Structure

```python
# app/routers/agent.py — AI agent endpoint with SSE streaming
@router.post("/agent/chat")
async def chat(
    request: ChatRequest,
    current_user: User = Depends(get_current_user),
):
    async def stream():
        async for chunk in agent_service.stream_response(
            session_id=request.session_id,
            message=request.message,
            user=current_user,
        ):
            yield f"data: {chunk.model_dump_json()}\n\n"

    return StreamingResponse(stream(), media_type="text/event-stream")
```

### Services Breakdown

| Module | Responsibility |
|---|---|
| `routers/auth.py` | Register, login, OTP verify, token refresh, logout |
| `routers/users.py` | Profile CRUD, language/currency preferences |
| `routers/agent.py` | Chat (SSE), voice (WebSocket), session management |
| `routers/flights.py` | Search, offer detail, pricing confirmation |
| `routers/bookings.py` | Create, retrieve, cancel, e-ticket download |
| `routers/payments.py` | Initiate, webhook receiver, refund |
| `routers/voice.py` | Twilio webhook, bidirectional WebSocket stream |

### Async Stack

- **FastAPI** — ASGI, fully async
- **SQLAlchemy 2.0** — async ORM (`asyncpg` driver)
- **aioredis** — async Redis client
- **httpx** — async HTTP for Amadeus, Kaspi calls
- **Celery + Redis** — background job queue

### Background Jobs (Celery)

```python
# workers/booking_tasks.py
@celery_app.task
def send_booking_confirmation(booking_id: str):
    # Generate PDF ticket → upload to R2 → send email via Resend
    ...

@celery_app.task
def process_payment_webhook(payload: dict):
    # Idempotent payment status update → trigger booking confirmation
    ...

@celery_app.task
def send_push_notification(user_id: str, message: dict):
    # Firebase FCM push
    ...
```

---

## 8. AI Agent Architecture

### Agent Overview

```
User message (text | transcribed voice)
         │
         ▼
┌────────────────────────────────────────────────────┐
│                 AGENT SESSION                       │
│                                                    │
│  1. Load context window (Redis L1 + Postgres L2)   │
│  2. Build dynamic system prompt                    │
│  3. Call Claude API (streaming, tool_use enabled)  │
│  4. Execute tool calls via Tool Router             │
│  5. Stream response tokens via SSE                 │
└────────────────────────────────────────────────────┘
         │
         ▼
┌────────────────────────────────────────────────────┐
│                  TOOL ROUTER                        │
│                                                    │
│  search_flights       → Amadeus integration        │
│  get_flight_detail    → Amadeus pricing endpoint   │
│  compare_flights      → Local comparison logic     │
│  lookup_iata_code     → Amadeus location API       │
│  initiate_booking     → Booking service            │
│  confirm_booking      → Payment initiation         │
│  get_booking          → Bookings DB                │
│  get_airport_info     → Amadeus reference data     │
└────────────────────────────────────────────────────┘
```

### Dynamic System Prompt

```python
def build_system_prompt(user: User, session: AgentSession) -> str:
    return f"""
You are CheckinCheckOut, a friendly and expert AI travel agent.

LANGUAGE: The user's preferred language is {user.language}.
Detect the language of the user's first message and respond in that language.
Maintain that language for the entire conversation unless the user explicitly switches.
Support: Arabic, English, Russian, Kazakh, and any other language naturally.

CURRENCY: Display all prices in {user.currency} when possible.

USER CONTEXT:
{user.travel_memory.summary if user.travel_memory else "New user, no travel history yet."}

TODAY'S DATE: {datetime.utcnow().strftime("%Y-%m-%d")}

CURRENT CAPABILITIES (Phase 1):
- You CAN search for flights, compare options, and complete bookings.
- For hotels, cars, events, and packages: acknowledge the request warmly and
  tell the user these features are coming soon.

BOOKING SAFETY:
- Always present a full summary before initiating payment.
- Never confirm a booking without explicit user approval.
- Always verify passport expiry is valid for the travel date.

TOOLS: Use tools whenever you need real data. Never guess flight prices,
availability, or schedules.
"""
```

### Conversation Memory Layers

| Layer | Storage | TTL | Content |
|---|---|---|---|
| L1 Active Window | Redis | 2 hours | Recent messages + tool calls (fits context) |
| L2 Session Summary | Postgres | Session lifetime | Compressed older turns (Claude-generated) |
| L3 User Profile Memory | Postgres | Permanent | Cross-session preferences, frequent routes |
| L4 Booking Draft | Redis + Postgres | 24 hours | Mid-checkout state, survives disconnect |

### Agent Session State Machine

```
IDLE → (user message) → THINKING → (response ready) → STREAMING
                                                            │
                                              (stream done) ▼
                                                     AWAITING_INPUT
                                                            │
                                            (booking starts)▼
                                                    BOOKING_FLOW
                                                    ├── COLLECTING_INFO
                                                    ├── PRICE_CONFIRM
                                                    ├── PAYMENT_PENDING
                                                    └── CONFIRMED → IDLE
```

---

## 9. Voice Pipeline

### Full Flow

```
Microphone (Flutter / Browser / Phone call)
         │
         │ Raw PCM audio chunks
         ▼
┌─────────────────────────┐
│   INPUT LAYER           │
│                         │
│  Flutter app    ───────►│ record package → WebSocket → API
│  Next.js web   ────────►│ MediaRecorder API → WebSocket → API
│  Twilio phone  ────────►│ Twilio Media Stream → WebSocket → API
└────────────┬────────────┘
             │
             ▼
┌─────────────────────────┐
│   DEEPGRAM Nova-3       │
│   Streaming STT         │
│                         │
│   Languages:            │
│   ar, en, ru, kk        │
│   Punctuation enabled   │
│   VAD (end of speech)   │
└────────────┬────────────┘
             │ transcript
             ▼
┌─────────────────────────┐
│   AI AGENT              │
│   (same as text path)   │
└────────────┬────────────┘
             │ response text
             ▼
┌─────────────────────────────────────────┐
│   TEXT-TO-SPEECH                        │
│                                         │
│   ElevenLabs streaming   ← App (mobile  │
│   (natural, emotional)     + web)       │
│                                         │
│   AWS Polly streaming    ← Phone calls  │
│   (lower cost per minute)               │
└────────────┬────────────────────────────┘
             │ audio chunks
             ▼
┌─────────────────────────┐
│   OUTPUT LAYER          │
│                         │
│  Flutter      ─────────►│ just_audio playback
│  Next.js web  ─────────►│ Web Audio API
│  Twilio phone ─────────►│ Twilio <Stream> TwiML
└─────────────────────────┘
```

### Twilio Phone Call Flow

```
Inbound call to CheckinCheckOut number
         │
         ▼
POST /api/voice/inbound   (Twilio webhook)
         │
         ▼
TwiML: <Connect><Stream url="wss://api.checkincheckout.app/ws/voice"/></Connect>
         │
         ▼
Bidirectional WebSocket established
         │
         ├── Incoming audio → Deepgram STT → Agent → Polly TTS → back to Twilio
         └── Booking confirmation → DTMF prompt ("Press 1 to confirm your booking")
```

### Latency Targets

| Segment | Target |
|---|---|
| Audio capture → STT transcript | < 300ms |
| Transcript → Claude first token | < 500ms |
| First token → TTS audio start | < 200ms |
| **Total perceived response latency** | **< 1.5 seconds** |

Achieved via: Deepgram streaming (not batch), Claude streaming API, ElevenLabs streaming endpoint, WebSocket throughout — no HTTP polling.

---

## 10. Data Layer

### PostgreSQL Schema

```sql
-- ═══════════════════════════════
-- USERS
-- ═══════════════════════════════

users (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email           TEXT UNIQUE,
  phone           TEXT UNIQUE,
  full_name       TEXT NOT NULL,
  avatar_url      TEXT,
  language        TEXT DEFAULT 'en',       -- ISO 639-1
  currency        TEXT DEFAULT 'USD',      -- ISO 4217
  country         TEXT,                    -- ISO 3166-1 alpha-2
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
)

user_sessions (
  id              UUID PRIMARY KEY,
  user_id         UUID REFERENCES users(id) ON DELETE CASCADE,
  refresh_token   TEXT NOT NULL,           -- stored hashed
  device_info     JSONB,
  platform        TEXT,                    -- flutter_ios | flutter_android | web
  expires_at      TIMESTAMPTZ NOT NULL,
  created_at      TIMESTAMPTZ DEFAULT now()
)

user_preferences (
  user_id              UUID PRIMARY KEY REFERENCES users(id),
  preferred_airlines   TEXT[],
  preferred_cabin      TEXT DEFAULT 'ECONOMY',
  preferred_seat       TEXT DEFAULT 'WINDOW',
  frequent_flyer_nos   JSONB,              -- {"EK": "123456"}
  travel_document      JSONB,              -- encrypted at app layer
  notifications_push   BOOLEAN DEFAULT true,
  notifications_email  BOOLEAN DEFAULT true,
  voice_enabled        BOOLEAN DEFAULT true,
  updated_at           TIMESTAMPTZ DEFAULT now()
)

-- ═══════════════════════════════
-- AI AGENT
-- ═══════════════════════════════

agent_sessions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES users(id),
  title           TEXT,                    -- "Flight to Dubai, March 2026"
  language        TEXT NOT NULL,
  channel         TEXT DEFAULT 'text',     -- text | voice_app | voice_phone
  status          TEXT DEFAULT 'active',   -- active | completed | abandoned
  summary         TEXT,                    -- compressed older turns
  booking_draft   JSONB,                   -- mid-booking state
  message_count   INTEGER DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
)

agent_messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id      UUID REFERENCES agent_sessions(id) ON DELETE CASCADE,
  role            TEXT NOT NULL,           -- user | assistant | tool_result
  content         TEXT,
  content_blocks  JSONB,                   -- full Claude message format
  tool_name       TEXT,
  tool_input      JSONB,
  tool_result     JSONB,
  tokens_used     INTEGER,
  latency_ms      INTEGER,
  created_at      TIMESTAMPTZ DEFAULT now()
)

user_travel_memory (
  user_id         UUID PRIMARY KEY REFERENCES users(id),
  summary         TEXT,                    -- "Travels for work, prefers aisle..."
  known_passengers  JSONB[],              -- family / colleagues
  frequent_routes   TEXT[],               -- ["ALA→DXB", "ALA→IST"]
  last_updated    TIMESTAMPTZ DEFAULT now()
)

-- ═══════════════════════════════
-- FLIGHTS
-- ═══════════════════════════════

flight_searches (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES users(id),
  session_id      UUID REFERENCES agent_sessions(id),
  origin          TEXT NOT NULL,           -- IATA
  destination     TEXT NOT NULL,           -- IATA
  departure_date  DATE NOT NULL,
  return_date     DATE,
  adults          INTEGER NOT NULL,
  children        INTEGER DEFAULT 0,
  infants         INTEGER DEFAULT 0,
  cabin_class     TEXT DEFAULT 'ECONOMY',
  raw_results     JSONB,                   -- cached Amadeus response
  result_count    INTEGER,
  search_ms       INTEGER,
  created_at      TIMESTAMPTZ DEFAULT now()
)

bookings (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID REFERENCES users(id),
  session_id      UUID REFERENCES agent_sessions(id),
  type            TEXT DEFAULT 'FLIGHT',   -- FLIGHT | HOTEL | CAR (Phase 2+)
  status          TEXT DEFAULT 'PENDING',  -- PENDING | CONFIRMED | CANCELLED | REFUNDED
  pnr             TEXT UNIQUE,
  provider        TEXT NOT NULL,           -- amadeus | kaspi_avia
  provider_ref    TEXT,
  offer_snapshot  JSONB NOT NULL,          -- full offer at booking time
  passengers      JSONB NOT NULL,          -- encrypted at app layer
  contact_email   TEXT NOT NULL,
  contact_phone   TEXT NOT NULL,
  total_amount    NUMERIC(12,2) NOT NULL,
  currency        TEXT NOT NULL,
  language        TEXT NOT NULL,
  confirmed_at    TIMESTAMPTZ,
  cancelled_at    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
)

booking_tickets (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id      UUID REFERENCES bookings(id),
  passenger_ref   TEXT NOT NULL,
  ticket_number   TEXT,
  seat_assignment TEXT,
  pdf_url         TEXT,                    -- Cloudflare R2 URL
  issued_at       TIMESTAMPTZ
)

-- ═══════════════════════════════
-- PAYMENTS
-- ═══════════════════════════════

payments (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id          UUID REFERENCES bookings(id),
  user_id             UUID REFERENCES users(id),
  provider            TEXT NOT NULL,       -- kaspi | stripe
  provider_payment_id TEXT,
  method              TEXT,                -- kaspi | card | apple_pay | google_pay
  status              TEXT DEFAULT 'PENDING',
  amount              NUMERIC(12,2) NOT NULL,
  currency            TEXT NOT NULL,
  exchange_rate       NUMERIC(10,6),
  idempotency_key     TEXT UNIQUE NOT NULL,
  provider_response   JSONB,
  created_at          TIMESTAMPTZ DEFAULT now(),
  updated_at          TIMESTAMPTZ DEFAULT now()
)
```

### Redis Key Patterns

```
session:{sessionId}:messages      → active message window (TTL: 2h)
session:{sessionId}:state         → agent state machine (TTL: 2h)
user:{userId}:ratelimit:agent     → per-user AI rate limit counter
flight:offer:{offerId}            → cached Amadeus offer (TTL: 15min)
amadeus:access_token              → Amadeus OAuth2 token (TTL: matches expiry)
booking:draft:{sessionId}         → mid-booking state (TTL: 24h)
voice:stream:{sessionId}          → active voice session context
celery:*                          → Celery task queue
```

### Multi-Currency

All monetary values stored in **original currency** with ISO 4217 code. Display conversion at presentation layer using daily exchange rates (ECB / Kazakhstan National Bank feed):

```
DB:      amount=85000, currency="KZT"
US user: displays "$185" (daily rate applied at render time)
Rule:    Never round-trip convert — always store original, convert for display only
```

---

## 11. API Integration Layer

### Provider Adapters

```python
# integrations/amadeus/client.py
class AmadeusClient:
    """OAuth2 token management + rate-limited HTTP client"""
    async def search_flights(self, params: FlightSearchParams) -> list[FlightOffer]: ...
    async def price_offer(self, offer_id: str) -> FlightOfferDetail: ...
    async def create_order(self, params: BookingParams) -> AmadeusOrder: ...
    async def get_locations(self, query: str) -> list[Airport]: ...

# integrations/amadeus/adapters.py
def adapt_flight_offer(raw: dict) -> FlightOffer:
    """Amadeus verbose JSON → clean FlightOffer model"""
    # The AI agent only ever sees FlightOffer — never Amadeus-specific shapes
```

### Circuit Breaker

Amadeus has transaction-per-second rate limits. The integration layer tracks error rates and opens a circuit when Amadeus is degraded:

```python
# If Amadeus error rate > 50% in last 60s → circuit OPEN
# Agent receives: ToolResult(error="Flight search temporarily unavailable. Please try again shortly.")
# Circuit attempts reset after 30s
```

### Kaspi Pay Flow

```
1. POST /payments/initiate  →  Kaspi creates payment link
2. User redirected to Kaspi app / QR code
3. Kaspi POSTs webhook → POST /payments/webhook
4. Verify HMAC signature
5. Idempotency check (prevent double-processing)
6. Update booking status → trigger confirmation Celery task
```

---

## 12. Infrastructure & Deployment

### Architecture

```
Cloudflare (DNS · DDoS Protection · CDN · R2 Storage)
                         │
        ┌────────────────┼────────────────┐
        │                │                │
   ┌────▼────┐     ┌─────▼─────┐    ┌────▼────────┐
   │ Next.js │     │  Flutter  │    │ FastAPI API  │
   │ (Vercel)│     │ App Store │    │ (Railway /   │
   │         │     │ Play Store│    │  Fly.io)     │
   └─────────┘     └───────────┘    └────┬────────┘
                                         │
                           ┌─────────────┼──────────────┐
                           │             │              │
                    ┌──────▼──────┐ ┌────▼────┐ ┌──────▼──────┐
                    │  Supabase   │ │ Upstash │ │ Celery      │
                    │  Postgres   │ │ Redis   │ │ Workers     │
                    └─────────────┘ └─────────┘ └─────────────┘
```

### Hosting Rationale

| Service | Provider | Reason |
|---|---|---|
| Next.js web | Vercel | Zero-config, edge SSR, preview URLs per PR |
| FastAPI | Railway or Fly.io | Simple Docker deploy, autoscaling, WebSocket support |
| Database | Supabase | Managed Postgres, RLS, Realtime, CIS region available |
| Redis | Upstash | Serverless, pay-per-request, no idle cost |
| File storage | Cloudflare R2 | Zero egress fees for PDF tickets + assets |
| Flutter CI | Codemagic or GitHub Actions | Flutter-optimized build pipelines |

### Environment Variables

```bash
# FastAPI (apps/api/.env)
DATABASE_URL=postgresql+asyncpg://...
REDIS_URL=redis://...
ANTHROPIC_API_KEY=
AMADEUS_CLIENT_ID=
AMADEUS_CLIENT_SECRET=
KASPI_API_KEY=
KASPI_WEBHOOK_SECRET=
STRIPE_SECRET_KEY=
STRIPE_WEBHOOK_SECRET=
TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_PHONE_NUMBER=
DEEPGRAM_API_KEY=
ELEVENLABS_API_KEY=
AWS_ACCESS_KEY_ID=          # For Polly (phone TTS)
AWS_SECRET_ACCESS_KEY=
RESEND_API_KEY=
FIREBASE_SERVICE_ACCOUNT=   # Push notifications
CLOUDFLARE_R2_ACCESS_KEY=
CLOUDFLARE_R2_SECRET_KEY=
CLOUDFLARE_R2_BUCKET=
JWT_SECRET_KEY=
JWT_REFRESH_SECRET_KEY=
ENCRYPTION_KEY=             # AES-256 for passport data

# Next.js (apps/web/.env.local)
NEXT_PUBLIC_API_URL=
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
```

### CI/CD Pipeline

```
GitHub Actions:

on: pull_request
  → pnpm lint + type-check (web)
  → pytest (api)
  → flutter analyze + flutter test (mobile)
  → Vercel preview deploy (web)

on: push to main
  → All checks above
  → Deploy Next.js → Vercel production
  → Deploy FastAPI → Railway production
  → Flutter build (CI artifact, manual submit to stores)
```

### Observability

```
Errors:    Sentry  (Flutter + Next.js + FastAPI)
Logs:      Structured JSON → Axiom or Logtail
Metrics:   Railway metrics (API) + Vercel Analytics (web)
Tracing:   OpenTelemetry on FastAPI — spans per tool call
           Track: token count, tool latency, total turn latency
AI Cost:   Log tokens per session → dashboard: cost per booking
Uptime:    Better Uptime (API health check every 60s)
```

---

## 13. Security Model

### Authentication

- JWT access tokens — 15-minute expiry
- Refresh tokens — 30-day expiry, rotation on every use, stored **hashed** in DB
- OTP via SMS (Twilio) for phone auth — 6-digit, 5-minute TTL
- Biometric re-auth on Flutter (local, no biometric data sent to server)
- Server-side session invalidation (logout deletes refresh token row)

### Payment Security

- Kaspi and Stripe process card details directly — server never touches raw card numbers
- PCI compliance fully delegated to payment providers
- `idempotency_key` on every payment operation — prevents double-charge on network retry
- Webhook endpoints verify HMAC signature before processing

### Data Security

- All DB connections over TLS
- Passport numbers and travel documents encrypted with AES-256-GCM at application layer before storage
- Decrypted only when needed for Amadeus API booking call — never logged
- Row-Level Security on Postgres: users can only query their own data
- API rate limiting per user per endpoint (Redis token bucket)
- `ANTHROPIC_API_KEY` is backend-only — never sent to Flutter or Next.js clients

### AI Security

- Claude tool inputs validated with Pydantic schemas before execution
- Agent cannot execute arbitrary code — only the pre-defined tool set
- Booking requires explicit double confirmation: AI presents summary → user confirms → payment initiated
- All conversations logged with user consent disclosed in Terms of Service

---

## 14. SEO Strategy (Web)

### Programmatic Pages

Generate static pages for top travel routes at build time:

```
/flights/almaty-to-dubai
/flights/nur-sultan-to-istanbul
/flights/almaty-to-moscow
/flights/almaty-to-london
... (top 500+ routes from booking data)
```

Each page includes: real pricing data (from last search cache), airline options, travel tips, and a prominent "Search Now" CTA that opens the AI agent.

### Technical SEO

| Feature | Implementation |
|---|---|
| Server-side rendering | Next.js App Router — all public pages SSR |
| Meta tags | `generateMetadata()` per page, dynamic titles |
| Sitemap | `/sitemap.ts` — dynamic, auto-includes new route pages |
| Robots | `/robots.ts` — allow public, block `/app/` |
| Structured data | JSON-LD (Flight, BreadcrumbList, FAQPage) |
| Image optimization | `next/image` with WebP, correct sizes |
| Core Web Vitals | Target: LCP < 2.5s, CLS < 0.1, FID < 100ms |
| Internationalization | `/en/`, `/ar/`, `/ru/`, `/kk/` with `hreflang` |
| Canonical URLs | All pages have explicit canonical |
| Open Graph | Rich previews for social sharing |

### Multi-Language URLs

```
English:  checkincheckout.app/en/flights/almaty-to-dubai
Arabic:   checkincheckout.app/ar/flights/almaty-to-dubai  (RTL page)
Russian:  checkincheckout.app/ru/flights/almaty-to-dubai
Kazakh:   checkincheckout.app/kk/flights/almaty-to-dubai
```

---

## 15. Phase 1 Roadmap

**Scope:** AI travel agent + flight search + flight booking only
**Team:** 2 Flutter devs, 1 Python backend dev, 1 Next.js dev, 1 AI/fullstack

### Milestone 1 — Foundation (Weeks 1–2)
**Goal:** All platforms compile, auth works, DB running

- [ ] Repository structure initialized (Flutter + Next.js + FastAPI)
- [ ] Supabase project + initial Alembic migrations (users, sessions, preferences)
- [ ] FastAPI auth: register, login (email + phone), OTP, JWT issuance
- [ ] Flutter app: auth screens, JWT storage (flutter_secure_storage), Go Router
- [ ] Next.js app: auth pages, middleware JWT guard
- [ ] CI pipeline: lint + test on PR for all three platforms

**Deliverable:** Login on all three platforms, session persists.

### Milestone 2 — Flight Search (Weeks 3–4)
**Goal:** Users can search and browse flights

- [ ] Amadeus OAuth2 client (token caching in Redis)
- [ ] Flight offers search endpoint (`POST /flights/search`)
- [ ] Airport IATA lookup + autocomplete (`GET /flights/airports`)
- [ ] Amadeus → `FlightOffer` adapter
- [ ] Redis caching (15-min TTL matching Amadeus offer validity)
- [ ] Flutter flight search UI (search form + results list + detail)
- [ ] Next.js flight search UI (same flow, server-side first render)
- [ ] Programmatic SEO route pages (top 100 routes, static generation)

**Deliverable:** Full flight search on Flutter and web.

### Milestone 3 — AI Agent — Text (Weeks 5–6)
**Goal:** Chat with AI to search flights

- [ ] Agent session management (`agent_sessions` + `agent_messages`)
- [ ] Claude API integration with tool_use + streaming (FastAPI SSE)
- [ ] Dynamic system prompt builder (language, user context, phase constraints)
- [ ] Tool executor: `search_flights`, `lookup_iata_code`, `compare_flights`, `get_flight_offer_detail`
- [ ] Flutter agent chat UI (streaming bubbles, tool result cards, FlightCard widget)
- [ ] Next.js agent chat UI (SSE stream from Python through Next.js API route)
- [ ] Conversation memory: Redis L1 + Postgres L2 summary generation
- [ ] Multi-language verification (AR, EN, RU, KK)

**Deliverable:** Full conversational flight search by text.

### Milestone 4 — Booking & Payment (Weeks 7–8)
**Goal:** End-to-end book and pay

- [ ] Passenger details form (Flutter + Next.js)
- [ ] Booking draft persistence (Redis + Postgres)
- [ ] Amadeus flight-orders endpoint (PNR creation)
- [ ] Kaspi Pay integration (payment link + webhook)
- [ ] Stripe integration (card payments)
- [ ] Webhook endpoint (HMAC verification + idempotency)
- [ ] Agent booking tools: `initiate_booking`, `confirm_booking`, `get_booking`
- [ ] E-ticket PDF generation + upload to R2 + email via Resend
- [ ] Booking history screen (Flutter + Next.js)
- [ ] Push notification on booking confirmation (Firebase FCM)

**Deliverable:** Full end-to-end: search → chat → book → pay → e-ticket.

### Milestone 5 — Voice Agent (Weeks 9–10)
**Goal:** Speak to the AI agent

- [ ] Deepgram streaming STT (WebSocket, AR/EN/RU/KK)
- [ ] ElevenLabs streaming TTS integration
- [ ] Voice WebSocket handler on FastAPI
- [ ] Flutter voice UI (push-to-talk button + VAD + audio playback)
- [ ] Next.js voice UI (MediaRecorder + Web Audio API)
- [ ] End-to-end latency tuning (target < 1.5s total)

**Deliverable:** Voice-to-voice AI travel agent on mobile and web.

### Milestone 6 — Phone & Launch (Weeks 11–12)
**Goal:** Production launch

- [ ] Twilio inbound phone number (TwiML + Media Streams WebSocket)
- [ ] AWS Polly TTS for phone calls
- [ ] DTMF booking confirmation ("Press 1 to confirm")
- [ ] Sentry integration (Flutter + Next.js + FastAPI)
- [ ] Rate limiting enforcement per user
- [ ] Security review (encrypted docs, audit log, CSP headers)
- [ ] App Store submission (iOS + Android)
- [ ] Vercel + Railway production environments
- [ ] Load testing (Amadeus rate limit simulation, 100 concurrent sessions)
- [ ] Monitoring dashboards (AI cost/session, booking conversion, voice latency)
- [ ] Onboarding flow (first session guide, all supported languages)

**Deliverable:** Live on App Store, Play Store, and web.

---

## 16. Architecture Decision Record

| Decision | Choice | Rationale |
|---|---|---|
| Mobile framework | Flutter | Native performance, single iOS+Android codebase, superior for complex booking UI |
| Web framework | Next.js 15 | Flutter Web uses Canvas (no SEO); Next.js renders real HTML, critical for flight search traffic |
| Backend language | Python | AI/LLM work is Python-native, better ecosystem for Deepgram/ElevenLabs/Anthropic |
| API framework | FastAPI | Async-first, Pydantic validation, streaming SSE/WebSocket, OpenAPI docs auto-generated |
| AI provider | Anthropic Claude (claude-sonnet-4-6) | Tool use, multilingual, streaming, best reasoning for booking flows |
| STT | Deepgram Nova-3 | Best accuracy for Arabic, Russian, Kazakh; streaming WebSocket (not batch) |
| TTS (app) | ElevenLabs | Most natural voice quality, streaming endpoint, emotional tone |
| TTS (phone) | AWS Polly | Per-character pricing, cheaper for high phone call volume |
| Flight data | Amadeus | Industry standard, covers CIS + MENA routes, Kazakh carrier support |
| Payment (KZ) | Kaspi Pay | Dominant fintech in Kazakhstan, required for local market penetration |
| Payment (global) | Stripe | Card payments for non-KZ users, Apple Pay / Google Pay |
| Database | Supabase (Postgres) | Managed, RLS, Realtime, CIS region available |
| Cache | Upstash Redis | Serverless pricing, no idle cost at Phase 1 scale |
| File storage | Cloudflare R2 | S3-compatible API, zero egress fees (vs AWS S3) |
| Background jobs | Celery + Redis | Python-native, reliable for booking confirmations and notifications |
| State (Flutter) | Riverpod | Best async state management for Flutter, testable |
| State (web) | TanStack Query + Zustand | Industry standard, separates server vs UI state |
| Push notifications | Firebase (FCM + APNs) | Flutter-native via `firebase_messaging`, cross-platform |
| Email | Resend | Modern transactional email, great DX |
| Error tracking | Sentry | Supports Flutter + Next.js + Python in one dashboard |
