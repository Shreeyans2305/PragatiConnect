import './App.css'

function App() {
  return (
    <div className="app">
      <div className="container">
        <header className="header">
          <h1>🌟 Welcome to Pragati Connect</h1>
          <p>
            Empowering India's 450+ million informal workers with AI-powered economic assistance
          </p>
        </header>

        <main className="content">
          <section className="services-intro">
            <h2>Our Primary Services</h2>
            <p>
              Pragati Connect offers two accessible ways to help informal workers discover fair wages, 
              practice negotiations, and access government schemes in their local language.
            </p>
          </section>

          <div className="services">
            {/* Mobile App Service */}
            <div className="service-card">
              <div className="service-header">
                <span className="service-icon">📱</span>
                <h3>Mobile App</h3>
              </div>
              <p className="service-description">
                A comprehensive Flutter-based mobile application supporting iOS and Android platforms. 
                Features include voice assistant, price estimator, AI chat, government scheme discovery, 
                and business tools—all in 10 Indian languages.
              </p>

              {/* Android Section */}
              <div className="platform-section">
                <h4>
                  🤖 Android
                  <span className="difficulty-badge easy">Easy Setup</span>
                </h4>
                <ol className="steps">
                  <li>
                    <strong>Download the APK:</strong> Click the button below to download the Pragati Connect APK file
                  </li>
                  <li>
                    <strong>Enable Installation:</strong> Go to your phone's <code>Settings → Security</code> and enable 
                    "Install apps from unknown sources" or "Install unknown apps"
                  </li>
                  <li>
                    <strong>Install the App:</strong> Open the downloaded APK file and tap "Install"
                  </li>
                  <li>
                    <strong>Launch & Test:</strong> Open Pragati Connect and start exploring features. 
                    Register with your phone number to access all functionality
                  </li>
                </ol>
                <a href="#" className="cta-button">📥 Download Android APK</a>
                <div className="note">
                  <strong>Note:</strong> The APK link will be provided during the demo session. 
                  Ensure you have at least 100MB of free storage.
                </div>
              </div>

              {/* iOS Section */}
              <div className="platform-section">
                <h4>
                  🍎 iOS
                  <span className="difficulty-badge advanced">Advanced Setup</span>
                </h4>
                <p style={{ color: '#856404', marginBottom: '1rem', fontStyle: 'italic' }}>
                  ⚠️ iOS testing requires a laptop (Mac/Windows/Linux) with Flutter installed, 
                  an iPhone, and enrollment in Apple Developer Beta Program. This is a more technical process.
                </p>
                <ol className="steps">
                  <li>
                    <strong>Install Flutter:</strong> Download and install Flutter SDK from{' '}
                    <a href="https://flutter.dev/docs/get-started/install" target="_blank" rel="noopener noreferrer">
                      flutter.dev
                    </a>. 
                    Follow the platform-specific instructions for your laptop OS. Verify installation with <code>flutter doctor</code>
                  </li>
                  <li>
                    <strong>Clone the Repository:</strong> Open Terminal/Command Prompt and run:
                    <br />
                    <code>git clone https://github.com/your-username/PragatiConnect.git</code>
                    <br />
                    <code>cd PragatiConnect/MobileApp</code>
                  </li>
                  <li>
                    <strong>Install Dependencies:</strong> Run <code>flutter pub get</code> to install all required packages
                  </li>
                  <li>
                    <strong>Join Apple Developer Beta:</strong> On your iPhone, go to{' '}
                    <a href="https://beta.apple.com" target="_blank" rel="noopener noreferrer">
                      beta.apple.com
                    </a>, 
                    sign in with your Apple ID, and enroll in the iOS Developer Beta Program (free)
                  </li>
                  <li>
                    <strong>Enable Developer Mode:</strong> On iPhone, go to <code>Settings → Privacy & Security → Developer Mode</code> and toggle it ON. 
                    Restart your phone when prompted
                  </li>
                  <li>
                    <strong>Trust Your Computer:</strong> Connect iPhone to laptop via USB cable. 
                    When prompted "Trust This Computer?" on iPhone, tap "Trust" and enter your passcode
                  </li>
                  <li>
                    <strong>Open in Xcode (Mac only):</strong> If on Mac, open <code>ios/Runner.xcworkspace</code> in Xcode. 
                    Go to Signing & Capabilities and select your Apple ID under "Team"
                  </li>
                  <li>
                    <strong>Select Device:</strong> In VS Code/Android Studio, click the device selector at bottom-right 
                    and choose your connected iPhone from the list of available devices
                  </li>
                  <li>
                    <strong>Run the App:</strong> Press <code>F5</code> in VS Code or run <code>flutter run</code> in Terminal. 
                    The app will build and install on your iPhone (first build may take 5-10 minutes)
                  </li>
                  <li>
                    <strong>Trust Developer Certificate:</strong> On iPhone, go to <code>Settings → General → VPN & Device Management</code>, 
                    tap your Apple ID, and tap "Trust"
                  </li>
                </ol>
                <div className="repo-link">
                  📦 <strong>Repository:</strong>{' '}
                  <a href="https://github.com/your-username/PragatiConnect" target="_blank" rel="noopener noreferrer">
                    github.com/your-username/PragatiConnect
                  </a>
                </div>
                <div className="note">
                  <strong>Troubleshooting:</strong> If you encounter build errors, ensure Xcode is updated (Mac), 
                  run <code>flutter clean</code> and <code>flutter pub get</code>, and check <code>flutter doctor</code> for issues.
                </div>
              </div>
            </div>

            {/* On-Call Service */}
            <div className="service-card">
              <div className="service-header">
                <span className="service-icon">📞</span>
                <h3>On-Call Voice Interface</h3>
              </div>
              <p className="service-description">
                A phone-based voice interaction system that allows users with feature phones to access 
                Pragati Connect services through natural voice conversations in their local language.
              </p>

              <div className="platform-section">
                <h4>🎯 Production Vision: Toll-Free Number</h4>
                <p style={{ lineHeight: '1.8', color: '#444' }}>
                  In the production deployment, users will dial a <strong>toll-free phone number</strong> (e.g., 1800-XXX-XXXX) 
                  accessible from any phone in India. The system will:
                </p>
                <ul style={{ marginLeft: '2rem', marginTop: '1rem', lineHeight: '1.8', color: '#444' }}>
                  <li>Answer calls within 3 rings with a multi-language greeting</li>
                  <li>Use advanced speech-to-text to transcribe the user's voice in real-time</li>
                  <li>Process queries through Amazon Bedrock AI for intelligent responses</li>
                  <li>Convert AI responses back to natural-sounding speech</li>
                  <li>Support wage queries, negotiation practice, and scheme information</li>
                </ul>
                <div className="note" style={{ marginTop: '1.5rem' }}>
                  <strong>Implementation:</strong> The production system will integrate with telephony providers 
                  like Vapi.ai, Twilio, or AWS Connect to handle voice calls at scale. This requires significant 
                  infrastructure investment and regulatory approvals for toll-free number allocation.
                </div>
              </div>

              <div className="platform-section" style={{ marginTop: '2rem' }}>
                <h4>
                  🌐 Current Prototype: Web Interface
                  <span className="difficulty-badge easy">Try Now</span>
                </h4>
                <p style={{ lineHeight: '1.8', color: '#444', marginBottom: '1.5rem' }}>
                  For demonstration and testing purposes, we've built a <strong>web-based prototype</strong> that 
                  replicates the phone call experience in your browser. This allows you to test the voice interaction 
                  system without needing telephony infrastructure.
                </p>
                
                <ol className="steps">
                  <li>
                    <strong>Open the Website:</strong> Visit{' '}
                    <a href="https://pragati-connect-on-call.vercel.app/" target="_blank" rel="noopener noreferrer">
                      pragati-connect-on-call.vercel.app
                    </a>{' '}
                    in your browser (works best on Chrome/Edge)
                  </li>
                  <li>
                    <strong>Grant Microphone Access:</strong> When prompted, click "Allow" to enable microphone access 
                    for voice input
                  </li>
                  <li>
                    <strong>Select Language:</strong> Choose your preferred language from the dropdown menu 
                    (Hindi, English, Tamil, Telugu, etc.)
                  </li>
                  <li>
                    <strong>Start Conversation:</strong> Click the "Start Call" button to begin the voice interaction session
                  </li>
                  <li>
                    <strong>Hold to Talk:</strong> Press and hold the microphone button, speak your query clearly, 
                    then release. The system will transcribe, process, and respond with voice audio
                  </li>
                  <li>
                    <strong>Test Features:</strong> Try asking about wage rates, practice negotiation scenarios, 
                    or inquire about government schemes like PM-KISAN or PM Vishwakarma
                  </li>
                  <li>
                    <strong>End Call:</strong> Click the red "End Call" button when finished to close the session
                  </li>
                </ol>

                <a 
                  href="https://pragati-connect-on-call.vercel.app/" 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="cta-button"
                >
                  🚀 Launch Web Interface
                </a>

                <div className="note" style={{ marginTop: '1.5rem' }}>
                  <strong>What's Happening Behind the Scenes:</strong> Your voice is captured via Web Audio API, 
                  transcribed using on-device speech recognition, sent to our AWS Lambda backend, processed by 
                  Amazon Bedrock AI, and the response is synthesized into natural speech—all in under 3 seconds!
                </div>

                <div className="repo-link">
                  💻 <strong>Web Interface Code:</strong>{' '}
                  <a href="https://github.com/your-username/PragatiConnect/tree/main/web-call-interface" target="_blank" rel="noopener noreferrer">
                    github.com/your-username/PragatiConnect/web-call-interface
                  </a>
                </div>
              </div>
            </div>
          </div>

          <section style={{ marginTop: '3rem', textAlign: 'center', padding: '2rem', background: '#f8f9fa', borderRadius: '15px' }}>
            <h3 style={{ fontSize: '1.75rem', marginBottom: '1rem', color: '#333' }}>Need Help?</h3>
            <p style={{ fontSize: '1.1rem', color: '#666', marginBottom: '1.5rem' }}>
              For questions, bug reports, or feature requests, please reach out to our team
            </p>
            <div style={{ display: 'flex', gap: '1rem', justifyContent: 'center', flexWrap: 'wrap' }}>
              <a href="mailto:team@pragaticonnect.com" className="cta-button">
                📧 Email Support
              </a>
              <a href="https://github.com/your-username/PragatiConnect/issues" target="_blank" rel="noopener noreferrer" className="cta-button">
                🐛 Report Issue
              </a>
            </div>
          </section>
        </main>

        <footer className="footer">
          <p><strong>Pragati Connect</strong> - Empowering India's Informal Workforce</p>
          <p>
            Built with ❤️ using AWS Bedrock, Flutter, React, and Python | {' '}
            <a href="https://github.com/your-username/PragatiConnect" target="_blank" rel="noopener noreferrer">
              View on GitHub
            </a>
          </p>
          <p style={{ fontSize: '0.9rem', marginTop: '1rem', opacity: 0.7 }}>
            © 2026 Pragati Connect Team. Open Source under MIT License.
          </p>
        </footer>
      </div>
    </div>
  )
}

export default App
