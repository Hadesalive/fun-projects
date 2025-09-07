import admin from 'firebase-admin';

class FirebaseAdminService {
  constructor() {
    this.initialized = false;
  }

  // Initialize Firebase Admin SDK
  initialize() {
    if (this.initialized) return;

    try {
      // For development: Use the Firebase project ID from your client config
      // In production: Use service account key file
      if (!admin.apps.length) {
        admin.initializeApp({
          projectId: process.env.FIREBASE_PROJECT_ID || 'your-project-id',
          // For production, add service account:
          // credential: admin.credential.cert(serviceAccountKey),
        });
      }
      
      this.initialized = true;
      console.log('🔥 Firebase Admin SDK initialized');
    } catch (error) {
      console.error('❌ Firebase Admin initialization error:', error.message);
      // Don't throw - allow app to continue with limited functionality
    }
  }

  // Verify Firebase ID token
  async verifyIdToken(idToken) {
    try {
      if (!this.initialized) {
        this.initialize();
      }

      if (!admin.apps.length) {
        throw new Error('Firebase Admin not initialized');
      }

      const decodedToken = await admin.auth().verifyIdToken(idToken);
      
      return {
        success: true,
        uid: decodedToken.uid,
        phoneNumber: decodedToken.phone_number,
        email: decodedToken.email,
        name: decodedToken.name,
        picture: decodedToken.picture,
        authTime: new Date(decodedToken.auth_time * 1000),
        issuedAt: new Date(decodedToken.iat * 1000),
      };
    } catch (error) {
      console.error('Firebase token verification error:', error.message);
      
      return {
        success: false,
        error: this._getErrorMessage(error),
        code: error.code || 'VERIFICATION_FAILED'
      };
    }
  }

  // Get user-friendly error message
  _getErrorMessage(error) {
    switch (error.code) {
      case 'auth/id-token-expired':
        return 'Token has expired. Please sign in again.';
      case 'auth/id-token-revoked':
        return 'Token has been revoked. Please sign in again.';
      case 'auth/invalid-id-token':
        return 'Invalid token format.';
      case 'auth/project-not-found':
        return 'Firebase project not found.';
      case 'auth/user-not-found':
        return 'User not found.';
      default:
        return 'Token verification failed.';
    }
  }

  // Check if Firebase Admin is available
  isAvailable() {
    return this.initialized && admin.apps.length > 0;
  }
}

export default new FirebaseAdminService();
