const { onCall, HttpsError } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');
const { Resend } = require('resend');

admin.initializeApp();

// Initialize Resend with API key from environment variables (or hardcoded placeholder for local testing)
// We will use process.env.RESEND_API_KEY for Firebase v2 environment variables
const resend = new Resend(process.env.RESEND_API_KEY || 're_placeholder'); 

/**
 * Generates a random 6-digit code.
 */
function generateVerificationCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

/**
 * Callable function to send a verification code to the authenticated user.
 */
exports.sendVerificationCode = onCall(async (request) => {
  // 1. Ensure the user is authenticated
  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  const uid = request.auth.uid;

  try {
    // 2. Fetch the user's email from Firebase Auth
    const userRecord = await admin.auth().getUser(uid);
    const email = userRecord.email;

    if (!email) {
      throw new HttpsError(
        'failed-precondition',
        'User does not have an email address.'
      );
    }

    if (userRecord.emailVerified) {
       return { success: true, message: 'Email is already verified.' };
    }

    // 3. Generate a 6-digit code and expiration (15 minutes from now)
    const code = generateVerificationCode();
    const expiresAt = admin.firestore.Timestamp.fromDate(new Date(Date.now() + 15 * 60 * 1000));

    // 4. Save the code securely in a private collection (e.g., 'verificationCodes')
    await admin.firestore().collection('verificationCodes').doc(uid).set({
      code: code,
      expiresAt: expiresAt,
      email: email, // Store email for auditing
    });

    const response = await resend.emails.send({
      from: 'ExpertMoney <no-reply@expert-money.com>',
      to: email,
      subject: 'Your ExpertMoney Verification Code',
      html: `
        <div style="font-family: sans-serif; text-align: center; padding: 20px;">
          <h2>ExpertMoney</h2>
          <p>Hi there,</p>
          <p>Thank you for registering! Please use the following 6-digit code to verify your email address:</p>
          <div style="background-color: #f4f4f4; padding: 15px; font-size: 24px; font-weight: bold; letter-spacing: 5px; border-radius: 8px; margin: 20px auto; width: fit-content;">
            ${code}
          </div>
          <p>This code will expire in 15 minutes.</p>
          <p>If you did not request this, please ignore this email.</p>
        </div>
      `,
    });

    if (response.error) {
      console.error('Resend API Error:', response.error);
      throw new HttpsError('internal', 'Failed to send email: ' + response.error.message);
    }

    return { success: true, message: 'Verification code sent successfully.' };

  } catch (error) {
    console.error('Error in sendVerificationCode:', error);
    throw new HttpsError('internal', 'An error occurred while sending the email.', error.message);
  }
});


/**
 * Callable function to verify the 6-digit code provided by the user.
 */
exports.verifyCode = onCall(async (request) => {
  // 1. Ensure authenticated
  if (!request.auth) {
    throw new HttpsError(
      'unauthenticated',
      'The function must be called while authenticated.'
    );
  }

  const uid = request.auth.uid;
  const userCode = request.data.code;

  if (!userCode || typeof userCode !== 'string' || userCode.length !== 6) {
    throw new HttpsError(
      'invalid-argument',
      'A valid 6-digit code is required.'
    );
  }

  try {
    const docRef = admin.firestore().collection('verificationCodes').doc(uid);
    const doc = await docRef.get();

    if (!doc.exists) {
      throw new HttpsError('not-found', 'No verification code found. Please request a new one.');
    }

    const verificationData = doc.data();

    // 2. Check if the code has expired
    if (verificationData.expiresAt.toDate() < new Date()) {
      throw new HttpsError('failed-precondition', 'The verification code has expired. Please request a new one.');
    }

    // 3. Check if the code matches
    if (verificationData.code !== userCode) {
      throw new HttpsError('invalid-argument', 'The verification code is incorrect.');
    }

    // 4. Code is valid! Update the user's emailVerified status
    await admin.auth().updateUser(uid, {
      emailVerified: true
    });

    // 5. Clean up the used code from Firestore
    await docRef.delete();

    return { success: true, message: 'Email verified successfully.' };

  } catch (error) {
    console.error('Error in verifyCode:', error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError('internal', 'An error occurred while verifying the code.', error.message);
  }
});
