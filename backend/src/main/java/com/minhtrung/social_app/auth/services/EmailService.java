package com.minhtrung.social_app.auth.services;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;

import java.util.concurrent.CompletableFuture;

@Service
@RequiredArgsConstructor
@Slf4j
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String fromEmail;

    public void sendVerificationEmail(String toEmail, int verificationCode) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(fromEmail);
            helper.setTo(toEmail);
            helper.setSubject("Email Verification Code");

            String htmlContent = buildEmailTemplate(verificationCode);

            helper.setText(htmlContent, true);

            log.info("Sending verification code email to {}", toEmail);
            mailSender.send(message);
        } catch (MessagingException e) {
            log.warn("Failed to send verification code email to {}", toEmail);
            throw new RuntimeException("Failed to send verification email", e);
        }
    }

    private String buildEmailTemplate(int code) {
        return """
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <style>
                            body {
                                font-family: Arial, sans-serif;
                                background-color: #f4f4f4;
                                margin: 0;
                                padding: 0;
                            }
                            .container {
                                max-width: 500px;
                                margin: 40px auto;
                                background: #ffffff;
                                padding: 20px;
                                border-radius: 10px;
                                box-shadow: 0 4px 10px rgba(0,0,0,0.1);
                                text-align: center;
                            }
                            .title {
                                font-size: 24px;
                                font-weight: bold;
                                color: #333;
                            }
                            .code {
                                margin: 20px 0;
                                font-size: 32px;
                                font-weight: bold;
                                letter-spacing: 5px;
                                color: #4CAF50;
                            }
                            .footer {
                                margin-top: 20px;
                                font-size: 12px;
                                color: #888;
                            }
                        </style>
                    </head>
                    <body>
                        <div class="container">
                            <div class="title">Email Verification Code</div>
                            <p>Hello</p>
                            <p>Your verification code is:</p>
                            <div class="code">%s</div>
                            <p>This code will expire in 5 minutes.</p>
                            <div class="footer">
                                If you didn’t request this, please ignore this email.
                            </div>
                        </div>
                    </body>
                    </html>
                """.formatted(code);
    }
    

    public void sendUntrustedDeviceWarning(String toEmail) {
        CompletableFuture.runAsync(() -> {
            try {
                MimeMessage message = mailSender.createMimeMessage();
                MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

                helper.setFrom(fromEmail);
                helper.setTo(toEmail);
                helper.setSubject("⚠️ New Login Detected");

                String htmlContent = buildWarningTemplate();

                helper.setText(htmlContent, true);

                log.info("Sending untrusted device warning email in background to {}", toEmail);
                mailSender.send(message);

            } catch (Exception e) {
                log.warn("Failed to send warning email to {}: {}", toEmail, e.getMessage());
            }
        });
    }
    
    private String buildWarningTemplate() {
        return """
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <style>
                            body {
                                font-family: Arial, sans-serif;
                                background-color: #f4f4f4;
                                margin: 0;
                                padding: 0;
                            }
                            .container {
                                max-width: 500px;
                                margin: 40px auto;
                                background: #ffffff;
                                padding: 20px;
                                border-radius: 10px;
                                box-shadow: 0 4px 10px rgba(0,0,0,0.1);
                                text-align: center;
                            }
                            .title {
                                font-size: 22px;
                                font-weight: bold;
                                color: #d9534f;
                            }
                            .info {
                                margin: 15px 0;
                                font-size: 14px;
                                color: #333;
                            }
                            .highlight {
                                font-weight: bold;
                                color: #000;
                            }
                            .warning {
                                margin-top: 20px;
                                padding: 10px;
                                background-color: #fff3cd;
                                border-radius: 5px;
                                color: #856404;
                                font-size: 13px;
                            }
                            .footer {
                                margin-top: 20px;
                                font-size: 12px;
                                color: #888;
                            }
                        </style>
                    </head>
                    <body>
                        <div class="container">
                            <div class="title">⚠️ New Login Detected</div>

                            <p class="info">We noticed a login from a new device</p>

                            <div class="warning">
                                If this was you, you can safely ignore this message.<br/>
                                If not, we recommend changing your password immediately.
                            </div>

                            <div class="footer">
                                Your account security is important to us.
                            </div>
                        </div>
                    </body>
                    </html>
                """.formatted();
    }
    
    
}