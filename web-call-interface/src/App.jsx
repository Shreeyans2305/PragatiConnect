import React, { useEffect, useMemo, useRef, useState } from 'react';

const LANGUAGE_OPTIONS = [
  { code: 'en', label: 'English' },
  { code: 'hi', label: 'Hindi' },
  { code: 'mr', label: 'Marathi' },
  { code: 'ta', label: 'Tamil' },
  { code: 'te', label: 'Telugu' },
  { code: 'bn', label: 'Bengali' },
  { code: 'gu', label: 'Gujarati' },
  { code: 'kn', label: 'Kannada' },
  { code: 'ml', label: 'Malayalam' },
  { code: 'pa', label: 'Punjabi' },
];

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  'https://svp4ns3exj.execute-api.us-east-1.amazonaws.com/api/v1';
const STATIC_ACCESS_TOKEN = (import.meta.env.VITE_ACCESS_TOKEN || '').trim();
const AUTO_AUTH_EMAIL = (import.meta.env.VITE_AUTO_AUTH_EMAIL || '').trim();
const AUTO_AUTH_OTP = (import.meta.env.VITE_AUTO_AUTH_OTP || '').trim();

function mimeFromBackend(format) {
  if (!format) return 'audio/mpeg';
  if (format === 'mp3') return 'audio/mpeg';
  if (format === 'ogg_opus') return 'audio/ogg';
  if (format === 'linear16') return 'audio/wav';
  return 'audio/mpeg';
}

function createConversationId() {
  return `web_voice_${Date.now()}_${Math.floor(Math.random() * 10000)}`;
}

async function blobToLinear16Wav(blob) {
  const audioBuffer = await blob.arrayBuffer();
  const audioContext = new AudioContext();
  const decoded = await audioContext.decodeAudioData(audioBuffer);
  audioContext.close();

  const channels = decoded.numberOfChannels;
  const sampleRate = decoded.sampleRate;
  const samples = decoded.length;
  const interleaved = new Int16Array(samples * channels);

  for (let i = 0; i < samples; i++) {
    for (let ch = 0; ch < channels; ch++) {
      const sample = decoded.getChannelData(ch)[i];
      const clamped = Math.max(-1, Math.min(1, sample));
      interleaved[i * channels + ch] = clamped < 0 ? clamped * 0x8000 : clamped * 0x7fff;
    }
  }

  const headerSize = 44;
  const wavBuffer = new ArrayBuffer(headerSize + interleaved.byteLength);
  const view = new DataView(wavBuffer);

  const writeString = (offset, value) => {
    for (let i = 0; i < value.length; i++) {
      view.setUint8(offset + i, value.charCodeAt(i));
    }
  };

  writeString(0, 'RIFF');
  view.setUint32(4, 36 + interleaved.byteLength, true);
  writeString(8, 'WAVE');
  writeString(12, 'fmt ');
  view.setUint32(16, 16, true);
  view.setUint16(20, 1, true);
  view.setUint16(22, channels, true);
  view.setUint32(24, sampleRate, true);
  view.setUint32(28, sampleRate * channels * 2, true);
  view.setUint16(32, channels * 2, true);
  view.setUint16(34, 16, true);
  writeString(36, 'data');
  view.setUint32(40, interleaved.byteLength, true);

  let offset = 44;
  for (let i = 0; i < interleaved.length; i++, offset += 2) {
    view.setInt16(offset, interleaved[i], true);
  }

  const uint8 = new Uint8Array(wavBuffer);
  let binary = '';
  const chunkSize = 0x8000;
  for (let i = 0; i < uint8.length; i += chunkSize) {
    const chunk = uint8.subarray(i, i + chunkSize);
    binary += String.fromCharCode(...chunk);
  }

  return {
    audioBase64: btoa(binary),
    sampleRate,
  };
}

export default function App() {
  const [language, setLanguage] = useState('hi');
  const [isAuthenticated, setIsAuthenticated] = useState(Boolean(STATIC_ACCESS_TOKEN));
  const [authLoading, setAuthLoading] = useState(false);
  const [callActive, setCallActive] = useState(false);
  const [isRecording, setIsRecording] = useState(false);
  const [isThinking, setIsThinking] = useState(false);
  const [conversationId, setConversationId] = useState('');
  const [messages, setMessages] = useState([]);
  const [error, setError] = useState('');
  const [statusText, setStatusText] = useState('Ready to start call');
  const [authEmail, setAuthEmail] = useState(AUTO_AUTH_EMAIL);
  const [otpCode, setOtpCode] = useState(AUTO_AUTH_OTP);
  const [needsOtp, setNeedsOtp] = useState(!STATIC_ACCESS_TOKEN);
  const [otpRequested, setOtpRequested] = useState(false);
  const [showWelcome, setShowWelcome] = useState(false);

  const mediaRecorderRef = useRef(null);
  const chunksRef = useRef([]);
  const currentAudioRef = useRef(null);
  const authTokenRef = useRef(STATIC_ACCESS_TOKEN);

  const canRecord = useMemo(() => callActive && !isThinking, [callActive, isThinking]);

  const requestOtp = async () => {
    if (!authEmail.trim()) {
      setError('Please enter email first.');
      return;
    }

    setAuthLoading(true);
    setError('');
    setStatusText('Requesting OTP...');

    const registerResponse = await fetch(`${API_BASE_URL}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: authEmail.trim() }),
    });

    if (!registerResponse.ok) {
      const registerError = await registerResponse.text();
      setAuthLoading(false);
      throw new Error(registerError || 'Failed to request OTP');
    }

    setOtpRequested(true);
    setNeedsOtp(true);
    setStatusText('OTP sent. Enter OTP to continue');
    setAuthLoading(false);
  };

  const verifyOtp = async () => {
    if (!authEmail.trim()) {
      setError('Please enter email first.');
      return;
    }
    if (!otpCode.trim()) {
      setError('Please enter OTP.');
      return;
    }

    setAuthLoading(true);
    setError('');
    setStatusText('Authenticating...');

    const verifyResponse = await fetch(`${API_BASE_URL}/auth/verify-otp`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: authEmail.trim(),
        otp: otpCode.trim(),
      }),
    });

    if (!verifyResponse.ok) {
      const verifyError = await verifyResponse.text();
      if (verifyError.includes('Invalid OTP') || verifyError.includes('expired')) {
        setNeedsOtp(true);
      }
      setAuthLoading(false);
      throw new Error(
        verifyError ||
          'OTP verification failed.',
      );
    }

    const tokenPayload = await verifyResponse.json();
    const accessToken = tokenPayload?.access_token?.trim();

    if (!accessToken) {
      setAuthLoading(false);
      throw new Error('Auto-auth did not return an access token');
    }

    authTokenRef.current = accessToken;
    setNeedsOtp(false);
    setIsAuthenticated(true);
    setStatusText('Authenticated. Ready to start call');
    setAuthLoading(false);
    
    // Persist auth token in localStorage
    try {
      localStorage.setItem('pragati-auth-token', accessToken);
      localStorage.setItem('pragati-auth-email', authEmail.trim());
    } catch (e) {
      console.warn('Failed to persist auth token:', e);
    }
  };

  useEffect(() => {
    if (STATIC_ACCESS_TOKEN) {
      setIsAuthenticated(true);
      setNeedsOtp(false);
      setStatusText('Authenticated. Ready to start call');
      return;
    }

    // Try to restore auth from localStorage
    try {
      const savedToken = localStorage.getItem('pragati-auth-token');
      const savedEmail = localStorage.getItem('pragati-auth-email');
      if (savedToken && savedEmail) {
        authTokenRef.current = savedToken;
        setAuthEmail(savedEmail);
        setIsAuthenticated(true);
        setNeedsOtp(false);
        setStatusText('Authenticated. Ready to start call');
        return;
      }
    } catch (e) {
      console.warn('Failed to restore auth token:', e);
    }

    if (AUTO_AUTH_EMAIL && AUTO_AUTH_OTP) {
      (async () => {
        try {
          await verifyOtp();
        } catch {
          setIsAuthenticated(false);
          setNeedsOtp(true);
          setStatusText('Authenticate to continue');
        }
      })();
    } else {
      setStatusText('Authenticate to continue');
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    try {
      const seen = localStorage.getItem('pragati-live-call-welcome-seen');
      if (!seen) {
        setShowWelcome(true);
      }
    } catch {
      setShowWelcome(true);
    }
  }, []);

  const dismissWelcome = () => {
    setShowWelcome(false);
    try {
      localStorage.setItem('pragati-live-call-welcome-seen', '1');
    } catch {
      // no-op
    }
  };

  const logout = () => {
    authTokenRef.current = null;
    setIsAuthenticated(false);
    setNeedsOtp(true);
    setOtpRequested(false);
    setOtpCode('');
    setStatusText('Authenticate to continue');
    
    try {
      localStorage.removeItem('pragati-auth-token');
      localStorage.removeItem('pragati-auth-email');
    } catch (e) {
      console.warn('Failed to clear auth token:', e);
    }
  };

  const ensureAuthToken = () => {
    if (!authTokenRef.current) {
      throw new Error('Please authenticate first.');
    }
    return authTokenRef.current;
  };

  const startCall = () => {
    if (!isAuthenticated) {
      setError('Authenticate first.');
      setStatusText('Authentication required');
      return;
    }

    setError('');

    const newId = createConversationId();
    setConversationId(newId);
    setCallActive(true);
    setMessages([
      {
        role: 'assistant',
        text: 'Call connected. Tap and speak to ask Pragati anything.',
      },
    ]);
    setStatusText('Call connected');
  };

  const endCall = () => {
    if (mediaRecorderRef.current && mediaRecorderRef.current.state !== 'inactive') {
      mediaRecorderRef.current.stop();
    }
    setIsRecording(false);
    setIsThinking(false);
    setCallActive(false);
    setConversationId('');
    setMessages([]);
    setStatusText('Call ended');
    if (currentAudioRef.current) {
      currentAudioRef.current.pause();
      currentAudioRef.current = null;
    }
  };

  const startRecording = async () => {
    if (!canRecord) return;

    setError('');
    setStatusText('Listening...');

    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const recorder = new MediaRecorder(stream, {
        mimeType: 'audio/webm;codecs=opus',
      });

      chunksRef.current = [];
      recorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          chunksRef.current.push(event.data);
        }
      };

      recorder.onstop = async () => {
        stream.getTracks().forEach((track) => track.stop());
        const blob = new Blob(chunksRef.current, { type: 'audio/webm' });
        await processAudio(blob);
      };

      mediaRecorderRef.current = recorder;
      recorder.start();
      setIsRecording(true);
    } catch (e) {
      // Check if it's a permission error
      if (e.name === 'NotAllowedError' || e.name === 'PermissionDeniedError') {
        alert('Please allow access to microphone to use voice calling.');
        setError('Microphone permission denied');
        setStatusText('Please enable microphone');
      } else {
        setError(`Microphone error: ${e.message}`);
        setStatusText('Mic access failed');
      }
    }
  };

  const stopRecording = () => {
    if (!mediaRecorderRef.current || mediaRecorderRef.current.state === 'inactive') return;
    setStatusText('Processing...');
    setIsRecording(false);
    mediaRecorderRef.current.stop();
  };

  const processAudio = async (blob) => {
    setIsThinking(true);

    try {
      const authToken = ensureAuthToken();
      const { audioBase64, sampleRate } = await blobToLinear16Wav(blob);

      let response = await fetch(`${API_BASE_URL}/voice/query-base64`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${authToken}`,
        },
        body: JSON.stringify({
          audio_data: audioBase64,
          language,
          conversation_id: conversationId,
          audio_encoding: 'LINEAR16',
          sample_rate: sampleRate,
        }),
      });

      if (response.status === 401) {
        authTokenRef.current = '';
        setIsAuthenticated(false);
        setNeedsOtp(true);
        setCallActive(false);
        throw new Error('Session expired. Please authenticate again.');
      }

      if (!response.ok) {
        const rawError = await response.text();
        throw new Error(rawError || `Voice request failed (${response.status})`);
      }

      const data = await response.json();

      setMessages((prev) => [
        ...prev,
        { role: 'user', text: data.user_transcript || '(no transcript)' },
        { role: 'assistant', text: data.ai_response || '(no response)' },
      ]);

      const mime = mimeFromBackend(data.audio_format);
      const audio = new Audio(`data:${mime};base64,${data.audio_response}`);
      currentAudioRef.current = audio;
      setStatusText('Pragati speaking...');
      await audio.play();
      audio.onended = () => setStatusText('Call connected');
    } catch (e) {
      setError(`Voice call failed: ${e.message}`);
      setStatusText('Call error');
    } finally {
      setIsThinking(false);
    }
  };

  const latestAssistantMessage = [...messages]
    .reverse()
    .find((message) => message.role === 'assistant')?.text;

  const latestUserMessage = [...messages]
    .reverse()
    .find((message) => message.role === 'user')?.text;

  return (
    <div className="page">
      <div className="iphone-shell">
        <div className="side-button side-button-left" />
        <div className="side-button side-button-right" />
        <div className="dynamic-island" aria-hidden="true">
          <div className="island-camera" />
          <div className="island-sensor" />
        </div>
        <div className="screen">
          {showWelcome && (
            <div className="welcome-overlay">
              <div className="welcome-card">
                <h3>Welcome to the PragatiConnect Live Call Assistance</h3>
                <p>
                  This is currently a demo web calling experience. In production, this can connect to a
                  real-time toll-free number via providers like Twilio/Exotel and stream live call audio
                  to the voice AI backend for STT → AI → TTS.
                </p>
                <p>
                  Calls can be routed over SIP/VoIP with authentication, rate limiting, monitoring, and
                  queuing for reliable support at scale.
                </p>
                <button className="call-button start" onClick={dismissWelcome} type="button">
                  Got it
                </button>
              </div>
            </div>
          )}

          {!callActive ? (
            <>
              <header className="header">
                <div>
                  <h1>Pragati Call</h1>
                  <p>{statusText}</p>
                </div>
                <div className={`signal ${callActive ? 'live' : ''}`}>
                  {callActive ? 'LIVE' : isAuthenticated ? 'READY' : 'AUTH'}
                </div>
              </header>

              <section className="controls">
                {!isAuthenticated && (
                  <>
                    <label>
                      Login Email
                      <input
                        type="email"
                        value={authEmail}
                        onChange={(e) => {
                          setAuthEmail(e.target.value);
                          setOtpRequested(false);
                        }}
                        placeholder="Enter your email"
                        disabled={otpRequested || authLoading}
                      />
                    </label>
                    <label>
                      OTP
                      <input
                        type="text"
                        value={otpCode}
                        onChange={(e) => setOtpCode(e.target.value)}
                        placeholder="Enter OTP"
                      />
                    </label>
                    <div className="call-actions">
                      <button
                        className="call-button start"
                        onClick={async () => {
                          try {
                            await requestOtp();
                          } catch (e) {
                            setError(`Authentication failed: ${e.message}`);
                            setStatusText('Auth failed');
                          }
                        }}
                        disabled={authLoading || otpRequested}
                      >
                        {otpRequested ? 'OTP Sent' : authLoading ? 'Requesting...' : 'Send OTP'}
                      </button>
                      <button
                        className="mic-button"
                        onClick={async () => {
                          try {
                            if (!otpRequested && !AUTO_AUTH_OTP) {
                              await requestOtp();
                            }
                            await verifyOtp();
                          } catch (e) {
                            setError(`Authentication failed: ${e.message}`);
                            setStatusText('Auth failed');
                          }
                        }}
                        disabled={authLoading}
                      >
                        {authLoading ? 'Authenticating...' : 'Verify OTP & Continue'}
                      </button>
                    </div>
                  </>
                )}

                {isAuthenticated && (
                  <>
                    <label>
                      Language
                      <select value={language} onChange={(e) => setLanguage(e.target.value)}>
                        {LANGUAGE_OPTIONS.map((option) => (
                          <option key={option.code} value={option.code}>
                            {option.label}
                          </option>
                        ))}
                      </select>
                    </label>
                    <button className="logout-button" onClick={logout}>
                      Logout
                    </button>
                  </>
                )}
              </section>

              {isAuthenticated && (
                <section className="call-actions">
                  <p className="precall-tip">
                    Tip: Press and hold the mic button while speaking. Release it when you finish your
                    message.
                  </p>
                  <button className="call-button start" onClick={startCall}>
                    Start Call
                  </button>
                </section>
              )}

              {error && <p className="error">{error}</p>}

              <section className="chat-log">
                {messages.map((message, index) => (
                  <div key={`${message.role}-${index}`} className={`bubble ${message.role}`}>
                    <span>{message.role === 'assistant' ? 'Pragati' : 'You'}</span>
                    <p>{message.text}</p>
                  </div>
                ))}
              </section>
            </>
          ) : (
            <section className="call-screen">
              <div className="call-top">
                <p className="call-label">Pragati Voice Assistant</p>
                <h2>On Call</h2>
                <p className="call-status">{statusText}</p>
              </div>

              <div className="call-transcript">
                <p className="transcript-role">Assistant</p>
                <p className="transcript-text">
                  {latestAssistantMessage || 'Namaste! Hold the mic button and speak.'}
                </p>
                {latestUserMessage && (
                  <>
                    <p className="transcript-role you">You</p>
                    <p className="transcript-text user">{latestUserMessage}</p>
                  </>
                )}
              </div>

              <div className="call-bottom-actions">
                <button className="circle-button neutral" type="button" disabled>
                  ✋
                  <span>Mute</span>
                </button>
                <button
                  className={`circle-button speak ${isRecording ? 'recording' : ''}`}
                  disabled={!canRecord}
                  onMouseDown={startRecording}
                  onMouseUp={stopRecording}
                  onTouchStart={startRecording}
                  onTouchEnd={stopRecording}
                  type="button"
                >
                  🎙
                  <span>{isRecording ? 'Release' : isThinking ? 'Thinking' : 'Hold to Talk'}</span>
                </button>
                <button className="circle-button end" onClick={endCall} type="button">
                  📞
                  <span>End</span>
                </button>
              </div>
            </section>
          )}
        </div>
      </div>
    </div>
  );
}
