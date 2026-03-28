const admin = require("firebase-admin");
const {onRequest, HttpsError} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");

admin.initializeApp();
setGlobalOptions({
  region: "asia-southeast2",
  maxInstances: 10,
});

const db = admin.firestore();

const JAKARTA_TIME_ZONE = "Asia/Jakarta";
const FREE_DAILY_LIMIT = 10;
const PREMIUM_MONTHLY_LIMIT = 500;
const MENTOR_MODEL = process.env.MENTOR_AI_MODEL || "gemini-2.5-flash";
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || "";
const GOOGLE_PLAY_PACKAGE_NAME = process.env.GOOGLE_PLAY_PACKAGE_NAME || "";
const GOOGLE_PLAY_SERVICE_ACCOUNT_JSON =
  process.env.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON || "";

const SYSTEM_PROMPT = `
Kamu adalah Andrew, mentor anti-prokrastinasi untuk anak muda Indonesia.
Kepribadianmu: hangat, energik, to-the-point, kadang pakai humor ringan.
Kamu membantu user:
- Memecah tugas besar jadi langkah kecil yang bisa langsung dikerjakan
- Mengatasi rasa malas dan prokrastinasi dengan teknik seperti Pomodoro dan time-blocking
- Memberikan motivasi yang spesifik dan realistis
- Memonitor jadwal dan target belajar

Aturan respons:
- Jawab dalam Bahasa Indonesia yang casual dan ramah
- Respons singkat dan langsung, maksimal 4 kalimat
- Kalau user stuck, kasih 1 langkah konkret yang bisa dilakukan sekarang
- Jangan panjang lebar kecuali diminta menjelaskan detail
- Panggil user dengan "kamu"
`.trim();

exports.mentorChatSend = onRequest({invoker: "public", cors: true}, async (req, res) => {
  await handleAuthedJsonRequest(req, res, async ({uid, data}) => {
    if (!GEMINI_API_KEY) {
      throw new HttpsError("failed-precondition", "GEMINI_API_KEY belum diset.");
    }

    const message = (data.message || "").toString().trim();
    const rawHistory = Array.isArray(data.history) ? data.history : [];
    if (!message) {
      throw new HttpsError("invalid-argument", "Pesan tidak boleh kosong.");
    }

    const initialQuota = await getQuotaStatus(uid);
    if (initialQuota.remaining <= 0) {
      throwQuotaError(initialQuota);
    }

    const history = rawHistory
        .slice(-8)
        .map((entry) => ({
          role: entry?.role === "model" ? "model" : "user",
          text: (entry?.text || "").toString().trim(),
        }))
        .filter((entry) => entry.text);

    const reply = await generateMentorReply(history, message);
    const updatedQuota = await db.runTransaction(async (transaction) => {
      const latestQuota = await getQuotaStatus(uid, transaction);
      if (latestQuota.remaining <= 0) {
        throwQuotaError(latestQuota);
      }

      const usageRef = getUsageDocRef(uid, latestQuota.plan, latestQuota.now);
      transaction.set(usageRef, {
        chatCount: admin.firestore.FieldValue.increment(1),
        lastRequestAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});

      const userRef = db.collection("users").doc(uid);
      transaction.set(userRef, {
        plan: latestQuota.plan,
        premiumStatus: latestQuota.premiumStatus,
        billingProvider: latestQuota.plan === "premium" ? "google_play" : "none",
        timezone: JAKARTA_TIME_ZONE,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});

      return {
        ...latestQuota,
        used: latestQuota.used + 1,
        remaining: Math.max(0, latestQuota.remaining - 1),
      };
    });

    return {
      reply,
      quota: serializeQuota(updatedQuota),
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

async function generateMentorReply(history, latestMessage) {
  const contents = [
    ...history.map((entry) => ({
      role: entry.role,
      parts: [{text: entry.text}],
    })),
    {
      role: "user",
      parts: [{text: latestMessage}],
    },
  ];

  const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${MENTOR_MODEL}:generateContent?key=${GEMINI_API_KEY}`,
      {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({
          systemInstruction: {
            parts: [{text: SYSTEM_PROMPT}],
          },
          contents,
          generationConfig: {
            temperature: 0.82,
            maxOutputTokens: 320,
          },
        }),
      },
  );

  if (!response.ok) {
    const payload = await response.text();
    throw new HttpsError(
        "internal",
        `Gemini request gagal: ${response.status}`,
        {payload},
    );
  }

  const json = await response.json();
  const reply = json?.candidates?.[0]?.content?.parts?.[0]?.text?.trim();
  if (!reply) {
    throw new HttpsError("internal", "Gemini tidak mengembalikan teks.");
  }
  return reply;
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

function throwQuotaError(quota) {
  throw new HttpsError(
      "resource-exhausted",
      "Kuota AI habis.",
      {
        reason: "quota-exhausted",
        ...serializeQuota(quota),
      },
  );
}

async function getQuotaStatus(uid, transaction = null) {
  const now = new Date();
  const jakarta = getJakartaParts(now);
  const userRef = db.collection("users").doc(uid);
  const userSnap = transaction ?
    await transaction.get(userRef) :
    await userRef.get();
  const userData = userSnap.data() || {};

  let plan = userData.plan === "premium" ? "premium" : "free";
  let premiumStatus = normalizePremiumStatus(userData.premiumStatus);
  const premiumUntil = userData.premiumUntil?.toDate ?
    userData.premiumUntil.toDate() :
    userData.premiumUntil ? new Date(userData.premiumUntil) : null;

  if (plan === "premium" && premiumUntil && premiumUntil <= now) {
    plan = "free";
    premiumStatus = "expired";
  }

  const usageRef = getUsageDocRef(uid, plan, jakarta);
  const usageSnap = transaction ?
    await transaction.get(usageRef) :
    await usageRef.get();
  const used = usageSnap.data()?.chatCount || 0;
  const limit = plan === "premium" ? PREMIUM_MONTHLY_LIMIT : FREE_DAILY_LIMIT;
  const remaining = Math.max(0, limit - used);
  const resetAt = plan === "premium" ?
    buildJakartaDateUtc(jakarta.year, jakarta.month + 1, 1, 0, 0) :
    buildJakartaDateUtc(jakarta.year, jakarta.month, jakarta.day + 1, 0, 0);

  return {
    now,
    plan,
    premiumStatus,
    premiumUntil,
    used,
    limit,
    remaining,
    resetAt,
  };
}

function getUsageDocRef(uid, plan, jakarta) {
  const usageCollection = db.collection("users").doc(uid).collection("usage");
  const month = String(jakarta.month).padStart(2, "0");
  const day = String(jakarta.day).padStart(2, "0");
  if (plan === "premium") {
    return usageCollection.doc(`monthly_${jakarta.year}${month}`);
  }
  return usageCollection.doc(`daily_${jakarta.year}${month}${day}`);
}

function getJakartaParts(date) {
  const formatter = new Intl.DateTimeFormat("en-CA", {
    timeZone: JAKARTA_TIME_ZONE,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hour12: false,
  });
  const parts = Object.fromEntries(
      formatter.formatToParts(date)
          .filter((part) => part.type !== "literal")
          .map((part) => [part.type, part.value]),
  );
  return {
    year: Number(parts.year),
    month: Number(parts.month),
    day: Number(parts.day),
    hour: Number(parts.hour),
    minute: Number(parts.minute),
    second: Number(parts.second),
  };
}

function buildJakartaDateUtc(year, month, day, hour, minute) {
  return new Date(Date.UTC(year, month - 1, day, hour - 7, minute, 0));
}

function normalizePremiumStatus(raw) {
  if (raw === "active" || raw === "grace" || raw === "expired") {
    return raw;
  }
  return "inactive";
}

function serializeQuota(quota) {
  return {
    plan: quota.plan,
    premiumStatus: quota.premiumStatus,
    limit: quota.limit,
    used: quota.used,
    remaining: quota.remaining,
    resetAt: quota.resetAt.toISOString(),
    premiumUntil: quota.premiumUntil ? quota.premiumUntil.toISOString() : null,
  };
}
