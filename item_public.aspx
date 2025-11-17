<%@ Page Language="C#" %>
<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <title>도면 정보</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI",
        "Apple SD Gothic Neo", sans-serif;
      background: #f5f5f7;
      color: #222;
    }
    .page {
      max-width: 960px;
      margin: 32px auto;
      padding: 16px;
    }
    .card {
      background: #fff;
      border-radius: 16px;
      box-shadow: 0 10px 30px rgba(0,0,0,0.04);
      padding: 24px 28px;
    }
    h1 {
      margin: 0 0 8px;
      font-size: 24px;
    }
    .subtitle {
      margin-bottom: 24px;
      color: #666;
      font-size: 13px;
    }
    .status {
      margin-bottom: 16px;
      font-size: 14px;
    }
    .status strong { font-weight: 600; }
    .status.ok { color: #0f893a; }
    .status.warn { color: #a86b00; }
    .status.err { color: #b10000; }

    table {
      width: 100%;
      border-collapse: collapse;
      font-size: 14px;
    }
    th, td {
      padding: 8px 10px;
      border-bottom: 1px solid #eee;
      vertical-align: top;
    }
    th {
      width: 140px;
      font-weight: 600;
      color: #555;
      text-align: left;
      background: #fafafa;
    }
    tr:last-child td { border-bottom: none; }

    a {
      color: #0366d6;
      text-decoration: none;
    }
    a:hover { text-decoration: underline; }

    .debug {
      margin-top: 16px;
      font-size: 11px;
      color: #999;
      word-break: break-all;
    }
  </style>
</head>
<body>
  <div class="page">
    <div class="card">
      <h1>도면 정보</h1>
      <div class="subtitle" id="subtitle">로딩 중…</div>

      <div class="status" id="status"></div>

      <table id="info-table" style="display:none;">
        <tbody id="info-body"></tbody>
      </table>

      <div class="debug" id="debug"></div>
    </div>
  </div>

  <script>
    // ▼▼▼ drawings.json 위치 (경로 바뀌면 이 줄만 수정) ▼▼▼
    const dataUrl =
      "https://dcctec.sharepoint.com/sites/SWCHPProjects-Drawings/Shared%20Documents/PublicPages/drawings.json";
    // ▲▲▲-----------------------------------------------------▲▲▲

    function getQueryParam(name) {
      const params = new URLSearchParams(window.location.search);
      return params.get(name);
    }

    function setStatus(type, message) {
      const el = document.getElementById("status");
      el.className = "status " + (type || "");
      el.textContent = message || "";
    }

    function setSubtitle(message) {
      document.getElementById("subtitle").textContent = message || "";
    }

    function setDebug(message) {
      document.getElementById("debug").textContent = message || "";
    }

    function renderRecord(record) {
      const tbody = document.getElementById("info-body");
      tbody.innerHTML = "";
      const table = document.getElementById("info-table");
      table.style.display = "table";

      const preferredOrder = [
        "DrawingNo", "Title", "Rev", "Status", "Current",
        "ApprovedDate", "RevisionNotes", "VerifyUrl",
        "NewKey", "Key", "DocNo"
      ];
      const added = new Set();

      function addRow(label, value) {
        if (value === undefined || value === null || value === "") return;
        const tr = document.createElement("tr");
        const th = document.createElement("th");
        const td = document.createElement("td");
        th.textContent = label;

        if (typeof value === "string" && /^https?:\/\//i.test(value)) {
          const a = document.createElement("a");
          a.href = value;
          a.target = "_blank";
          a.rel = "noopener";
          a.textContent = value;
          td.appendChild(a);
        } else {
          td.textContent = value;
        }
        tr.appendChild(th);
        tr.appendChild(td);
        tbody.appendChild(tr);
      }

      for (const key of preferredOrder) {
        if (Object.prototype.hasOwnProperty.call(record, key)) {
          addRow(key, record[key]);
          added.add(key);
        }
      }

      for (const key of Object.keys(record)) {
        if (added.has(key)) continue;
        addRow(key, record[key]);
      }
    }

    async function init() {
      const doc = getQueryParam("doc");

      if (!doc) {
        setSubtitle("문서번호(doc) 파라미터가 없습니다.");
        setStatus(
          "warn",
          "URL에 ?doc=문서번호 형식의 파라미터가 필요합니다. QR 코드 생성 시 doc 값을 포함하도록 설정해 주세요."
        );
        return;
      }

      setSubtitle("도면 정보를 불러오는 중입니다…");
      setStatus("", "");

      try {
        const res = await fetch(dataUrl, { cache: "no-cache" });
        if (!res.ok) {
          throw new Error("drawings.json 응답 코드: " + res.status);
        }

        const data = await res.json();
        if (!Array.isArray(data)) {
          throw new Error("drawings.json 형식이 배열이 아닙니다.");
        }

        const record = data.find(row =>
          String(row.Key) === doc ||
          String(row.NewKey) === doc ||
          String(row.DrawingNo) === doc ||
          String(row.DocNo) === doc
        );

        if (!record) {
          setSubtitle("도면을 찾을 수 없습니다.");
          setStatus(
            "warn",
            "drawings.json에서 doc 값 '" + doc + "' 에 해당하는 도면을 찾지 못했습니다."
          );
          setDebug("doc 파라미터: " + doc);
          return;
        }

        setSubtitle("도면 정보를 불러왔습니다.");
        setStatus("ok", "정상적으로 도면 정보를 조회했습니다.");
        renderRecord(record);
        setDebug("doc 파라미터: " + doc);
      } catch (err) {
        console.error(err);
        setSubtitle("도면 정보를 가져오는 중 오류가 발생했습니다.");
        setStatus("err", "오류: " + err.message);
        setDebug("dataUrl: " + dataUrl);
      }
    }

    document.addEventListener("DOMContentLoaded", init);
  </script>
</body>
</html>
