const JAKARTA_TIME_ZONE = "Asia/Jakarta";

const ADD_TASK_TRIGGERS = [
  "tambahkan tugas", "tambah tugas", "tolong catat", "catat tugas",
  "ingatkan aku untuk", "ingatkan aku", "buatkan tugas", "buat tugas",
  "tambahkan jadwal", "jadwalkan",
];

const GREETING_TRIGGERS = ["halo", "hai", "hi", "pagi", "siang", "malam"];

const DEFAULT_REPLY =
  "Andrew saat ini hanya bisa membantu topik tertentu: mengatur napas, " +
  "memulai fokus/pomodoro, deep work, musik fokus, mengatasi malas, cara " +
  "pakai fitur, dan menambahkan tugas. Coba tulis ulang permintaanmu, " +
  "misalnya \"tambahkan tugas belajar besok jam 9\".";

/**
 * @param {string} message - pesan mentah dari user
 * @returns {{reply: string, toolCall: {name: string, args: object} | null}}
 * Tidak pernah throw; selalu mengembalikan reply penuh (tidak ada fallback ke
 * LLM lagi, jadi fungsi ini exhaustive).
 */
function buildMentorReply(message) {
  const text = normalizeMentorText(message);

  const addTaskMatch = tryMatchAddTask(text);
  if (addTaskMatch) return addTaskMatch;

  const cannedReply = tryBuildCannedReply(text);
  if (cannedReply) return {reply: cannedReply, toolCall: null};

  if (includesAny(text, GREETING_TRIGGERS) && text.length <= 20) {
    return {
      reply: "Halo. Ada tugas yang mau kamu mulai atau rencanakan hari ini?",
      toolCall: null,
    };
  }

  return {reply: DEFAULT_REPLY, toolCall: null};
}

function tryMatchAddTask(normalized) {
  const trigger = ADD_TASK_TRIGGERS.find((t) => normalized.includes(t));
  if (!trigger) return null;

  const remainder = stripTrigger(normalized, trigger);
  const {cleanText, startAt} = extractDateTimePhrase(remainder);
  const title = titleCase(cleanText.trim());
  if (!title) return null;

  return {
    reply: buildAddTaskConfirmation(title, startAt),
    toolCall: {
      name: "add_task",
      args: {
        title,
        start_at: startAt ? startAt.toISOString() : undefined,
        description: "",
      },
    },
  };
}

function stripTrigger(text, trigger) {
  const idx = text.indexOf(trigger);
  if (idx < 0) return text;
  return (text.slice(0, idx) + " " + text.slice(idx + trigger.length)).trim();
}

const DAY_OFFSETS = [
  {pattern: /\bhari ini\b/, offset: 0},
  {pattern: /\bsekarang\b/, offset: 0},
  {pattern: /\bbesok\b/, offset: 1},
  {pattern: /\blusa\b/, offset: 2},
  {pattern: /\bminggu depan\b/, offset: 7},
];

const TIME_PATTERN = /\bjam\s*(\d{1,2})(?:[:.](\d{2}))?\b|\b(\d{1,2}):(\d{2})\b/;

function extractDateTimePhrase(text) {
  let cleanText = text;
  let dayOffset = null;

  for (const day of DAY_OFFSETS) {
    if (day.pattern.test(cleanText)) {
      dayOffset = day.offset;
      cleanText = cleanText.replace(day.pattern, " ").replace(/\s+/g, " ").trim();
      break;
    }
  }

  let hour = null;
  let minute = 0;
  const timeMatch = cleanText.match(TIME_PATTERN);
  if (timeMatch) {
    hour = Number(timeMatch[1] !== undefined ? timeMatch[1] : timeMatch[3]);
    const rawMinute = timeMatch[2] !== undefined ? timeMatch[2] : timeMatch[4];
    minute = rawMinute !== undefined ? Number(rawMinute) : 0;
    cleanText = cleanText.replace(TIME_PATTERN, " ").replace(/\s+/g, " ").trim();
  }

  if (dayOffset === null && hour === null) {
    return {cleanText, startAt: null};
  }

  const effectiveDayOffset = dayOffset === null ? 0 : dayOffset;
  const effectiveHour = hour === null ? 9 : hour;
  const now = new Date();
  const jakarta = getJakartaParts(now);
  const startAt = buildJakartaDateUtc(
      jakarta.year,
      jakarta.month,
      jakarta.day + effectiveDayOffset,
      effectiveHour,
      minute,
  );

  return {cleanText, startAt};
}

function titleCase(text) {
  if (!text) return "";
  return text.charAt(0).toUpperCase() + text.slice(1);
}

function buildAddTaskConfirmation(title, startAt) {
  if (!startAt) {
    return `Sudah kutambahkan tugas "${title}" ke daftar.`;
  }
  const jakarta = getJakartaParts(startAt);
  const pad = (value) => String(value).padStart(2, "0");
  const dateStr = `${pad(jakarta.day)}/${pad(jakarta.month)}`;
  const timeStr = `${pad(jakarta.hour)}:${pad(jakarta.minute)}`;
  return `Sudah kutambahkan tugas "${title}" untuk ${dateStr} pukul ${timeStr} WIB.`;
}

function tryBuildCannedReply(text) {
  if (!text || text.length > 120) return null;

  if (includesAny(text, [
    "atur napas", "napas", "bernapas", "tenangkan pikiran", "relax mode",
  ])) {
    return "Baik. Kita mulai dari hal yang paling sederhana. Tarik napas selama empat hitungan, tahan empat hitungan, lalu hembuskan enam hitungan. Ulangi lima kali. Setelah itu, baru putuskan langkah berikutnya.";
  }

  if (includesAny(text, [
    "fokus cepat", "mulai fokus", "pomodoro", "25 menit", "15 menit",
  ])) {
    return "Jangan menunggu motivasi terasa sempurna. Siapkan satu tugas saja, aktifkan sesi fokus singkat, lalu kerjakan tanpa menilai hasilnya selama lima belas hingga dua puluh lima menit. Tugasmu saat ini hanya memulai.";
  }

  if (includesAny(text, [
    "deep work", "kerja serius", "tanpa distraksi",
  ])) {
    return "Untuk deep work, singkirkan semua distraksi sebelum memulai. Pilih satu pekerjaan bernilai tinggi, tentukan durasi yang jelas, lalu bekerja tanpa berpindah konteks sampai sesi berakhir. Disiplin awal lebih penting daripada durasi panjang.";
  }

  if (includesAny(text, [
    "musik fokus", "musik kerja", "suara fokus",
  ])) {
    return "Gunakan musik yang stabil, minim lirik, dan tidak menuntut perhatian. Tujuannya bukan hiburan, melainkan menjaga ritme kerja tetap tenang. Setelah musik berjalan, langsung mulai tugas pertamamu.";
  }

  if (includesAny(text, [
    "cara pakai", "fitur", "list", "tugas apa saja",
  ])) {
    return "Tulis tugasmu lewat chat ini, misalnya \"tambahkan tugas belajar besok jam 9\", lalu buka daftarnya di halaman utama. Tap satu tugas untuk mulai sesi fokus Pomodoro.";
  }

  if (includesAny(text, [
    "malas", "mager", "sulit fokus",
  ]) && text.length <= 40) {
    return "Kalau demikian, jangan mencoba memperbaiki seluruh harimu. Pilih satu langkah yang terlalu kecil untuk ditolak, lalu kerjakan selama lima menit. Setelah itu, baru nilai apakah kamu perlu melanjutkan.";
  }

  return null;
}

function normalizeMentorText(input) {
  return (input || "")
      .toString()
      .trim()
      .toLowerCase()
      .replace(/\s+/g, " ");
}

function includesAny(text, keywords) {
  return keywords.some((keyword) => text.includes(keyword));
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

module.exports = {buildMentorReply};
