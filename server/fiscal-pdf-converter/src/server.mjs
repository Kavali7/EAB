import express from "express";
import { execFile } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { basename, join } from "node:path";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);

const app = express();
const port = Number(process.env.PORT || 8080);
const maxUploadBytes = Number(process.env.MAX_UPLOAD_BYTES || 10 * 1024 * 1024);
const conversionTimeoutMs = Number(process.env.CONVERSION_TIMEOUT_MS || 60000);
const verifySupabaseJwt = process.env.VERIFY_SUPABASE_JWT !== "false";
const allowedOrigins = (process.env.ALLOWED_ORIGINS || "")
  .split(",")
  .map((origin) => origin.trim())
  .filter(Boolean);

app.use(
  express.json({
    limit: `${Math.ceil((maxUploadBytes * 4) / 3 + 1024)}b`,
  }),
);

app.use((req, res, next) => {
  const origin = req.get("origin");
  if (origin && (allowedOrigins.length === 0 || allowedOrigins.includes(origin))) {
    res.setHeader("Access-Control-Allow-Origin", origin);
    res.setHeader("Vary", "Origin");
  }
  res.setHeader("Access-Control-Allow-Headers", "authorization, content-type");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  if (req.method === "OPTIONS") return res.status(204).end();
  next();
});

app.get("/health", (_req, res) => {
  res.json({
    ok: true,
    converter:
      process.platform === "win32"
        ? "libreoffice-with-excel-com-fallback"
        : "libreoffice",
    verifySupabaseJwt,
    maxUploadBytes,
  });
});

app.post("/convert", async (req, res) => {
  try {
    await verifyRequest(req);

    const { filename, xlsxBase64 } = req.body || {};
    if (typeof filename !== "string" || typeof xlsxBase64 !== "string") {
      return res.status(400).json({
        error: "invalid_request",
        message: "filename et xlsxBase64 sont requis.",
      });
    }

    const xlsxBytes = Buffer.from(xlsxBase64, "base64");
    if (xlsxBytes.length === 0 || xlsxBytes.length > maxUploadBytes) {
      return res.status(413).json({
        error: "file_too_large",
        message: `Le fichier Excel depasse la taille autorisee (${maxUploadBytes} octets).`,
      });
    }

    const safeBaseName = sanitizeFilename(filename).replace(/\.xlsx$/i, "");
    console.log(
      JSON.stringify({
        event: "convert_start",
        filename: safeBaseName,
        bytes: xlsxBytes.length,
      }),
    );
    const tempDir = await mkdtemp(join(tmpdir(), "eab-fiscal-pdf-"));
    try {
      const inputPath = join(tempDir, `${safeBaseName}.xlsx`);
      const outputPath = join(tempDir, `${safeBaseName}.pdf`);
      await writeFile(inputPath, xlsxBytes);

      await convertWorkbookToPdf({
        inputPath,
        outputPath,
        outputDir: tempDir,
        timeout: conversionTimeoutMs,
      });

      const pdfBytes = await readFile(outputPath);
      res.setHeader("Content-Type", "application/pdf");
      res.setHeader("Cache-Control", "no-store");
      res.setHeader(
        "Content-Disposition",
        `attachment; filename="${safeBaseName}.pdf"`,
      );
      console.log(
        JSON.stringify({
          event: "convert_success",
          filename: safeBaseName,
          bytes: pdfBytes.length,
        }),
      );
      res.send(pdfBytes);
    } finally {
      await rm(tempDir, { recursive: true, force: true });
    }
  } catch (error) {
    const status = error.statusCode || 500;
    console.error(
      JSON.stringify({
        event: "convert_error",
        status,
        code: error.code,
        message: error.message,
      }),
    );
    res.status(status).json({
      error: error.code || "conversion_failed",
      message:
        status === 500
          ? "La conversion PDF a echoue. Verifiez LibreOffice et les logs du service."
          : error.message,
    });
  }
});

app.listen(port, () => {
  console.log(`Fiscal PDF converter listening on ${port}`);
});

async function verifyRequest(req) {
  if (!verifySupabaseJwt) return;

  const supabaseUrl = process.env.SUPABASE_URL;
  const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;
  if (!supabaseUrl || !supabaseAnonKey) {
    const error = new Error("SUPABASE_URL et SUPABASE_ANON_KEY sont requis.");
    error.statusCode = 500;
    error.code = "missing_supabase_config";
    throw error;
  }

  const auth = req.get("authorization") || "";
  if (!auth.toLowerCase().startsWith("bearer ")) {
    const error = new Error("Token utilisateur manquant.");
    error.statusCode = 401;
    error.code = "missing_token";
    throw error;
  }

  const response = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: {
      apikey: supabaseAnonKey,
      authorization: auth,
    },
  });
  if (!response.ok) {
    const error = new Error("Token utilisateur invalide.");
    error.statusCode = 401;
    error.code = "invalid_token";
    throw error;
  }
}

function sanitizeFilename(filename) {
  const clean = basename(filename)
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9_.-]+/g, "_")
    .replace(/_+/g, "_")
    .replace(/^_+|_+$/g, "");
  return clean.endsWith(".xlsx") ? clean : `${clean || "dossier_fiscal"}.xlsx`;
}

async function convertWorkbookToPdf({ inputPath, outputPath, outputDir, timeout }) {
  try {
    await execFileAsync(
      "soffice",
      [
        "--headless",
        "--nologo",
        "--nofirststartwizard",
        "--convert-to",
        "pdf",
        "--outdir",
        outputDir,
        inputPath,
      ],
      { timeout },
    );
    return;
  } catch (error) {
    if (!canFallbackToExcelCom(error)) throw error;
  }

  await convertWithExcelCom({ inputPath, outputPath, timeout });
}

function canFallbackToExcelCom(error) {
  return process.platform === "win32" && error?.code === "ENOENT";
}

async function convertWithExcelCom({ inputPath, outputPath, timeout }) {
  const scriptPath = `${outputPath}.ps1`;
  const script = `
param([string]$InputWorkbook, [string]$OutputPdf)
$ErrorActionPreference = 'Stop'
$excel = $null
$workbook = $null
try {
  $excel = New-Object -ComObject Excel.Application
  $excel.Visible = $false
  $excel.DisplayAlerts = $false
  $workbook = $excel.Workbooks.Open($InputWorkbook, 3, $true)
  $workbook.ExportAsFixedFormat(0, $OutputPdf)
  $workbook.Close($false)
} finally {
  if ($workbook -ne $null) {
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($workbook) | Out-Null
  }
  if ($excel -ne $null) {
    $excel.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($excel) | Out-Null
  }
  [GC]::Collect()
  [GC]::WaitForPendingFinalizers()
}
`;
  await writeFile(scriptPath, script, "utf8");
  await execFileAsync(
    "powershell.exe",
    [
      "-NoProfile",
      "-ExecutionPolicy",
      "Bypass",
      "-File",
      scriptPath,
      inputPath,
      outputPath,
    ],
    { timeout },
  );
}
