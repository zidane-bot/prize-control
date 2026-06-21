const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

/**
 * TRIGGER: onSessionCreated
 * Triggered when a new session document is created in the 'sessions' collection.
 * Sends a custom security verification email to the user.
 */
exports.onSessionCreated = onDocumentCreated("sessions/{sessionId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) return;

  const data = snapshot.data();
  const sessionId = event.params.sessionId;
  const email = data.email;
  const deviceInfo = data.deviceInfo || {};
  const time = new Date().toLocaleString("id-ID", { timeZone: "Asia/Jakarta" });

  // SMTP configuration for Gmail
  const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
  });

  // Action URLs (Update with your project's region and ID)
  const projectId = process.env.GCLOUD_PROJECT;
  const region = "us-central1"; 
  const baseUrl = `https://${region}-${projectId}.cloudfunctions.net`;
  
  const approveUrl = `${baseUrl}/approveLogin?sessionId=${sessionId}`;
  const blockUrl = `${baseUrl}/blockLogin?sessionId=${sessionId}`;

  const htmlContent = `
    <div style="font-family: 'Arial', sans-serif; background-color: #0A0E14; color: #FFFFFF; padding: 40px; border-radius: 12px; max-width: 600px; margin: auto; border: 1px solid #1E293B;">
      <h2 style="color: #00FF9C; letter-spacing: 2px; font-family: 'Courier New', monospace;">BITANIC PRECISION CONTROL</h2>
      <hr style="border: 0; border-top: 1px solid #1E293B; margin: 24px 0;">
      <p style="font-size: 18px;">Halo,</p>
      <p style="font-size: 16px; line-height: 1.6; color: #CBD5E1;">
        Kami mendeteksi upaya login baru ke akun BITANIC Anda. Silakan verifikasi apakah ini adalah Anda.
      </p>
      
      <div style="background-color: #121820; padding: 20px; border-radius: 8px; margin: 24px 0; border-left: 4px solid #00FF9C;">
        <p style="margin: 0; font-weight: bold; color: #00FF9C;">Detail Login:</p>
        <ul style="list-style: none; padding: 0; margin: 12px 0; color: #94A3B8;">
          <li><strong>Perangkat:</strong> ${deviceInfo.model || "Unknown"} ${deviceInfo.os || ""}</li>
          <li><strong>Waktu:</strong> ${time} WIB</li>
          <li><strong>Lokasi:</strong> Capture by IP (Backend)</li>
        </ul>
      </div>

      <div style="margin-top: 32px; display: flex; gap: 10px;">
        <a href="${approveUrl}" style="background-color: #00FF9C; color: #000000; padding: 14px 28px; text-decoration: none; border-radius: 6px; font-weight: bold; font-size: 14px; text-align: center; display: inline-block;">YA, INI SAYA</a>
        <a href="${blockUrl}" style="background-color: #EF4444; color: #FFFFFF; padding: 14px 28px; text-decoration: none; border-radius: 6px; font-weight: bold; font-size: 14px; text-align: center; display: inline-block;">TIDAK, AMANKAN AKUN</a>
      </div>

      <p style="font-size: 12px; color: #475569; margin-top: 40px; text-align: center;">
        Pesan ini dikirimkan otomatis demi keamanan akun Anda. Jika Anda tidak merasa melakukan tindakan ini, segera klik tombol "AMANKAN AKUN".
      </p>
    </div>
  `;

  try {
    await transporter.sendMail({
      from: '"BITANIC Security" <security@bitanic.com>',
      to: email,
      subject: "Keamanan: Upaya login baru di BITANIC Precision Control",
      html: htmlContent,
    });
    logger.info(`Verification email sent to ${email} for session ${sessionId}`);
  } catch (error) {
    logger.error("Error sending email:", error);
  }
});

/**
 * HTTPS ENDPOINT: approveLogin
 * Updates the session status to 'APPROVED' in Firestore.
 */
exports.approveLogin = onRequest(async (req, res) => {
  const sessionId = req.query.sessionId;
  if (!sessionId) {
    return res.status(400).send("Session ID is missing");
  }

  try {
    await admin.firestore().collection("sessions").doc(sessionId).update({
      status: "APPROVED",
      approvedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    res.send(`
      <html>
        <body style="font-family: sans-serif; text-align: center; padding-top: 100px; background-color: #0A0E14; color: white;">
          <h1 style="color: #00FF9C;">LOGIN DISETUJUI</h1>
          <p>Aplikasi Anda akan segera masuk ke Dashboard secara otomatis.</p>
          <script>setTimeout(() => window.close(), 3000);</script>
        </body>
      </html>
    `);
  } catch (error) {
    logger.error("Error approving login:", error);
    res.status(500).send("Internal Server Error");
  }
});

/**
 * HTTPS ENDPOINT: blockLogin
 * Updates the session status to 'BLOCKED' and disables the user account.
 */
exports.blockLogin = onRequest(async (req, res) => {
  const sessionId = req.query.sessionId;
  if (!sessionId) {
    return res.status(400).send("Session ID is missing");
  }

  try {
    const sessionDoc = await admin.firestore().collection("sessions").doc(sessionId).get();
    if (!sessionDoc.exists) {
      return res.status(404).send("Session not found");
    }

    const { uid } = sessionDoc.data();

    // Block session
    await admin.firestore().collection("sessions").doc(sessionId).update({
      status: "BLOCKED",
      blockedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Disable Firebase Auth Account
    await admin.auth().updateUser(uid, { disabled: true });

    res.send(`
      <html>
        <body style="font-family: sans-serif; text-align: center; padding-top: 100px; background-color: #0A0E14; color: white;">
          <h1 style="color: #EF4444;">AKUN DIAMANKAN</h1>
          <p>Upaya login telah diblokir dan akun Anda telah dinonaktifkan sementara demi keamanan.</p>
          <p>Silakan hubungi administrator untuk pemulihan akun.</p>
        </body>
      </html>
    `);
  } catch (error) {
    logger.error("Error blocking login:", error);
    res.status(500).send("Internal Server Error");
  }
});

exports.debugUsers = onRequest(async (req, res) => {
  try {
    const snap = await admin.firestore().collection("users").get();
    const users = [];
    snap.forEach(doc => {
      users.push({ id: doc.id, ...doc.data() });
    });
    res.json(users);
  } catch (error) {
    res.status(500).send(error.toString());
  }
});
