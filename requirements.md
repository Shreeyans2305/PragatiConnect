# Requirements Document: Pragati Connect

## Executive Summary

### The Problem
India's 450+ million informal workers—artisans, daily wage laborers, domestic workers—operate in an economic blind spot. They lack access to fair price discovery, struggle with wage negotiations due to information asymmetry, and miss critical government welfare schemes designed for them. This perpetuates exploitation and economic vulnerability.

### The Solution
Pragati Connect is a unified economic assistant that bridges informal workers to the formal economy through three accessible interfaces: a visual price estimator (mobile app), a voice negotiator (phone call), and an opportunity alert system (WhatsApp). By meeting users where they are—with low-literacy voice interfaces, local language support, and low-bandwidth optimization—we democratize economic empowerment for India's backbone workforce.

### Why This Matters
Fair price discovery alone can increase artisan income by 15-30%. Access to government schemes (PM-KISAN, PMAY, etc.) provides safety nets worth ₹6,000-₹2,50,000 per beneficiary annually. Voice-based negotiation practice builds confidence and reduces wage exploitation. Pragati Connect transforms economic participation from survival to sustainability.

## User Personas

### Persona 1: Radha the Weaver
- **Age:** 38
- **Location:** Semi-urban Tamil Nadu
- **Trade:** Handloom saree weaving
- **Literacy:** Can read Tamil at basic level, no English
- **Tech Access:** Feature phone (primary), occasional smartphone access via family
- **Pain Points:**
  - Middlemen offer ₹800 for sarees she could sell for ₹2,500 directly
  - Unaware of Handloom Weaver Comprehensive Welfare Scheme
  - Struggles to articulate value of intricate designs to buyers
- **Goals:** Get fair prices for her work, access government loans for better loom equipment
- **Pragati Connect Usage:** Uses Visual Price Estimator via daughter's phone to photograph sarees and get market rates; receives WhatsApp alerts about weaver schemes

### Persona 2: Raju the Carpenter
- **Age:** 45
- **Location:** Rural Uttar Pradesh
- **Trade:** Furniture carpentry and home repairs
- **Literacy:** Minimal (can recognize numbers, limited Hindi reading)
- **Tech Access:** Basic feature phone with voice call capability
- **Pain Points:**
  - Customers negotiate aggressively; he accepts low rates due to uncertainty
  - Misses out on PMAY (housing scheme) benefits despite eligibility
  - No practice negotiating in formal settings
- **Goals:** Earn fair daily wages (₹600-800 vs current ₹400), secure housing assistance
- **Pragati Connect Usage:** Calls Voice Negotiator to practice wage discussions in Hindi before client meetings; receives voice alerts about construction worker schemes

## Glossary

- **Pragati_Connect**: The unified economic assistant system serving India's informal workforce
- **Visual_Price_Estimator**: Mobile application interface for photo-based price analysis
- **Voice_Negotiator**: Phone-based voice AI interface for wage queries and negotiation practice
- **Opportunity_Alert**: WhatsApp-based chatbot for government scheme notifications
- **Central_Brain**: Backend AI orchestration layer processing requests from all three interfaces
- **Multimodal_LLM**: Large language model capable of processing both images and text (Claude 3.5 Sonnet)
- **Knowledge_Base**: RAG system storing government scheme information and eligibility criteria
- **User_Profile**: Stored user data including trade, location, language preference, and interaction history
- **Fair_Market_Price**: Price estimate based on complexity analysis, material assessment, and regional market data
- **Low_Bandwidth_Mode**: Optimized data transmission for areas with poor connectivity (<2G speeds)

## Requirements

### Requirement 1: Visual Price Estimator - Image Analysis

**Priority:** P0 (MVP Essential)

**User Story:** As an artisan like Radha, I want to photograph my handcrafted product and receive a fair market price estimate in my local language, so that I can negotiate confidently with buyers and avoid exploitation.

#### Acceptance Criteria

1. WHEN a user uploads a product image via the mobile interface, THE Visual_Price_Estimator SHALL accept JPEG/PNG formats up to 5MB
2. WHEN an image is received, THE Central_Brain SHALL invoke the Multimodal_LLM to analyze product complexity, materials, and craftsmanship quality
3. WHEN analysis is complete, THE System SHALL return a fair market price range (min-max) within 8 seconds
4. WHEN displaying results, THE Visual_Price_Estimator SHALL present prices in Indian Rupees with voice narration in the user's selected language
5. IF image quality is insufficient for analysis, THEN THE System SHALL request a clearer photo with voice guidance

### Requirement 2: Visual Price Estimator - Voice Query Interface

**Priority:** P0 (MVP Essential)

**User Story:** As a low-literacy user like Raju, I want to ask questions about the price estimate using my voice in Hindi, so that I can understand the reasoning without reading complex text.

#### Acceptance Criteria

1. WHEN a user taps the voice button after receiving a price estimate, THE Visual_Price_Estimator SHALL activate voice input using Deepgram STT
2. WHEN a voice query is received in a supported language (Hindi, Tamil, Telugu, Bengali), THE Central_Brain SHALL process the query and generate a contextual response
3. WHEN responding to queries, THE System SHALL use text-to-speech (ElevenLabs/Azure) to narrate explanations in the user's language
4. WHEN a user asks "Why this price?", THE System SHALL explain factors like material cost, labor complexity, and regional market rates
5. THE System SHALL support follow-up questions within the same conversation context for up to 5 minutes

### Requirement 3: Voice Negotiator - Phone-Based Access

**Priority:** P0 (MVP Essential)

**User Story:** As a daily wage worker like Raju with only a feature phone, I want to call a phone number and practice wage negotiations in Hindi, so that I can build confidence before meeting clients.

#### Acceptance Criteria

1. THE Voice_Negotiator SHALL provide a toll-free or local-rate phone number accessible from any phone in India
2. WHEN a user calls the number, THE System SHALL answer within 3 rings and greet the user in Hindi (default) with language selection options
3. WHEN a user states their trade and location, THE Voice_Negotiator SHALL provide typical wage ranges for that trade in that region
4. WHEN a user requests negotiation practice, THE System SHALL simulate a client conversation with realistic objections and counteroffers
5. WHEN the call ends, THE System SHALL provide a summary of key negotiation points via SMS if the user consents

### Requirement 4: Voice Negotiator - Low-Latency Conversation

**Priority:** P0 (MVP Essential)

**User Story:** As a user calling from a rural area with poor connectivity, I want the voice assistant to respond quickly without long pauses, so that the conversation feels natural and doesn't waste my phone balance.

#### Acceptance Criteria

1. THE Voice_Negotiator SHALL maintain end-to-end latency below 2 seconds from user speech end to AI response start
2. WHEN network conditions degrade, THE System SHALL prioritize voice quality over feature richness (e.g., disable background music)
3. THE Voice_Negotiator SHALL use Vapi.ai's optimized voice pipeline with Deepgram for real-time transcription
4. WHEN a user pauses mid-sentence, THE System SHALL wait 1.5 seconds before processing to avoid cutting off speech
5. THE System SHALL handle network interruptions gracefully by resuming context when connection restores within 30 seconds

### Requirement 5: Opportunity Alert - WhatsApp Scheme Notifications

**Priority:** P0 (MVP Essential)

**User Story:** As an informal worker like Radha, I want to receive WhatsApp messages about government schemes I'm eligible for, so that I don't miss financial assistance opportunities.

#### Acceptance Criteria

1. WHEN a user registers via any interface, THE System SHALL request WhatsApp opt-in and store the phone number in User_Profile
2. WHEN a new government scheme matching the user's trade and location is added to the Knowledge_Base, THE Opportunity_Alert SHALL send a notification within 24 hours
3. WHEN sending notifications, THE System SHALL use simple language with key details: scheme name, benefit amount, eligibility, and application deadline
4. WHEN a user replies to a notification, THE Opportunity_Alert SHALL answer questions about eligibility and application process using the Knowledge_Base
5. THE System SHALL limit notifications to 2 per week per user to avoid spam perception

### Requirement 6: Opportunity Alert - Scheme Eligibility Matching

**Priority:** P1 (Future Enhancement)

**User Story:** As a user, I want the system to automatically determine which schemes I qualify for based on my profile, so that I only receive relevant opportunities.

#### Acceptance Criteria

1. WHEN a User_Profile is created or updated, THE Central_Brain SHALL query the Knowledge_Base to identify matching schemes based on trade, location, age, and income bracket
2. WHEN evaluating eligibility, THE System SHALL apply scheme-specific rules (e.g., "weavers in Tamil Nadu under BPL category")
3. THE System SHALL rank schemes by potential benefit value and application deadline urgency
4. WHEN a user's profile changes (e.g., new trade added), THE System SHALL re-evaluate eligibility and notify about newly matched schemes
5. THE Knowledge_Base SHALL store eligibility criteria in structured format for automated matching

### Requirement 7: User Profile Management

**Priority:** P0 (MVP Essential)

**User Story:** As a system user, I want my trade, language preference, and location to be remembered across all three interfaces, so that I get personalized assistance without repeating information.

#### Acceptance Criteria

1. WHEN a user first interacts via any interface, THE System SHALL create a User_Profile with phone number as unique identifier
2. THE User_Profile SHALL store: phone number, primary trade, secondary trades (optional), location (district level), preferred language, and registration timestamp
3. WHEN a user accesses any interface (Visual, Voice, WhatsApp), THE System SHALL retrieve the User_Profile and personalize the experience
4. WHEN a user updates profile information via one interface, THE changes SHALL be reflected across all interfaces immediately
5. THE System SHALL store User_Profile data in DynamoDB with phone number as partition key

### Requirement 8: Multimodal LLM Integration - Vision Analysis

**Priority:** P0 (MVP Essential)

**User Story:** As the system, I need to analyze product images to extract complexity, materials, and quality indicators, so that I can generate accurate price estimates.

#### Acceptance Criteria

1. THE Central_Brain SHALL use Amazon Bedrock with Claude 3.5 Sonnet model for image analysis
2. WHEN analyzing an image, THE System SHALL generate a structured prompt requesting: product category, materials identified, craftsmanship complexity (1-10 scale), and condition assessment
3. THE Multimodal_LLM SHALL return analysis results in JSON format within 6 seconds
4. WHEN materials are ambiguous, THE System SHALL request clarification via voice interface before finalizing price estimate
5. THE System SHALL log all image analysis requests with timestamps for performance monitoring

### Requirement 9: Knowledge Base for Government Schemes

**Priority:** P0 (MVP Essential)

**User Story:** As the system, I need access to up-to-date government scheme information with eligibility criteria, so that I can match users to relevant opportunities accurately.

#### Acceptance Criteria

1. THE System SHALL use Knowledge Bases for Bedrock (RAG) to store and retrieve government scheme information
2. THE Knowledge_Base SHALL contain: scheme name, administering ministry, benefit description, eligibility criteria, application process, and deadlines
3. WHEN queried, THE Knowledge_Base SHALL return relevant schemes ranked by semantic similarity to the query
4. THE System SHALL support manual updates to the Knowledge_Base for new schemes or policy changes
5. WHEN a scheme deadline passes, THE System SHALL mark it as inactive and exclude it from notifications

### Requirement 10: Low-Bandwidth Optimization

**Priority:** P0 (MVP Essential)

**User Story:** As a user in a rural area with 2G connectivity, I want the mobile app to work without long loading times or failures, so that I can access price estimates despite poor internet.

#### Acceptance Criteria

1. THE Visual_Price_Estimator SHALL compress uploaded images to maximum 500KB before transmission while maintaining analysis quality
2. WHEN network speed is detected below 100 kbps, THE System SHALL enable Low_Bandwidth_Mode with text-only responses and deferred voice playback
3. THE mobile app SHALL cache the last 5 price estimates locally for offline viewing
4. WHEN uploading images, THE System SHALL show upload progress and allow cancellation if taking longer than 15 seconds
5. THE System SHALL use progressive image loading for result displays (low-res preview first, then full quality)

### Requirement 11: Multi-Language Support

**Priority:** P0 (MVP Essential)

**User Story:** As a Tamil-speaking user like Radha, I want all voice interactions and text displays in Tamil, so that I can use the system without language barriers.

#### Acceptance Criteria

1. THE System SHALL support Hindi, Tamil, Telugu, and Bengali for voice input, voice output, and text display
2. WHEN a user selects a language preference, THE System SHALL store it in User_Profile and apply it to all interfaces
3. WHEN generating voice output, THE System SHALL use language-specific TTS models with natural prosody
4. THE System SHALL translate LLM responses from English to the user's language before voice synthesis
5. WHEN a user speaks in an unsupported language, THE System SHALL detect it and offer to switch to the nearest supported language

### Requirement 12: Data Privacy and Security

**Priority:** P0 (MVP Essential)

**User Story:** As a user sharing my trade and location information, I want my data to be secure and not shared with third parties, so that I can trust the system with my personal details.

#### Acceptance Criteria

1. THE System SHALL encrypt all data in transit using TLS 1.3
2. THE System SHALL encrypt User_Profile data at rest in DynamoDB using AWS KMS
3. THE System SHALL NOT share user data with third parties without explicit consent
4. WHEN storing images in S3, THE System SHALL apply server-side encryption and set expiration policies (30 days)
5. THE System SHALL provide a data deletion option accessible via WhatsApp command "/delete-my-data"

### Requirement 13: API Gateway and Backend Architecture

**Priority:** P0 (MVP Essential)

**User Story:** As the system, I need a scalable backend architecture that handles requests from three different interfaces efficiently, so that all users get consistent performance.

#### Acceptance Criteria

1. THE System SHALL expose RESTful APIs via AWS API Gateway for mobile app integration
2. THE Central_Brain SHALL be implemented as AWS Lambda functions triggered by API Gateway and Vapi webhooks
3. WHEN a request is received, THE System SHALL route it to the appropriate Lambda function based on interface type (visual, voice, WhatsApp)
4. THE System SHALL implement request validation and authentication using API keys for mobile app and webhook signatures for Vapi/WhatsApp
5. THE System SHALL log all API requests to CloudWatch for monitoring and debugging

### Requirement 14: Voice Webhook Integration

**Priority:** P0 (MVP Essential)

**User Story:** As the system, I need to receive real-time voice transcriptions from Vapi.ai and respond with appropriate actions, so that voice conversations flow naturally.

#### Acceptance Criteria

1. THE System SHALL expose a webhook endpoint POST /api/v1/voice-webhook for Vapi.ai integration
2. WHEN Vapi sends a transcription event, THE System SHALL parse the user's intent (price query, negotiation practice, scheme question)
3. THE System SHALL generate a response using the Central_Brain and return it to Vapi within 1.5 seconds
4. WHEN a conversation requires context from previous turns, THE System SHALL retrieve conversation history from DynamoDB
5. THE System SHALL handle Vapi webhook retries gracefully and return idempotent responses

### Requirement 15: Error Handling and Fallbacks

**Priority:** P0 (MVP Essential)

**User Story:** As a user, I want the system to handle errors gracefully and guide me to alternative actions, so that I don't get stuck or frustrated.

#### Acceptance Criteria

1. WHEN the Multimodal_LLM fails to analyze an image, THE System SHALL return a user-friendly error message and suggest retaking the photo
2. WHEN voice transcription confidence is below 70%, THE System SHALL ask the user to repeat their question
3. WHEN the Knowledge_Base query returns no results, THE System SHALL offer to connect the user with a human helpline (future feature placeholder)
4. WHEN API latency exceeds 10 seconds, THE System SHALL timeout gracefully and notify the user to retry
5. THE System SHALL log all errors to CloudWatch with severity levels for triage

### Requirement 16: Analytics and Monitoring

**Priority:** P1 (Future Enhancement)

**User Story:** As a system administrator, I want to monitor usage patterns and performance metrics, so that I can optimize the system and demonstrate impact.

#### Acceptance Criteria

1. THE System SHALL track daily active users across all three interfaces
2. THE System SHALL measure average response latency for image analysis, voice queries, and WhatsApp messages
3. THE System SHALL count successful price estimates, negotiation practice sessions, and scheme notifications sent
4. THE System SHALL store analytics data in DynamoDB with daily aggregation
5. THE System SHALL expose a dashboard endpoint (admin-only) showing key metrics

### Requirement 17: Negotiation Practice Scenarios

**Priority:** P1 (Future Enhancement)

**User Story:** As a user practicing negotiations, I want realistic scenarios with different client personalities, so that I'm prepared for various real-world situations.

#### Acceptance Criteria

1. THE Voice_Negotiator SHALL offer three scenario types: aggressive bargainer, polite but firm client, and corporate buyer
2. WHEN a user selects a scenario, THE System SHALL simulate that client personality with appropriate language and tactics
3. THE System SHALL provide real-time feedback during practice (e.g., "Good point about quality!" or "Try mentioning your experience")
4. WHEN practice ends, THE System SHALL summarize strengths and areas for improvement
5. THE System SHALL store practice session history in User_Profile for progress tracking

### Requirement 18: Offline Price Estimate Cache

**Priority:** P1 (Future Enhancement)

**User Story:** As a user who frequently makes similar products, I want to access previous price estimates offline, so that I can reference them without internet connectivity.

#### Acceptance Criteria

1. THE Visual_Price_Estimator mobile app SHALL cache the last 10 price estimates with thumbnails locally
2. WHEN offline, THE app SHALL display cached estimates with a "Last updated" timestamp
3. WHEN connectivity returns, THE app SHALL sync cached data and refresh estimates if market conditions changed significantly
4. THE app SHALL allow users to mark specific estimates as "favorites" for permanent offline access
5. THE cache SHALL not exceed 50MB of device storage

## Non-Functional Requirements

### Performance

1. **Image Analysis Latency:** THE System SHALL return price estimates within 8 seconds of image upload (P0)
2. **Voice Response Latency:** THE Voice_Negotiator SHALL maintain end-to-end latency below 2 seconds (P0)
3. **WhatsApp Message Delivery:** THE Opportunity_Alert SHALL deliver messages within 5 seconds of trigger event (P0)
4. **API Throughput:** THE System SHALL handle 100 concurrent requests without degradation (P1)

### Scalability

1. **User Capacity:** THE System SHALL support 10,000 registered users during initial deployment phase (P0)
2. **Storage Growth:** THE System SHALL accommodate 1GB of image storage and 100MB of user profile data initially (P0)

### Reliability

1. **Uptime:** THE System SHALL maintain 95% uptime during production hours (P0)
2. **Data Durability:** THE System SHALL ensure zero data loss for User_Profile and transaction records (P0)

### Usability

1. **Voice Clarity:** THE System SHALL use TTS voices rated above 4/5 for naturalness in user testing (P0)
2. **Language Accuracy:** THE System SHALL achieve >90% translation accuracy for supported languages (P0)
3. **Onboarding Time:** New users SHALL complete registration and first interaction within 3 minutes (P1)

### Accessibility

1. **Low-Literacy Design:** THE Visual_Price_Estimator SHALL use icons and voice narration for all critical actions (P0)
2. **Voice-First Navigation:** THE Voice_Negotiator SHALL be fully operable without any visual interface (P0)

### Compliance

1. **Data Residency:** THE System SHALL store all user data in AWS India regions (Mumbai/Hyderabad) (P0)
2. **Consent Management:** THE System SHALL obtain explicit consent before sending WhatsApp messages (P0)

## Success Metrics

1. **Price Fairness:** Users report 20%+ increase in earnings after using price estimates (measured via follow-up survey)
2. **Scheme Awareness:** 50%+ of users discover at least one relevant government scheme within first week
3. **Engagement:** 60%+ of registered users return for a second interaction within 7 days
4. **Voice Satisfaction:** Voice interface rated 4+/5 for ease of use by low-literacy users

## Out of Scope (Future Phases)

1. Direct marketplace integration for selling products
2. Payment processing or financial transactions
3. Multi-user collaboration features
4. Advanced analytics dashboard with ML insights
5. Integration with government portals for scheme applications
6. Video-based tutorials for skill development
7. Community forum for peer support
