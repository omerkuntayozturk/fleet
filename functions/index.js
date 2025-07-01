// ========== ENGLISH VERSION CODE ==========

const nodemailer = require("nodemailer");
const admin = require("firebase-admin");
const functions = require("firebase-functions/v1");
const { onSchedule } = require("firebase-functions/v2/scheduler");


admin.initializeApp();

/**
 * Creates and verifies an SMTP transporter.
 */
const createTransporter = () => {
  try {
    const transport = nodemailer.createTransport({
      host: "smtp.gmail.com",
      port: 587,
      secure: false,
      auth: {
        user: "info@goyaapp.com",
        pass: "tranzeaxnafwnvjv", // Replace with your real password
      },
      tls: {
        rejectUnauthorized: true,
      },
    });
    
    transport.verify((error) => {
      if (error) {
        console.error("SMTP verification error:", error);
      } else {
        console.log("SMTP server is ready");
      }
    });
    
    return transport;
  } catch (error) {
    console.error("Error creating email transporter:", error);
    return null;
  }
};

/**
 * Generates a 6-digit random verification code.
 */
function generateVerificationCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

/**
 * Sends a verification code to the given email (callable function).
 */
exports.sendVerificationCode = functions.https.onCall(async (data, context) => {
  try {
    const { email, isGoogleSignIn } = data;
    if (!email) {
      return { 
        success: false, 
        message: "Email is required" 
      };
    }

    const verificationCode = generateVerificationCode();
    
    const transporter = createTransporter();
    if (!transporter) {
      return { 
        success: false, 
        message: "Email service configuration error" 
      };
    }

    // Save the verification code in Firestore with a 5-minute expiration
    await admin.firestore().collection("verificationCodes").doc(email).set({
      code: verificationCode,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expires: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 5 * 60 * 1000) // 5 minutes from now
      ),
      isGoogleSignIn: isGoogleSignIn || false
    });

    const mailTemplate = isGoogleSignIn ? 
      emailTemplates.googleSignInVerification(email, verificationCode) :
      emailTemplates.emailVerification(email, verificationCode);

    const mailOptions = {
      from: '"Goya HR Support" <info@goyaapp.com>',
      to: email,
      subject: mailTemplate.subject,
      html: mailTemplate.html
    };

    await transporter.sendMail(mailOptions);
    
    return { 
      success: true, 
      message: "Verification code sent successfully"
    };
  } catch (error) {
    console.error("Error sending verification code:", error);
    return { 
      success: false, 
      message: "Error sending verification code",
      error: error.toString()
    };
  }
});

/**
 * Verifies the submitted code (callable function).
 */
exports.verifyCode = functions.https.onCall(async (data, context) => {
  try {
    const { email, code } = data;
    
    const docRef = admin.firestore().collection("verificationCodes").doc(email);
    const doc = await docRef.get();
    
    if (!doc.exists) {
      return { 
        success: false, 
        message: "No verification code found" 
      };
    }

    const { code: storedCode, expires } = doc.data();
    
    if (new Date() > expires.toDate()) {
      await docRef.delete();
      return { 
        success: false, 
        message: "Verification code expired" 
      };
    }

    if (code !== storedCode) {
      return { 
        success: false, 
        message: "Invalid verification code" 
      };
    }

    await docRef.delete();
    return { 
      success: true, 
      message: "Code verified successfully" 
    };
  } catch (error) {
    console.error("Error verifying code:", error);
    return { 
      success: false, 
      message: "Error verifying code",
      error: error.toString()
    };
  }
});

/**
 * Simple test function (HTTP).
 */
exports.testHttpFunctionv1 = functions.https.onRequest((request, response) => {
  response.status(200).send("HTTP function is working!");
});

/**
 * Main support email function (callable).
 */
exports.sendSupportEmail = functions.https.onCall(async (data, context) => {
  console.log("sendSupportEmail function called with data:", JSON.stringify(data));
  
  try {
    // Authentication check
    if (!context.auth) {
      return { 
        success: false, 
        message: "Authentication required" 
      };
    }

    // Data validation
    const { userEmail, userName, subject, message } = data;
    if (!userEmail || !subject || !message) {
      console.error("Missing required fields:", { userEmail, subject, message });
      return { 
        success: false, 
        message: "Missing required fields",
        details: {
          hasEmail: Boolean(userEmail),
          hasSubject: Boolean(subject),
          hasMessage: Boolean(message)
        }
      };
    }

    const transporter = createTransporter();
    if (!transporter) {
      return { 
        success: false, 
        message: "Email service configuration error" 
      };
    }

    const mailOptions = {
      from: `"GOYA HR Support" <info@goyaapp.com>`,
      to: "support@goyaapp.com", 
      bcc: "omerkuntayozturk@gmail.com",
      replyTo: userEmail,
      subject: `[Support] ${subject}`,
      text: `From: ${userName} (${userEmail})\n\n${message}`,
      html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 5px;">
      <h2 style="color: #5271ff;">New Support Request - GOYA HR 👥</h2>
      <p style="color: #666; font-style: italic;">Comprehensive HR Management Solution for Modern Businesses</p>
      <hr style="border: none; border-top: 1px solid #ddd; margin: 20px 0;">
      
      <div style="background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin-bottom: 20px;">
      <p><strong>From:</strong> ${userName}</p>
      <p><strong>Email:</strong> ${userEmail}</p>
      <p><strong>Subject:</strong> ${subject}</p>
      </div>

      <div style="margin-top: 20px;">
      <h3 style="color: #5271ff;">Message:</h3>
      <p style="background-color: #f9f9f9; padding: 15px; border-left: 4px solid #5271ff;">
      ${message.replace(/\n/g, "<br>")}
      </p>
      </div>

      <div style="margin-top: 30px; font-size: 12px; color: #666;">
      <p>🚀 Key Features of GOYA HR:</p>
      <ul>
      <li>👥 Comprehensive Employee Management - Store complete profiles with advanced search and filtering</li>
      <li>📝 Contract Management - Full lifecycle tracking with expiration notifications</li>
      <li>🧠 Skills and Talent Management - Track employee capabilities and identify skill gaps</li>
      <li>🏢 Organizational Structure Visualization - Interactive org charts showing departments and positions</li>
      <li>📊 Intelligent Dashboard - Real-time HR metrics with intuitive charts and analytics</li>
      </ul>
      <p>GOYA HR: Transform your HR operations with our all-in-one platform!</p>
      </div>
      </div>
      `
    };

    try {
      const info = await transporter.sendMail(mailOptions);
      
      await admin.firestore().collection("EmailLogs").add({
        type: "support",
        to: "support@goyaapp.com",
        from: userEmail,
        subject: `[Support] ${subject}`,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        success: true,
        messageId: info.messageId
      });
      
      return { 
        success: true, 
        message: "Email sent successfully!",
        messageId: info.messageId
      };
    } catch (emailError) {
      console.error("Error sending email:", emailError);
      
      await admin.firestore().collection("EmailLogs").add({
        type: "support",
        to: "support@goyaapp.com",
        from: userEmail,
        subject: `[Support] ${subject}`,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        success: false,
        error: emailError.toString()
      });
      
      return { 
        success: false, 
        message: "An error occurred while sending the email.",
        error: emailError.toString()
      };
    }
  } catch (error) {
    console.error("Function execution error:", error);
    return { 
      success: false, 
      message: "An error occurred during execution.",
      error: error.toString()
    };
  }
});

/**
 * Sends a new verification email (callable).
 */
exports.sendVerificationEmail = functions.https.onCall(async (data, context) => {
  try {
    const { email } = data;
    if (!email) {
      return { success: false, message: "Email is required" };
    }

    const verificationCode = Math.floor(100000 + Math.random() * 900000).toString();
    const transporter = createTransporter();

    // Store the code in Firestore
    await admin.firestore().collection("verificationCodes").doc(email).set({
      code: verificationCode,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expires: admin.firestore.Timestamp.fromDate(
        new Date(Date.now() + 5 * 60 * 1000) // 5 minutes
      )
    });

    const mailOptions = {
      from: `"GOYA HR Support" <info@goyaapp.com>`,
      to: email,
      subject: "GOYA HR - Your Verification Code 👥",
      html: `
      <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; padding: 30px; border-radius: 12px; background-color: #f9f9f9; box-shadow: 0 4px 8px rgba(0,0,0,0.05);">
      <div style="text-align: center; margin-bottom: 25px;">
      <h2 style="color: #5271ff; margin: 0; font-size: 28px; font-weight: 600;">Welcome to GOYA HR! 👥</h2>
      <p style="color: #555; font-size: 16px; margin-top: 10px;">Comprehensive HR Management Solution for Modern Businesses</p>
      </div>
      
      <div style="background: linear-gradient(135deg, #5271ff 0%, #5e85ff 100%); padding: 20px; border-radius: 10px; text-align: center; margin: 25px 0;">
      <p style="color: white; font-size: 16px; margin: 0 0 10px 0;">Your verification code:</p>
      <h1 style="color: white; font-size: 38px; letter-spacing: 8px; margin: 10px 0; font-weight: 700; text-shadow: 0 2px 4px rgba(0,0,0,0.1);">${verificationCode}</h1>
      <p style="color: rgba(255,255,255,0.9); font-size: 14px; margin: 10px 0 0 0;">This code will expire in 5 minutes.</p>
      </div>
      
      <div style="background: white; padding: 20px; border-radius: 10px; margin-top: 25px;">
      <h3 style="color: #5271ff; margin-top: 0;">🚀 Key Features:</h3>
      <ul style="color: #555; padding-left: 20px;">
      <li>👥 Comprehensive Employee Management - Store complete profiles with advanced search and filtering</li>
      <li>📝 Contract Management - Full lifecycle tracking with expiration notifications</li>
      <li>🧠 Skills and Talent Management - Track employee capabilities and identify skill gaps</li>
      <li>🏢 Organizational Structure Visualization - Interactive org charts showing departments and positions</li>
      <li>📊 Intelligent Dashboard - Real-time HR metrics with intuitive charts and analytics</li>
      </ul>
      </div>

      <p style="text-align: center; color: #888; font-size: 14px; margin-top: 25px;">
      Transform your HR operations with our all-in-one platform! Experience the future of HR management with GOYA HR.
      </p>
      </div>
      `
    };

    await transporter.sendMail(mailOptions);
    
    await admin.firestore().collection("EmailLogs").add({
      type: "verification",
      to: email,
      subject: "Verification Code",
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      success: true
    });

    return { success: true, message: "Verification code sent" };
  } catch (error) {
    console.error("Error sending verification email:", error);
    return { success: false, message: error.message };
  }
});

/**
 * Verifies the submitted code (callable).
 */
exports.verifyEmailCode = functions.https.onCall(async (data, context) => {
  try {
    const { email, code } = data;
    const doc = await admin.firestore()
      .collection("verificationCodes")
      .doc(email)
      .get();

    if (!doc.exists) {
      return { success: false, message: "No verification code found" };
    }

    const { code: storedCode, expires } = doc.data();
    
    if (new Date() > expires.toDate()) {
      await doc.ref.delete();
      return { success: false, message: "Code expired" };
    }

    if (code !== storedCode) {
      return { success: false, message: "Invalid code" };
    }

    await doc.ref.delete();
    return { success: true, message: "Email verified successfully" };
  } catch (error) {
    console.error("Error verifying code:", error);
    return { success: false, message: error.message };
  }
});

/**
 * Scheduled function to send daily user stats
 * Runs at 23:59 Istanbul time every day
 */
exports.sendDailyUserStats = onSchedule(
  {
    schedule: "59 23 * * *",
    timeZone: "Europe/Istanbul",
    timeoutSeconds: 300,
    memory: "256MiB",
    region: "europe-west3",
  },
  async (event) => {
    const now = new Date();
    const stats = await getUserStats(now);

    const transporter = createTransporter();
    if (!transporter) return;

    const mailOptions = {
      from: '"Goya HR Analytics 👥" <info@goyaapp.com>',
      to: "info@goyaapp.com",
      bcc: "omerkuntayozturk@gmail.com",
      subject: `📊 Goya HR Daily User Insights - ${now.toLocaleDateString('en-US')}`,
      html: `
      <div style="font-family: 'Segoe UI', sans-serif; max-width: 800px; margin: 0 auto; padding: 30px; background-color: #f8fafc;">
      <!-- Header Section -->
      <div style="text-align: center; margin-bottom: 30px; background: linear-gradient(135deg, #5271ff 0%, #5e85ff 100%); padding: 30px; border-radius: 15px; color: white;">
      <h1 style="margin: 0; font-size: 28px;">HR Management Analytics Report 👥</h1>
      <p style="margin: 10px 0 0 0; opacity: 0.9;">Transform your HR operations with our all-in-one platform!</p>
      <p style="margin: 5px 0 0 0; opacity: 0.9;">${now.toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</p>
      </div>

      <!-- Quick Summary Cards -->
      <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-bottom: 30px;">
      <div style="background: white; padding: 20px; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.05);">
      <div style="font-size: 24px; margin-bottom: 10px;">👥 Active Users</div>
      <div style="font-size: 32px; font-weight: bold; color: #5271ff;">${stats.allTime.total}</div>
      </div>
      <div style="background: white; padding: 20px; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.05);">
      <div style="font-size: 24px; margin-bottom: 10px;">⭐ Premium Users</div>
      <div style="font-size: 32px; font-weight: bold, color: #5271ff;">${stats.allTime.premium}</div>
      </div>
      </div>

      <!-- Key Features Section -->
      <div style="background: white; border-radius: 12px; padding: 25px; box-shadow: 0 4px 6px rgba(0,0,0,0.05); margin-bottom: 30px;">
      <h2 style="color: #1a1a1a; margin-top: 0; margin-bottom: 20px; font-size: 22px;">🌟 Key Features</h2>
      <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px;">
      <div style="padding: 15px; background: #f8fafc; border-radius: 8px;">
      <h3 style="margin: 0; color: #5271ff;">👥 Employee Management</h3>
      <p style="margin: 5px 0 0 0; color: #64748b;">Store complete profiles with advanced search and filtering</p>
      </div>
      <div style="padding: 15px; background: #f8fafc; border-radius: 8px;">
      <h3 style="margin: 0; color: #5271ff;">📝 Contract Management</h3>
      <p style="margin: 5px 0 0 0; color: #64748b;">Full lifecycle tracking with expiration notifications</p>
      </div>
      <div style="padding: 15px; background: #f8fafc; border-radius: 8px;">
      <h3 style="margin: 0; color: #5271ff;">🧠 Skills Management</h3>
      <p style="margin: 5px 0 0 0; color: #64748b;">Track employee capabilities and identify skill gaps</p>
      </div>
      <div style="padding: 15px; background: #f8fafc; border-radius: 8px;">
      <h3 style="margin: 0; color: #5271ff;">🏢 Org Structure</h3>
      <p style="margin: 5px 0 0 0; color: #64748b;">Interactive org charts showing departments and positions</p>
      </div>
      </div>
      </div>

      <!-- Growth Metrics -->
      <div style="background: white; border-radius: 12px; padding: 25px; box-shadow: 0 4px 6px rgba(0,0,0,0.05);">
      <h2 style="color: #1a1a1a; margin-top: 0; margin-bottom: 20px; font-size: 22px;">📈 User Growth Metrics</h2>
      <table style="width: 100%; border-collapse: separate; border-spacing: 0; margin-top: 10px;">
      <thead>
      <tr>
      <th style="padding: 12px; background: #f1f5f9; border-radius: 8px 0 0 8px; text-align: left; color: #64748b;">Period</th>
      <th style="padding: 12px; background: #f1f5f9; text-align: center; color: #64748b;">New Users</th>
      <th style="padding: 12px; background: #f1f5f9; text-align: center; color: #64748b;">Premium</th>
      <th style="padding: 12px; background: #f1f5f9; border-radius: 0 8px 8px 0; text-align: center; color: #64748b;">Conversion</th>
      </tr>
      </thead>
      <tbody>
      ${generateModernTableRow('Last 24 Hours 🕒', stats.daily)}
      ${generateModernTableRow('Last 7 Days 📅', stats.weekly)}
      ${generateModernTableRow('Last 30 Days 📆', stats.monthly)}
      ${generateModernTableRow('Last Year 🗓️', stats.yearly)}
      </tbody>
      </table>
      </div>

      <!-- Footer Section -->
      <div style="text-align: center; margin-top: 30px; color: #64748b; font-size: 14px;">
      <p>Automatically generated by Goya HR Analytics Engine 🤖</p>
      <p style="margin-top: 10px;">
      <a href="https://goyaapp.com" style="color: #5271ff; text-decoration: none;">View Full Analytics Dashboard →</a>
      </p>
      <p style="margin-top: 15px; color: #64748b; font-style: italic;">
      GOYA HR: Transform your HR operations with our all-in-one platform!
      </p>
      </div>
      `
    };

    await transporter.sendMail(mailOptions);
    console.log('Daily statistics email sent successfully.');
    
    return null;
  } 
);

/**
 * Helper function: Retrieves user statistics.
 */
async function getUserStats(now) {
  const firestore = admin.firestore();
  const usersRef = firestore.collection('users');
  
  // Date ranges
  const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
  const oneWeekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  const oneMonthAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
  const oneYearAgo = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000);

  // Get all users
  const snapshot = await usersRef.get();
  const users = snapshot.docs.map(doc => ({
    ...doc.data(),
    id: doc.id
  }));

  // Calculate stats
  const stats = {
    daily: {
      total: 0,
      premium: 0
    },
    weekly: {
      total: 0,
      premium: 0
    },
    monthly: {
      total: 0,
      premium: 0
    },
    yearly: {
      total: 0,
      premium: 0
    },
    allTime: {
      total: users.length,
      premium: users.filter(user => user.membershipStatus === 'premium').length
    }
  };

  users.forEach(user => {
    let registrationDate;
    
    try {
      // Try different date fields and formats
      if (user.registrationDate && typeof user.registrationDate.toDate === 'function') {
        registrationDate = user.registrationDate.toDate();
      } else if (user.createdAt && typeof user.createdAt.toDate === 'function') {
        registrationDate = user.createdAt.toDate();
      } else if (user.registrationDate instanceof Date) {
        registrationDate = user.registrationDate;
      } else if (user.createdAt instanceof Date) {
        registrationDate = user.createdAt;
      } else if (user.registrationDate) {
        registrationDate = new Date(user.registrationDate);
      } else if (user.createdAt) {
        registrationDate = new Date(user.createdAt);
      }
    } catch (error) {
      console.warn(`Failed to parse date for user ${user.id}:`, error);
      return; // Skip this user
    }

    if (!registrationDate || isNaN(registrationDate.getTime())) {
      console.warn(`Invalid or missing registration date for user ${user.id}`);
      return; // Skip this user
    }

    if (registrationDate >= oneDayAgo) {
      stats.daily.total++;
      if (user.membershipStatus === 'premium') stats.daily.premium++;
    }
    if (registrationDate >= oneWeekAgo) {
      stats.weekly.total++;
      if (user.membershipStatus === 'premium') stats.weekly.premium++;
    }
    if (registrationDate >= oneMonthAgo) {
      stats.monthly.total++;
      if (user.membershipStatus === 'premium') stats.monthly.premium++;
    }
    if (registrationDate >= oneYearAgo) {
      stats.yearly.total++;
      if (user.membershipStatus === 'premium') stats.yearly.premium++;
    }
  });

  return stats;
}

/**
 * Generates HTML rows for modern table styling in emails.
 */
function generateModernTableRow(label, data) {
  const conversionRate = data.total > 0 
    ? ((data.premium / data.total) * 100).toFixed(1)
    : '0.0';
  
  return `
    <tr style="border-bottom: 1px solid #f1f5f9;">
      <td style="padding: 16px; color: #1a1a1a; font-weight: 500;">${label}</td>
      <td style="padding: 16px; text-align: center; color: #5271ff; font-weight: 600;">${data.total}</td>
      <td style="padding: 16px; text-align: center; color: #5271ff; font-weight: 600;">${data.premium}</td>
      <td style="padding: 16px; text-align: center;">
        <span style="background: ${conversionRate > 20 ? '#dcfce7' : '#f1f5f9'}; 
                     color: ${conversionRate > 20 ? '#166534' : '#64748b'}; 
                     padding: 6px 12px; 
                     border-radius: 12px; 
                     font-size: 14px;">
          ${conversionRate}%
        </span>
      </td>
    </tr>
  `;
}

/**
 * Email templates for Goya ERP in English
 */
const unsubscribeTemplate = (userId) => `
  <div style="text-align: center; margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee;">
    <a href="https://goyaapp.com/unsubscribe?uid=${userId}" 
       style="color: #666; font-size: 12px; text-decoration: none;">
      Click here to unsubscribe
    </a>
  </div>
`;

const emailTemplates = {
  welcome: (userName) => ({
    subject: "🎉 Welcome to GOYA HR!",
    html: `
      <div style="font-family: 'Segoe UI', sans-serif; max-width: 600px; margin: 0 auto; padding: 30px; background-color: #f9f9f9;">
        <div style="text-align: center; margin-bottom: 30px;">
          <h1 style="color: #5271ff;">Welcome to GOYA HR! 👥</h1>
          <p style="font-size: 18px; color: #666;">
            Hello ${userName},<br>
            Your comprehensive HR management solution is ready to transform your operations!
          </p>
        </div>
        
        <div style="background: white; padding: 20px; border-radius: 10px; margin-bottom: 20px;">
          <h2 style="color: #5271ff;">Getting Started with GOYA HR 🎯</h2>
          <ul style="list-style: none; padding: 0; margin: 0;">
            <li style="margin: 10px 0;">👥 Comprehensive Employee Management - Store complete profiles with advanced search and filtering</li>
            <li style="margin: 10px 0;">📝 Contract Management - Full lifecycle tracking with expiration notifications</li>
            <li style="margin: 10px 0;">🧠 Skills and Talent Management - Track employee capabilities and identify skill gaps</li>
            <li style="margin: 10px 0;">🏢 Organizational Structure Visualization - Interactive org charts showing departments and positions</li>
            <li style="margin: 10px 0;">📊 Intelligent Dashboard - Real-time HR metrics with intuitive charts and analytics</li>
          </ul>
        </div>
        
        <div style="text-align: center; margin-top: 20px;">
          <a href="https://goyaapp.com/dashboard" 
             style="background: #5271ff; color: #fff; padding: 12px 24px; text-decoration: none; border-radius: 6px; font-size: 16px;">
            Start Managing Your HR
          </a>
        </div>
        
        {{unsubscribeButton}}
      </div>
    `
  }),

  purchaseConfirmation: (userName, planName, endDate) => ({
    subject: "🌟 Thank You! Your GOYA HR Premium Subscription is Activated",
    html: `
      <div style="font-family: 'Segoe UI', sans-serif; max-width: 600px; margin: 0 auto; padding: 30px; background-color: #f9f9f9;">
        <h1 style="color: #5271ff; text-align: center;">Premium Features Unlocked! 🎉</h1>
        <div style="background: white; padding: 20px; border-radius: 10px; margin-top: 20px;">
          <h2 style="color: #333;">Hello ${userName},</h2>
          <p>
            Welcome to GOYA HR Premium! <br>
            Current plan: <strong>${planName}</strong><br>
            Valid until: <strong>${endDate}</strong>
          </p>
          <p>You now have access to premium features to transform your HR operations:</p>
          <ul style="list-style: none; padding: 0; margin: 0;">
            <li>📊 Advanced HR Analytics Dashboard with workforce insights</li>
            <li>📝 Enhanced Contract Management with custom templates and automated workflows</li>
            <li>🧠 Comprehensive Skills Gap Analysis and development planning tools</li>
            <li>🏢 Advanced Organizational Structure with multi-level hierarchy visualization</li>
            <li>👥 Extended Employee Database with custom fields and detailed reporting</li>
          </ul>
        </div>
        
        {{unsubscribeButton}}
      </div>
    `
  }),

  passwordChanged: (userName) => ({
    subject: "🔐 Your GOYA HR Password Has Been Updated",
    html: `
      <div style="font-family: 'Segoe UI', sans-serif; max-width: 600px; margin: 0 auto; padding: 30px; background-color: #f9f9f9;">
        <h1 style="color: #5271ff; text-align: center;">Password Updated Successfully</h1>
        <div style="background: white; padding: 20px; border-radius: 10px;">
          <p>Hello ${userName},</p>
          <p>Your GOYA HR account password has been changed. If you didn't make this change, please contact support immediately.</p>
          <p>At GOYA HR, we take your employee data security seriously and recommend regular password updates to keep your sensitive information safe.</p>
        </div>
        
        {{unsubscribeButton}}
      </div>
    `
  }),

  accountDeleted: (userName) => ({
    subject: "👋 Your GOYA HR Account Has Been Deleted",
    html: `
      <div style="font-family: 'Segoe UI', sans-serif; max-width: 600px; margin: 0 auto; padding: 30px; background-color: #f9f9f9;">
        <h1 style="color: #5271ff; text-align: center;">Account Deleted</h1>
        <div style="background: white; padding: 20px; border-radius: 10px;">
          <p>Hello ${userName},</p>
          <p>Your GOYA HR account has been permanently deleted. We hope our application helped you with managing your workforce and HR processes.</p>
          <p>Whether you're a small business, growing company, or large enterprise, you're always welcome back when you're ready to transform your HR operations again!</p>
        </div>
      </div>
    `
  }),

  membershipCancelled: (userName) => ({
    subject: "Your GOYA HR Premium Membership Has Been Canceled",
    html: `
      <div style="font-family: 'Segoe UI', sans-serif; max-width: 600px; margin: 0 auto; padding: 30px; background-color: #f9f9f9;">
        <h1 style="color: #5271ff; text-align: center;">Premium Membership Canceled</h1>
        <div style="background: white; padding: 20px; border-radius: 10px;">
          <p>Hello ${userName},</p>
          <p>Your premium membership has been canceled. You can continue using our basic features to manage your HR operations.</p>
          <p>Upgrade anytime to regain access to our comprehensive HR solution with advanced features like detailed analytics, enhanced contract management, and organizational structure visualization!</p>
        </div>
        
        {{unsubscribeButton}}
      </div>
    `
  }),

  trialEnding: (userName) => ({
    subject: "🎁 Your GOYA HR Premium Trial Ends Tomorrow",
    html: `
      <div style="font-family: 'Segoe UI', sans-serif; max-width: 600px; margin: 0 auto; padding: 30px; background-color: #f9f9f9;">
        <h1 style="color: #5271ff; text-align: center;">Don't Miss Out on Premium Features!</h1>
        <div style="background: white; padding: 20px; border-radius: 10px;">
          <p>Hello ${userName},</p>
          <p>Your premium trial ends tomorrow. Continue transforming your HR operations with advanced features like:</p>
          <ul>
            <li>👥 Comprehensive Employee Management - Store complete profiles with advanced search and filtering</li>
            <li>📝 Contract Management - Full lifecycle tracking with expiration notifications</li>
            <li>🧠 Skills and Talent Management - Track employee capabilities and identify skill gaps</li>
            <li>🏢 Organizational Structure Visualization - Interactive org charts showing departments and positions</li>
            <li>📊 Intelligent Dashboard - Real-time HR metrics with intuitive charts and analytics</li>
          </ul>
          
          <div style="text-align: center; margin-top: 20px;">
            <a href="https://goyaapp.com/upgrade" 
               style="background: #5271ff; color: #fff; padding: 12px 24px; text-decoration: none; border-radius: 6px;">
              Upgrade to Premium
            </a>
          </div>
        </div>
        
        {{unsubscribeButton}}
      </div>
    `
  }),

  googleSignInVerification: (email, code) => ({
    subject: "Complete Your Google Sign-in - GOYA HR",
    html: `
      <div style="font-family: 'Segoe UI', sans-serif; max-width: 600px; margin: 0 auto; padding: 30px; background-color: #f9f9f9;">
        <div style="text-align: center; margin-bottom: 25px;">
          <h2 style="color: #5271ff; margin: 0; font-size: 28px; font-weight: 600;">Complete Your Google Sign-in</h2>
          <p style="color: #555; font-size: 16px; margin-top: 10px;">One step closer to transforming your HR operations with GOYA HR!</p>
        </div>
      
        <div style="background: linear-gradient(135deg, #5271ff 0%, #5e85ff 100%); padding: 20px; border-radius: 10px; text-align: center; margin: 25px 0;">
          <p style="color: white; font-size: 16px; margin: 0 0 10px 0;">Your verification code:</p>
          <h1 style="color: white; font-size: 38px; letter-spacing: 8px; margin: 10px 0; font-weight: 700;">${code}</h1>
          <p style="color: rgba(255,255,255,0.9); font-size: 14px; margin: 10px 0 0 0;">This code will expire in 5 minutes</p>
        </div>
        
        <div style="background: white; padding: 20px; border-radius: 10px; margin-top: 25px;">
          <h3 style="color: #5271ff; margin-top: 0;">🚀 Perfect for:</h3>
          <ul style="color: #555; padding-left: 20px;">
            <li>👥 Small and Medium-sized Enterprises looking to streamline HR processes</li>
            <li>🏢 Growing Companies wanting to organize their workforce data</li>
            <li>🏭 Enterprises seeking comprehensive employee management</li>
            <li>🚀 HR Managers who need powerful tools for talent management</li>
          </ul>
        </div>
        
        <p style="text-align: center; color: #888; font-size: 14px; margin-top: 25px;">
          GOYA HR takes your employee data security seriously. Your information is protected with our modern authentication system.
        </p>
      </div>
    `
  }),

  emailVerification: (email, code) => ({
    subject: "Verify Your Email - GOYA HR",
    html: `
      <div style="font-family: 'Segoe UI', sans-serif; max-width: 600px; margin: 0 auto; padding: 30px; background-color: #f9f9f9;">
        <div style="text-align: center; margin-bottom: 25px;">
          <h2 style="color: #5271ff; margin: 0; font-size: 28px; font-weight: 600;">Verify Your Email</h2>
          <p style="color: #555; font-size: 16px; margin-top: 10px;">Transform your HR operations with GOYA HR!</p>
        </div>
      
        <div style="background: linear-gradient(135deg, #5271ff 0%, #5e85ff 100%); padding: 20px; border-radius: 10px; text-align: center; margin: 25px 0;">
          <p style="color: white; font-size: 16px; margin: 0 0 10px 0;">Your verification code:</p>
          <h1 style="color: white; font-size: 38px; letter-spacing: 8px; margin: 10px 0; font-weight: 700;">${code}</h1>
          <p style="color: rgba(255,255,255,0.9); font-size: 14px; margin: 10px 0 0 0;">This code will expire in 5 minutes</p>
        </div>
        
        <div style="background: white; padding: 20px; border-radius: 10px; margin-top: 25px;">
          <h3 style="color: #5271ff; margin-top: 0;">🚀 GOYA HR Features:</h3>
          <ul style="color: #555; padding-left: 20px;">
            <li>👥 Comprehensive Employee Management - Store complete profiles with advanced search</li>
            <li>📝 Contract Management - Full lifecycle tracking with expiration notifications</li>
            <li>🧠 Skills and Talent Management - Track capabilities and identify skill gaps</li>
            <li>🏢 Organizational Structure - Interactive org charts showing departments and positions</li>
            <li>📊 Intelligent Dashboard - Real-time HR metrics with intuitive charts and analytics</li>
          </ul>
        </div>
        
        <p style="text-align: center; color: #888; font-size: 14px; margin-top: 25px;">
          With our modern and sleek design, GOYA HR works smoothly on mobile devices and tablets. 
          Take your HR operations to the next level, improve workforce management, and make data-driven decisions!
        </p>
      </div>
    `
  })
};

/**
 * A generic email sending function for Goya ERP.
 */
async function sendEmail(to, template, userId = null) {
  try {
    // Check if the user has unsubscribed.
    if (userId) {
      const userDoc = await admin.firestore().collection('users').doc(userId).get();
      const userData = userDoc.data();
      if (userData.unsubscribed) {
        console.log(`User ${userId} has unsubscribed from emails`);
        return { success: false, message: "User has unsubscribed" };
      }
    }

    const transporter = createTransporter();
    if (!transporter) {
      throw new Error("Email service configuration error");
    }

    // Insert the unsubscribe button if userId is provided.
    const htmlContent = userId
      ? template.html.replace('{{unsubscribeButton}}', unsubscribeTemplate(userId))
      : template.html.replace('{{unsubscribeButton}}', '');

    const mailOptions = {
      from: '"Goya HR" <info@goyaapp.com>',
      to,
      subject: template.subject,
      html: htmlContent
    };

    const info = await transporter.sendMail(mailOptions);
    
    // Log the email to Firestore.
    await admin.firestore().collection("EmailLogs").add({
      to,
      subject: template.subject,
      userId,
      type: template.subject.includes('Welcome')
        ? 'welcome'
        : template.subject.includes('Premium')
        ? 'premium'
        : 'notification',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      success: true,
      messageId: info.messageId
    });

    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error("Error sending email:", error);
    return { success: false, error: error.message };
  }
}

/**
 * Triggered email functions for different events.
 */

// Welcome email when a new user is created via Firebase Auth.
exports.sendWelcomeEmail = functions.auth.user().onCreate(async (user) => {
  const userName = user.displayName || 'Valued User';
  await sendEmail(user.email, emailTemplates.welcome(userName), user.uid);
});

// Purchase confirmation when membershipStatus changes to 'premium'.
exports.sendPurchaseConfirmation = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    
    if (newData.membershipStatus === 'premium' && oldData.membershipStatus !== 'premium') {
      await sendEmail(
        newData.email,
        emailTemplates.purchaseConfirmation(
          newData.profileName || 'Valued User',
          newData.membershipPlan,
          new Date(newData.membershipEndDate.toDate()).toLocaleDateString()
        ),
        context.params.userId
      );
    }
  });

// Password change notification (callable).
exports.sendPasswordChangeEmail = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new Error('Unauthorized');
  }

  const userDoc = await admin.firestore().collection('users').doc(context.auth.uid).get();
  const userData = userDoc.data();
  
  await sendEmail(
    userData.email,
    emailTemplates.passwordChanged(userData.profileName || 'Valued User'),
    context.auth.uid
  );
});

// Account deletion notification when a user is deleted from Firebase Auth.
exports.sendAccountDeletedEmail = functions.auth.user().onDelete(async (user) => {
  const userDoc = await admin.firestore().collection('users').doc(user.uid).get();
  const userData = userDoc.data();
  
  await sendEmail(
    user.email,
    emailTemplates.accountDeleted(userData.profileName || 'Valued User')
  );
});

// Membership cancellation notification.
exports.sendMembershipCancelledEmail = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const newData = change.after.data();
    const oldData = change.before.data();
    
    if (newData.membershipStatus === 'free' && oldData.membershipStatus === 'premium') {
      await sendEmail(
        newData.email,
        emailTemplates.membershipCancelled(newData.profileName || 'Valued User'),
        context.params.userId
      );
    }
  });

exports.checkTrialEndingUsers = onSchedule(
  {
    schedule: "0 10 * * *",
    timeZone: "Europe/Istanbul",
    timeoutSeconds: 300,
    memory: "256MiB",
    region: "europe-west3",
  },
  async (event) => {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);

    const qs = await admin
      .firestore()
      .collection("users")
      .where("membershipEndDate", "<=", tomorrow)
      .where("membershipStatus", "==", "starter")
      .get();

    for (const doc of qs.docs) {
      const u = doc.data();
      await sendEmail(
        u.email,
        emailTemplates.trialEnding(u.profileName || "Valued User"),
        doc.id
      );
    }
    console.log(`Trial-ending mails sent: ${qs.size}`);
    return null;
  }
);

// Unsubscribe handler for users to opt out of emails.
exports.handleUnsubscribe = functions.https.onRequest(async (req, res) => {
  try {
    const userId = req.query.uid;
    if (!userId) {
      res.status(400).send('User ID is required');
      return;
    }

    await admin.firestore().collection('users').doc(userId).update({
      unsubscribed: true,
      unsubscribedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    res.send(`
      <html>
      <body style="font-family: 'Segoe UI', Tahoma, sans-serif; text-align: center; padding: 50px; background-color: #f9f9f9; color: #333;">
        <div style="max-width: 600px; margin: 0 auto; background-color: white; padding: 30px; border-radius: 12px; box-shadow: 0 4px 8px rgba(0,0,0,0.05);">
        <h1 style="color: #5271ff;">Successfully Unsubscribed</h1>
        <p style="font-size: 16px; line-height: 1.5;">You will no longer receive emails from GOYA HR.</p>
        <p style="font-size: 16px; line-height: 1.5; margin-bottom: 25px;">If you change your mind, you can update your preferences in the <a href="https://goyaapp.com/settings" style="color: #5271ff; text-decoration: none; font-weight: bold;">Settings</a> section.</p>
        
        <div style="background-color: #f0f4ff; padding: 20px; border-radius: 8px; text-align: left; margin-top: 25px;">
          <h3 style="color: #5271ff; margin-top: 0;">Transform your HR operations with GOYA HR:</h3>
          <ul style="padding-left: 20px; color: #555;">
          <li>👥 Comprehensive Employee Management</li>
          <li>📝 Contract Management</li>
          <li>🧠 Skills and Talent Management</li>
          <li>🏢 Organizational Structure Visualization</li>
          <li>📊 Intelligent Dashboard</li>
          </ul>
        </div>
        </div>
      </body>
      </html>
    `);
  } catch (error) {
    console.error('Unsubscribe error:', error);
    res.status(500).send('Error processing your request');
  }
});

/**
 * Cloud function to mirror data from sub-user to parent user
 */
exports.mirrorSubUserData = functions.https.onCall(async (data, context) => {
  // Check if the request is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  try {
    const { userId, parentUserId, collectionName, documentId, data: docData, operation } = data;
    
    // Verify that the caller is either the sub-user or the parent user
    if (context.auth.uid !== userId && context.auth.uid !== parentUserId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'You do not have permission to mirror this data.'
      );
    }
    
    // Get the user document to verify the parent-child relationship
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(userId)
      .get();
      
    if (!userDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'User not found.'
      );
    }
    
    const userData = userDoc.data();
    
    // Verify that the specified parent is actually the parent of this user
    if (userData.parentUserId !== parentUserId) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'The specified parent user is not the actual parent of this user.'
      );
    }
    
    // Reference to the document in the parent's collection
    const parentDocRef = admin.firestore()
      .collection('users')
      .doc(parentUserId)
      .collection(collectionName)
      .doc(documentId);
      
    // Add tracking fields
    const enhancedData = {
      ...docData,
      originalCreatorId: userId,
      mirroredAt: admin.firestore.FieldValue.serverTimestamp(),
      mirroredBy: context.auth.uid,
    };
    
    // Perform the requested operation
    if (operation === 'add' || operation === 'update') {
      await parentDocRef.set(enhancedData, { merge: operation === 'update' });
      return { success: true, message: `Data successfully ${operation === 'add' ? 'added to' : 'updated in'} parent user's collection` };
    } 
    else if (operation === 'delete') {
      await parentDocRef.delete();
      return { success: true, message: 'Data successfully deleted from parent user\'s collection' };
    } 
    else {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid operation specified. Must be "add", "update", or "delete".'
      );
    }
  } catch (error) {
    console.error('Error in mirrorSubUserData:', error);
    throw new functions.https.HttpsError(
      'internal',
      'An error occurred while mirroring the data.',
      error.message
    );
  }
});

/**
 * Listen for data mirror requests and process them
 */
exports.processMirrorRequests = functions.firestore
  .document('data_mirror_requests/{requestId}')
  .onCreate(async (snapshot, context) => {
    try {
      const requestData = snapshot.data();
      const { userId, parentUserId, collectionName, documentId, data: docData, operation } = requestData;
      
      // Reference to the document in the parent's collection
      const parentDocRef = admin.firestore()
        .collection('users')
        .doc(parentUserId)
        .collection(collectionName)
        .doc(documentId);
        
      // Add tracking fields
      const enhancedData = {
        ...docData,
        originalCreatorId: userId,
        mirroredAt: admin.firestore.FieldValue.serverTimestamp(),
        mirroredVia: 'background-process',
      };
      
      // Perform the requested operation
      if (operation === 'add' || operation === 'update') {
        await parentDocRef.set(enhancedData, { merge: operation === 'update' });
      } 
      else if (operation === 'delete') {
        await parentDocRef.delete();
      }
      
      // Update the request status to 'completed'
      await snapshot.ref.update({ 
        status: 'completed',
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return { success: true };
    } catch (error) {
      console.error('Error processing mirror request:', error);
      
      // Update the request status to 'failed'
      await snapshot.ref.update({ 
        status: 'failed',
        error: error.message,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return { success: false, error: error.message };
    }
  });

/**
 * Sends a password reset email using our email template system (callable function).
 */
exports.sendPasswordResetEmail = functions.https.onCall(async (data, context) => {
  try {
    const { email } = data;
    
    if (!email) {
      return { 
        success: false, 
        message: "Email is required" 
      };
    }

    // Check if user exists in Firebase Auth
    try {
      const userRecord = await admin.auth().getUserByEmail(email);
      if (!userRecord) {
        return {
          success: false,
          message: "No user found with this email address"
        };
      }
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        return {
          success: false,
          message: "No user found with this email address"
        };
      }
      throw error;
    }

    // Create email transporter
    const transporter = createTransporter();
    if (!transporter) {
      return { 
        success: false, 
        message: "Email service configuration error" 
      };
    }

    // Generate password reset link
    const resetLink = await admin.auth().generatePasswordResetLink(email);

    // Get user profile data for personalization
    let userName = 'Valued User';
    try {
      const userRecord = await admin.auth().getUserByEmail(email);
      const userId = userRecord.uid;
      const userDoc = await admin.firestore().collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        const userData = userDoc.data();
        userName = userData.profileName || userData.username || userName;
      }
    } catch (error) {
      console.log('Error fetching user data for email personalization:', error);
      // Continue with default userName
    }

    // Use our password reset email template
    const mailOptions = {
      from: '"GOYA HR Support" <info@goyaapp.com>',
      to: email,
      subject: "Reset Your GOYA HR Password 🔑",
      html: `
      <div style="font-family: 'Segoe UI', sans-serif; max-width: 600px; margin: 0 auto; padding: 30px; background-color: #f9f9f9;">
      <div style="text-align: center; margin-bottom: 25px;">
        <h2 style="color: #5271ff; margin: 0; font-size: 28px; font-weight: 600;">Password Reset Request</h2>
        <p style="color: #555; font-size: 16px; margin-top: 10px;">We received a request to reset your GOYA HR password</p>
      </div>
      
      <div style="background: white; padding: 25px; border-radius: 12px; box-shadow: 0 4px 8px rgba(0,0,0,0.05); margin-bottom: 25px;">
        <p style="color: #333; font-size: 16px; margin-top: 0;">Hello ${userName},</p>
        <p style="color: #555; line-height: 1.5;">You recently requested to reset your password for your GOYA HR account. Click the button below to reset it:</p>
        
        <div style="text-align: center; margin: 30px 0;">
        <a href="${resetLink}" style="background: linear-gradient(135deg, #5271ff 0%, #5e85ff 100%); color: white; padding: 12px 30px; text-decoration: none; border-radius: 8px; font-size: 16px; font-weight: 600; display: inline-block;">Reset My Password</a>
        </div>
        
        <p style="color: #555; line-height: 1.5;">If you did not request a password reset, please ignore this email or contact support if you have questions.</p>
        
        <p style="color: #555; line-height: 1.5;">This password reset link will expire in 1 hour for security reasons.</p>
      </div>

      <div style="background: #f0f4ff; border-radius: 12px; padding: 20px; margin-top: 25px;">
        <h3 style="color: #5271ff; margin-top: 0; font-size: 18px;">🚀 GOYA HR Features:</h3>
        <ul style="color: #555; padding-left: 20px;">
        <li>👥 Comprehensive Employee Management - Store complete profiles with advanced search</li>
        <li>📝 Contract Management - Full lifecycle tracking with expiration notifications</li>
        <li>🧠 Skills and Talent Management - Track employee capabilities and identify skill gaps</li>
        <li>🏢 Organizational Structure Visualization - Interactive org charts showing departments</li>
        <li>📊 Intelligent Dashboard - Real-time HR metrics with intuitive charts and analytics</li>
        </ul>
      </div>
      
      <p style="text-align: center; color: #888; font-size: 14px; margin-top: 25px;">
        GOYA HR: Transform your HR operations with our all-in-one platform!
      </p>
      </div>
      `
    };

    // Send the email
    await transporter.sendMail(mailOptions);
    
    // Log the password reset request
    await admin.firestore().collection("EmailLogs").add({
      type: "password_reset",
      to: email,
      subject: "Password Reset Request",
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      success: true
    });

    return { 
      success: true, 
      message: "Password reset email sent successfully" 
    };
  } catch (error) {
    console.error("Error sending password reset email:", error);
    
    // Try the standard Firebase Auth method as fallback
    try {
      await admin.auth().generatePasswordResetLink(email);
      
      // Log the fallback attempt
      await admin.firestore().collection("EmailLogs").add({
        type: "password_reset_fallback",
        to: email,
        subject: "Password Reset Request (Fallback)",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        success: true,
        note: "Used fallback method due to error in primary method"
      });
      
      return { 
        success: true, 
        message: "Password reset email sent using fallback method" 
      };
    } catch (fallbackError) {
      console.error("Fallback password reset also failed:", fallbackError);
      
      await admin.firestore().collection("EmailLogs").add({
        type: "password_reset_failed",
        to: email,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        success: false,
        error: error.toString(),
        fallbackError: fallbackError.toString()
      });
      
      return { 
        success: false, 
        message: "Failed to send password reset email",
        error: error.message
      };
    }
  }
});
