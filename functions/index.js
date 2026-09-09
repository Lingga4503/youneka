const admin = require("firebase-admin");
const {onRequest, HttpsError} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");
const {buildMentorReply} = require("./mentorRules");

admin.initializeApp();
setGlobalOptions({
  region: "asia-southeast2",
  maxInstances: 10,
});

const db = admin.firestore();

const JAKARTA_TIME_ZONE = "Asia/Jakarta";
const GOOGLE_PLAY_PACKAGE_NAME = process.env.GOOGLE_PLAY_PACKAGE_NAME || "";
const GOOGLE_PLAY_SERVICE_ACCOUNT_JSON =
  process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON || "";
const ADMIN_EMAILS = (process.env.ADMIN_EMAILS || "")
    .split(",")
    .map((value) => value.trim().toLowerCase())
    .filter(Boolean);

exports.mentorChatSend = onRequest({invoker: "public", cors: true}, async (req, res) => {
  await handleAuthedJsonRequest(req, res, async ({data}) => {
    const message = (data.message || "").toString().trim();
    if (!message) {
      throw new HttpsError("invalid-argument", "Pesan tidak boleh kosong.");
    }

    const result = buildMentorReply(message);
    return {
      reply: result.reply,
      toolCall: result.toolCall,
    };
  });
});

exports.activatePremiumSubscription = onRequest(
    {invoker: "public", cors: true},
    async (req, res) => {
      await handleAuthedJsonRequest(req, res, async ({uid, data}) => {
        const productId = (data.productId || "").toString().trim();
        const purchaseToken = (data.purchaseToken || "").toString().trim();
        if (!productId || !purchaseToken) {
          throw new HttpsError(
              "invalid-argument",
              "productId dan purchaseToken wajib diisi.",
          );
        }

        const verification = await verifyGooglePlaySubscription(purchaseToken);
        await persistSubscription(uid, {
          productId,
          purchaseToken,
          verification,
        });

        return {
          ok: true,
          premiumUntil: verification.expiryTime,
          status: verification.premiumStatus,
        };
      });
    },
);

exports.restorePremiumSubscription = onRequest(
    {invoker: "public", cors: true},
    async (req, res) => {
      await handleAuthedJsonRequest(req, res, async ({uid, data}) => {
        const purchaseToken = (data.purchaseToken || "").toString().trim();
        const productId = (data.productId || "").toString().trim();
        if (!productId || !purchaseToken) {
          throw new HttpsError(
              "invalid-argument",
              "productId dan purchaseToken wajib diisi.",
          );
        }

        const verification = await verifyGooglePlaySubscription(purchaseToken);
        await persistSubscription(uid, {
          productId,
          purchaseToken,
          verification,
        });

        return {
          ok: true,
          premiumUntil: verification.expiryTime,
          status: verification.premiumStatus,
        };
      });
    },
);

exports.sendAdminAnnouncement = onRequest(
    {invoker: "public", cors: true},
    async (req, res) => {
      await handleAuthedJsonRequest(req, res, async ({auth, data}) => {
        assertAdminAccess(auth);

        const title = (data.title || "").toString().trim();
        const body = (data.body || "").toString().trim();
        const targetType = (data.targetType || "email").toString().trim();
        const email = (data.email || "").toString().trim().toLowerCase();

        if (!title || !body) {
          throw new HttpsError(
              "invalid-argument",
              "Judul dan isi pesan wajib diisi.",
          );
        }
        if (title.length > 80) {
          throw new HttpsError(
              "invalid-argument",
              "Judul pesan maksimal 80 karakter.",
          );
        }
        if (body.length > 500) {
          throw new HttpsError(
              "invalid-argument",
              "Isi pesan maksimal 500 karakter.",
          );
        }

        let targetUserIds = [];
        let targetLabel = "";
        if (targetType === "all") {
          targetUserIds = await listAllUserIds();
          targetLabel = "all";
        } else if (targetType === "email") {
          if (!email) {
            throw new HttpsError(
                "invalid-argument",
                "Email target wajib diisi.",
            );
          }
          const user = await admin.auth().getUserByEmail(email);
          targetUserIds = [user.uid];
          targetLabel = email;
        } else {
          throw new HttpsError(
              "invalid-argument",
              "Target pesan tidak dikenali.",
          );
        }

        if (targetUserIds.length === 0) {
          throw new HttpsError(
              "failed-precondition",
              "Tidak ada user yang bisa dikirimi pesan.",
          );
        }

        await writeAnnouncementNotifications({
          userIds: targetUserIds,
          title,
          body,
          createdBy: auth.token.email || auth.uid,
          audience: targetType,
        });

        return {
          ok: true,
          sentCount: targetUserIds.length,
          targetType,
          targetLabel,
        };
      });
    },
);

async function handleAuthedJsonRequest(req, res, handler) {
  setJsonHeaders(res);

  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return;
  }

  if (req.method !== "POST") {
    sendError(res, 405, "method-not-allowed", "Metode tidak didukung.");
    return;
  }

  const idToken = extractBearerToken(req);
  if (!idToken) {
    sendError(res, 401, "unauthenticated", "Login Google wajib.");
    return;
  }

  try {
    const auth = await admin.auth().verifyIdToken(idToken);
    await maybeVerifyAppCheck(req);
    const data = normalizeBody(req.body);
    const result = await handler({
      uid: auth.uid,
      auth,
      data,
      req,
    });
    res.status(200).json(result);
  } catch (error) {
    handleHttpError(res, error);
  }
}

function setJsonHeaders(res) {
  res.set("Cache-Control", "no-store");
}

function extractBearerToken(req) {
  const header = req.get("Authorization") || "";
  const match = header.match(/^Bearer\s+(.+)$/i);
  return match ? match[1].trim() : "";
}

function normalizeBody(body) {
  if (!body) return {};
  if (typeof body === "string") {
    try {
      return JSON.parse(body);
    } catch (_) {
      throw new HttpsError("invalid-argument", "Body JSON tidak valid.");
    }
  }
  if (typeof body === "object") {
    return body;
  }
  throw new HttpsError("invalid-argument", "Body request tidak valid.");
}

async function maybeVerifyAppCheck(req) {
  const token = req.get("X-Firebase-AppCheck") || "";
  if (!token) return null;
  try {
    return await admin.appCheck().verifyToken(token);
  } catch (error) {
    console.warn("App Check token ignored:", error.message);
    return null;
  }
}

function assertAdminAccess(auth) {
  const email = (auth?.token?.email || "").toString().trim().toLowerCase();
  if (!email || !ADMIN_EMAILS.includes(email)) {
    throw new HttpsError(
        "permission-denied",
        "Akun ini tidak punya akses admin broadcast.",
    );
  }
}

function handleHttpError(res, error) {
  if (error instanceof HttpsError) {
    const status = httpsErrorStatus(error.code);
    sendError(res, status, error.code, error.message, error.details);
    return;
  }

  console.error("Unhandled mentor http error", error);
  sendError(res, 500, "internal", "Terjadi gangguan pada server mentor.");
}

function httpsErrorStatus(code) {
  switch (code) {
    case "invalid-argument":
      return 400;
    case "unauthenticated":
      return 401;
    case "permission-denied":
      return 403;
    case "resource-exhausted":
      return 429;
    case "failed-precondition":
      return 412;
    case "unavailable":
      return 503;
    default:
      return 500;
  }
}

function sendError(res, status, code, message, details) {
  const payload = {
    error: {
      code,
      message,
    },
  };

  if (details !== undefined) {
    payload.error.details = sanitizeDetails(details);
  }

  res.status(status).json(payload);
}

function sanitizeDetails(details) {
  if (details == null) return details;
  if (typeof details === "string" ||
      typeof details === "number" ||
      typeof details === "boolean") {
    return details;
  }

  try {
    return JSON.parse(JSON.stringify(details));
  } catch (_) {
    return {
      type: typeof details,
      message: details?.message || "non-serializable",
    };
  }
}

async function listAllUserIds() {
  let pageToken;
  const userIds = [];
  do {
    const page = await admin.auth().listUsers(1000, pageToken);
    userIds.push(...page.users.map((user) => user.uid));
    pageToken = page.pageToken;
  } while (pageToken);
  return userIds;
}

async function writeAnnouncementNotifications(input) {
  const chunks = [];
  for (let index = 0; index < input.userIds.length; index += 400) {
    chunks.push(input.userIds.slice(index, index + 400));
  }

  for (const chunk of chunks) {
    const batch = db.batch();
    for (const uid of chunk) {
      const ref = db.collection("users")
          .doc(uid)
          .collection("notifications")
          .doc();
      batch.set(ref, {
        id: ref.id,
        title: input.title,
        body: input.body,
        isRead: false,
        source: "admin",
        audience: input.audience,
        createdBy: input.createdBy,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}

async function persistSubscription(uid, input) {
  const userRef = db.collection("users").doc(uid);
  const subscriptionRef = userRef.collection("subscriptions").doc("current");
  const expiryTime = new Date(input.verification.expiryTime);

  await db.runTransaction(async (transaction) => {
    transaction.set(userRef, {
      plan: input.verification.isPremium ? "premium" : "free",
      premiumStatus: input.verification.premiumStatus,
      premiumUntil: expiryTime,
      billingProvider: input.verification.isPremium ? "google_play" : "none",
      timezone: JAKARTA_TIME_ZONE,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});

    transaction.set(subscriptionRef, {
      productId: input.productId,
      purchaseToken: input.purchaseToken,
      status: input.verification.subscriptionState,
      startedAt: input.verification.startTime ?
        new Date(input.verification.startTime) : null,
      expiryTime,
      lastVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
  });
}

async function verifyGooglePlaySubscription(purchaseToken) {
  if (!GOOGLE_PLAY_PACKAGE_NAME || !GOOGLE_PLAY_SERVICE_ACCOUNT_JSON) {
    throw new HttpsError(
        "failed-precondition",
        "Google Play verification env belum lengkap.",
    );
  }

  const {google} = require("googleapis");
  const credentials = JSON.parse(GOOGLE_PLAY_SERVICE_ACCOUNT_JSON);
  const auth = new google.auth.GoogleAuth({
    credentials,
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
  const client = await auth.getClient();
  const accessToken = await client.getAccessToken();

  const response = await fetch(
      `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${GOOGLE_PLAY_PACKAGE_NAME}/purchases/subscriptionsv2/tokens/${purchaseToken}`,
      {
        headers: {
          Authorization: `Bearer ${accessToken.token}`,
        },
      },
  );

  if (!response.ok) {
    const payload = await response.text();
    throw new HttpsError(
        "failed-precondition",
        "Verifikasi Google Play gagal.",
        {payload},
    );
  }

  const json = await response.json();
  const lineItem = json.lineItems?.[0] || {};
  const subscriptionState = json.subscriptionState ||
    "SUBSCRIPTION_STATE_UNSPECIFIED";
  const premiumStatus = subscriptionState === "SUBSCRIPTION_STATE_ACTIVE" ?
    "active" :
    subscriptionState === "SUBSCRIPTION_STATE_IN_GRACE_PERIOD" ?
      "grace" :
      "expired";

  return {
    subscriptionState,
    premiumStatus,
    isPremium: premiumStatus === "active" || premiumStatus === "grace",
    startTime: lineItem.startTime || null,
    expiryTime: lineItem.expiryTime || new Date().toISOString(),
  };
}
