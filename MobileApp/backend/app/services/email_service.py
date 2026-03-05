"""Email service using Gmail SMTP."""
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from app.config import settings
import asyncio


class EmailService:
    """Send emails via Gmail SMTP."""
    
    def __init__(self):
        self.smtp_server = "smtp.gmail.com"
        self.smtp_port = 587
        self.sender_email = settings.gmail_address
        self.sender_password = settings.gmail_app_password
    
    async def send_otp_email(self, email: str, otp: str) -> bool:
        """Send OTP email to user.
        
        Args:
            email: User's email address
            otp: 6-digit OTP code
            
        Returns:
            True if sent successfully, False otherwise
        """
        try:
            # Create email message
            subject = "PragatiConnect - Your Verification Code"
            
            html_body = f"""
            <html>
                <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
                    <div style="max-width: 500px; margin: 0 auto; padding: 20px;">
                        <h2 style="color: #2c3e50;">Welcome to PragatiConnect</h2>
                        
                        <p>Your OTP verification code is:</p>
                        
                        <div style="background-color: #f0f0f0; padding: 20px; text-align: center; border-radius: 8px; margin: 20px 0;">
                            <h1 style="color: #27ae60; letter-spacing: 5px; margin: 0;">{otp}</h1>
                        </div>
                        
                        <p style="color: #7f8c8d; font-size: 14px;">
                            This code expires in <strong>5 minutes</strong>.
                        </p>
                        
                        <p style="color: #7f8c8d; font-size: 14px;">
                            If you didn't request this code, please ignore this email.
                        </p>
                        
                        <hr style="border: none; border-top: 1px solid #ecf0f1; margin: 30px 0;">
                        
                        <p style="color: #95a5a6; font-size: 12px; text-align: center;">
                            PragatiConnect - Empowering India's Informal Workforce<br>
                            &copy; 2026. All rights reserved.
                        </p>
                    </div>
                </body>
            </html>
            """
            
            # Run in executor since SMTP is blocking
            loop = asyncio.get_event_loop()
            result = await loop.run_in_executor(
                None, 
                self._send_smtp_email, 
                email, 
                subject, 
                html_body
            )
            return result
            
        except Exception as e:
            print(f"Error sending OTP email to {email}: {str(e)}")
            return False
    
    def _send_smtp_email(self, to_email: str, subject: str, html_body: str) -> bool:
        """Internal method to send email via SMTP (blocking)."""
        try:
            # Create message
            message = MIMEMultipart("alternative")
            message["Subject"] = subject
            message["From"] = self.sender_email
            message["To"] = to_email
            
            # Attach HTML body
            part = MIMEText(html_body, "html")
            message.attach(part)
            
            # Send email
            with smtplib.SMTP(self.smtp_server, self.smtp_port, timeout=10) as server:
                server.starttls()  # Secure connection
                server.login(self.sender_email, self.sender_password)
                server.send_message(message)
            
            print(f"✅ OTP email sent to {to_email}")
            return True
            
        except smtplib.SMTPAuthenticationError:
            print(f"❌ SMTP Authentication failed. Check Gmail credentials.")
            return False
        except smtplib.SMTPException as e:
            print(f"❌ SMTP error: {str(e)}")
            return False
        except Exception as e:
            print(f"❌ Error sending email: {str(e)}")
            return False


# Singleton instance
email_service = EmailService()
