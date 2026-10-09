#!/bin/bash
# ติดตั้ง / ซ่อม โปรแกรมตัดคลิป AI บน Mac — ดับเบิลคลิกไฟล์นี้ใน Finder (รันซ้ำได้เรื่อย ๆ ของที่มีแล้วจะข้าม)
# ถ้าดับเบิลคลิกแล้วขึ้นว่า "เปิดไม่ได้เพราะมาจากผู้พัฒนาที่ไม่รู้จัก" → คลิกขวาที่ไฟล์ → เปิด (Open) → เปิด
#
# ทำอะไรบ้าง:
#  1) ตรวจ python3 + git ของเครื่อง (/usr/bin/python3) — ไม่มี → เปิดหน้าต่างติดตั้ง Command Line Tools ของ Apple ให้
#  2) ตรวจ ffmpeg — ไม่มี → บอกวิธีติดตั้ง (ไม่โหลดโปรแกรมจากเว็บมาให้เอง)
#  3) ดึงโปรแกรมจาก GitHub สาย stable ไว้ที่ ~/CutAI (แบบเดียวกับเครื่อง Windows)
#  4) ติดตั้งไลบรารี Python (pip --user)  5) ตรวจเครื่องมือของโปรแกรม
#  6) สร้างไอคอน "ตัดคลิป AI" บน Desktop  7) เปิดโปรแกรม
# หลังจากนี้ทุกครั้งที่เปิดโปรแกรม จะเช็ครุ่นใหม่แล้วอัปเดตให้เอง (อัปเดตแล้วเปิดไม่ขึ้น = ถอยกลับรุ่นเดิมเอง)
#
# ทดสอบตัวติดตั้งโดยไม่แตะของจริง: CUTAI_REPO=<repo ทดสอบ> CUTAI_DEST=<โฟลเดอร์ชั่วคราว>/CutAI
#   CUTAI_DESKTOP=<โฟลเดอร์ชั่วคราว> CUTAI_TEST=1 (ข้าม pip/ตรวจเครื่องมือ + ไม่เปิดโปรแกรม)

REPO="${CUTAI_REPO:-https://github.com/sahaphakhun/cut-clip-ai.git}"
BRANCH="stable"
DEST="${CUTAI_DEST:-$HOME/CutAI}"
DESK="${CUTAI_DESKTOP:-$HOME/Desktop}"
PY=/usr/bin/python3                       # python ของ Apple — ตัวเดียวกับที่ไอคอนบน Desktop ใช้เปิดโปรแกรม
# ติดตั้งแบบลูกค้า: ระบบขายใส่ 2 ค่านี้ให้ตอนลูกค้าดาวน์โหลดตัวติดตั้ง (ระบบขาย/README.md) — ว่าง = ติดตั้งแบบเจ้าของจาก GitHub
CUTAI_SERVER="https://script.google.com/macros/s/AKfycbx_UXwvru_VdhzTwgCq0w5CE_eRKxj69EZapGD97R1_ypurfpgY1r0zTb16HHKXlbalDQ/exec"
CUTAI_KEY=""
CUSTOMER=""
if [ -n "$CUTAI_SERVER" ]; then CUSTOMER=1; fi   # มี server แต่คีย์ว่าง = ตัวติดตั้งสาธารณะ (manifest_public)

STEP=0                                    # ขั้นที่กำลังทำ (จาก say "N/7 …") — ใช้บอกลูกค้าว่าล้มที่ขั้นไหน
STEP_TITLE=""
say()  {
    case "$1" in
        [1-7]/7\ *) STEP="${1%%/*}"; STEP_TITLE="${1#*/7 }" ;;
    esac
    printf '\n\033[1;36m== %s ==\033[0m\n' "$1"
}
ok()   { printf '  \033[32m[OK]\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m[!]\033[0m  %s\n' "$1"; }
bye()  { printf '\n'; read -r -p "กด Enter เพื่อปิดหน้าต่างนี้ " _; exit "${1:-0}"; }

# วิธีแก้แยกตามขั้น 1-7 (ภาษาคนทั่วไป) — ขั้นที่ไม่รู้ = คำแนะนำทั่วไป
step_advice() {
    case "$1" in
    1) echo "   - ติดตั้ง Command Line Tools ของ Apple (หน้าต่างจะเด้งให้กด \"ติดตั้ง\") แล้วดับเบิลคลิกไฟล์ติดตั้งนี้อีกครั้ง" ;;
    2) echo "   - ติดตั้ง ffmpeg ตามวิธีที่แสดงในขั้นที่ 2 แล้วดับเบิลคลิกไฟล์ติดตั้งนี้อีกครั้ง" ;;
    3) echo "   - ดาวน์โหลดโปรแกรมไม่สำเร็จ ส่วนใหญ่เป็นเพราะเน็ตหลุด/VPN/ไฟร์วอลล์/แอนตี้ไวรัสบล็อก ลองปิดตัวบล็อกชั่วคราวแล้วรันไฟล์นี้ใหม่"
       echo "   - เช็คว่าดิสก์ Mac ยังมีที่ว่างพอ (อย่างน้อย 10 GB) และเปิดเว็บทั่วไปได้ตามปกติ" ;;
    4) echo "   - ติดตั้งส่วนประกอบของโปรแกรมไม่สำเร็จ ส่วนใหญ่เน็ตหลุดกลางทาง ให้รันไฟล์ติดตั้งนี้ใหม่"
       echo "   - ถ้าใช้เน็ตบริษัท/โรงเรียน ลองใช้ฮอตสปอตมือถือแทน" ;;
    5) echo "   - รันไฟล์ติดตั้งนี้อีกครั้ง (ใช้เวลาไม่นาน) ถ้ายังไม่ผ่านให้ส่งรายงานด้านล่าง" ;;
    6) echo "   - สร้างไอคอนบน Desktop ไม่สำเร็จ แต่โปรแกรมลงเสร็จแล้ว เปิดได้จากโฟลเดอร์ CutAI ในโฟลเดอร์ผู้ใช้" ;;
    7) echo "   - ลองดับเบิลคลิกไอคอน 'ตัดคลิป AI' บน Desktop อีกครั้ง หรือรีสตาร์ตเครื่องแล้วเปิดใหม่" ;;
    *) echo "   - ลองรันไฟล์ติดตั้งนี้ใหม่อีกครั้ง (ของที่ลงไปแล้วจะข้าม) ถ้ายังไม่ได้ให้ส่งรายงานด้านล่าง หรือส่งไฟล์ log ให้แอดมินทางไลน์" ;;
    esac
}

# รายงานอาการ: สร้างข้อความ (ลบคีย์/ลิงก์ระบบขาย/อีเมล/ชื่อผู้ใช้/ชื่อเครื่องออก) แล้วส่งเข้าฟีดแบ็กระบบขาย (action install_report · ไม่ส่งคีย์)
# python ที่ฝังตรงนี้อ่านจากตัวแปรเพื่อให้ stdin ว่างไว้ใช้ · ใช้ได้ 2 โหมด: build (พิมพ์ข้อความรายงาน) / send (ส่ง stdin ไประบบขาย)
read -r -d '' REPORT_PY <<'RPTEOF'
import json, os, platform, re, shutil, socket, subprocess, sys, urllib.request
mode = sys.argv[1]
E = os.environ

def sanitize(t):
    for s in (E.get("CUTAI_KEY", ""), E.get("CUTAI_SERVER", "")):
        if len(s) >= 4:
            t = t.replace(s, "***")
    t = re.sub(r"(?i)\b(key|token|order|admin|code)=[^&\s\"']+", r"\1=***", t)
    t = re.sub(r"(?i)https?://script\.google(usercontent)?\.com/\S+", "<ลิงก์ระบบขาย>", t)
    t = re.sub(r"[A-Za-z0-9._%+\-]+@[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)+", "<อีเมล>", t)
    for v, rep in ((os.path.expanduser("~"), "<โฟลเดอร์ผู้ใช้>"), (E.get("USER", ""), "<ผู้ใช้>"), (socket.gethostname(), "<เครื่อง>")):
        if len(v) >= 3:
            t = re.sub(re.escape(v), rep, t, flags=re.I)
    return t

if mode == "build":
    def run(*a):
        try:
            return subprocess.run(list(a), capture_output=True, timeout=10).stdout.decode("utf-8", "replace").strip()
        except Exception:
            return "อ่านไม่ได้"
    try:
        free = "%d GB" % (shutil.disk_usage(os.path.expanduser("~")).free // 2 ** 30)
    except Exception:
        free = "อ่านไม่ได้"
    tail = ""
    try:
        with open("/tmp/cutai_ติดตั้ง_error.txt", encoding="utf-8") as f:
            tail = "".join(f.readlines()[-25:])
    except Exception:
        pass
    text = "[ตัวติดตั้ง Mac ล้ม] ขั้น %s/7 %s\nสาเหตุ: %s\n\nmacOS: %s\nชิป: %s\nPython: %s\nดิสก์ว่าง: %s" % (
        E.get("STEP", "0"), E.get("STEP_TITLE", ""), E.get("REASON", ""), run("sw_vers", "-productVersion"),
        platform.machine(), platform.python_version(), free)
    if tail:
        text += "\n\n--- ท้ายไฟล์ log ---\n" + tail
    print(sanitize(text))
else:
    server = E.get("CUTAI_SERVER", "")
    if not server:
        print("ERR ตัวติดตั้งนี้ไม่มีช่องส่งรายงาน")
        sys.exit(1)
    body = json.dumps({"action": "install_report", "os": "mac", "step": "%s/7" % E.get("STEP", "0"),
                       "text": sanitize(sys.stdin.read()), "contact": sanitize(E.get("CONTACT", "")),
                       "cid": "ins-" + os.urandom(6).hex()}, ensure_ascii=False).encode("utf-8")
    try:
        req = urllib.request.Request(server, data=body, headers={"Content-Type": "text/plain;charset=utf-8", "User-Agent": "CutAI-installer"})
        with urllib.request.urlopen(req, timeout=60) as r:
            d = json.loads(r.read(1 << 20).decode("utf-8", "replace"))
        if isinstance(d, dict) and d.get("ok"):
            print("OK %s" % d.get("id", ""))
        else:
            print("ERR %s" % ((d or {}).get("error") or "ระบบขายไม่รับรายงาน"))
            sys.exit(1)
    except SystemExit:
        raise
    except Exception as e:
        print("ERR %s" % type(e).__name__)
        sys.exit(1)
RPTEOF

# ติดตั้งล้ม: บอกขั้น + สาเหตุ + วิธีแก้ → ถามว่าจะส่งรายงานไหม (CUTAI_NO_REPORT=1 / CUTAI_TEST=1 / ไม่ได้เปิดจากหน้าต่าง = ไม่ถาม)
fail() {
    printf '\n\033[31m[X] ติดตั้งไม่สำเร็จ — ล้มที่ขั้น %s/7 : %s\033[0m\n' "$STEP" "$STEP_TITLE"
    printf '    สาเหตุ: %s\n\n  วิธีแก้:\n' "$1"
    step_advice "$STEP"
    printf '  (ถ้ามีไฟล์ log จะอยู่ที่ /tmp/cutai_ติดตั้ง_error.txt — ส่งให้แอดมินทางไลน์ได้)\n'
    if [ -z "$CUTAI_NO_REPORT" ] && [ -z "$CUTAI_TEST" ] && [ -t 0 ]; then
        RPT="$(REASON="$1" STEP="$STEP" STEP_TITLE="$STEP_TITLE" "$PY" -c "$REPORT_PY" build 2>/dev/null)"
        if [ -n "$RPT" ]; then
            printf '\n  ส่งรายงานอาการให้ทีมงานช่วยดู? ข้อความที่จะส่งมีแค่นี้ (ไม่มีคีย์ ชื่อ หรือรหัสผ่านของคุณ):\n'
            printf '  ------------------------------------------------\n%s\n  ------------------------------------------------\n' "$RPT"
            read -r -p "  พิมพ์ Y แล้วกด Enter เพื่อส่ง (หรือกด Enter เฉย ๆ เพื่อข้าม) " ANS
            case "$ANS" in
            [yY]*)
                read -r -p "  อยากให้ติดต่อกลับทางไหน? พิมพ์ไลน์ไอดีหรือเบอร์โทร (ไม่พิมพ์ก็ได้ กด Enter ข้าม) " CONTACT
                RES="$(printf '%s' "$RPT" | STEP="$STEP" CONTACT="$CONTACT" "$PY" -c "$REPORT_PY" send 2>/dev/null)"
                case "$RES" in
                OK*) printf '  \033[32m[OK]\033[0m ส่งรายงานให้ทีมงานแล้ว (เลขอ้างอิง %s) — ทีมงานจะตอบกลับทางช่องทางที่คุณให้ไว้\n' "${RES#OK }" ;;
                *)   warn "ส่งรายงานไม่สำเร็จ (${RES#ERR }) — ส่งไฟล์ log ให้แอดมินทางไลน์แทนได้" ;;
                esac ;;
            esac
        fi
    fi
    bye 1
}

# ✅ ติดตั้งเสร็จจริง → บอกระบบขายครั้งเดียว (action install_done = นับ "ติดตั้งสำเร็จ" ในแดชบอร์ด)
# ไม่ส่งคีย์/ชื่อ/ข้อมูลเครื่อง · ยิงไม่ติด/ไม่มี curl ก็คืน 0 เสมอ ไม่ทำให้การติดตั้งล้ม (CUTAI_CURL = ทดสอบเท่านั้น)
ins_done() {
    [ -n "$CUTAI_SERVER" ] || return 0
    case "$CUTAI_SERVER" in *\?*) _sep="&" ;; *) _sep="?" ;; esac
    "${CUTAI_CURL:-/usr/bin/curl}" -s -m 15 -o /dev/null "${CUTAI_SERVER}${_sep}action=install_done&os=mac" >/dev/null 2>&1 || true
    return 0
}

echo "โปรแกรมตัดคลิป AI — ตัวติดตั้งสำหรับ Mac"

# ───────── 1) python3 + git (มากับ Command Line Tools ของ Apple) ─────────
say "1/7 ตรวจ python3 และ git ของเครื่อง"
if ! xcode-select -p >/dev/null 2>&1 || ! "$PY" -c 'import sys' >/dev/null 2>&1; then
    xcode-select --install >/dev/null 2>&1
    echo "  เครื่องนี้ยังไม่มี Command Line Tools (ชุดเครื่องมือฟรีของ Apple ที่มี python3 และ git)"
    echo "  → จะมีหน้าต่างของ Apple เด้งขึ้นมา ให้กดปุ่ม \"ติดตั้ง\" (Install) แล้วรอจนเสร็จ (ประมาณ 5-15 นาที)"
    echo "  → ติดตั้งเสร็จแล้ว ดับเบิลคลิกไฟล์ติดตั้งนี้อีกครั้ง"
    bye 1
fi
ok "python3 $("$PY" -c 'import sys; print("%d.%d.%d" % sys.version_info[:3])') ($PY)"
GIT="$(command -v git || echo /usr/bin/git)"
if [ -z "$CUSTOMER" ]; then                # ลูกค้าไม่ใช้ git (โหลดโปรแกรมจากระบบขาย)
    "$GIT" --version >/dev/null 2>&1 || fail "ใช้ git ไม่ได้ — เปิด Terminal พิมพ์ xcode-select --install กดติดตั้ง แล้วรันไฟล์นี้ใหม่"
    ok "$("$GIT" --version)"
fi

# ───────── 2) ffmpeg (ไม่โหลดไฟล์โปรแกรมจากเว็บให้เอง — บอกวิธีให้ผู้ใช้ทำ) ─────────
say "2/7 ตรวจ ffmpeg (ตัวตัดต่อวิดีโอ)"
find_tool() {
    for c in "$HOME/bin/$1" /opt/homebrew/bin/"$1" /usr/local/bin/"$1" "$(command -v "$1" 2>/dev/null)"; do
        if [ -n "$c" ] && [ -x "$c" ]; then echo "$c"; return 0; fi
    done
    return 1
}
FF="$(find_tool ffmpeg)"
FFP="$(find_tool ffprobe)"
if [ -n "$FF" ] && [ -n "$FFP" ]; then
    ok "ffmpeg: $FF"
else
    if [ "$(uname -m)" = "arm64" ]; then CHIP="Apple Silicon (arm64)"; else CHIP="Intel (x86_64)"; fi
    if [ -n "$CUSTOMER" ]; then
        warn "ยังไม่มี ffmpeg / ffprobe — จะโหลดมาติดตั้งให้เองหลังดึงโปรแกรม (ขั้นที่ 3)"
    else
    warn "ยังไม่มี ffmpeg / ffprobe — ตัดคลิปไม่ได้จนกว่าจะติดตั้ง (ขั้นอื่นทำต่อให้ก่อน)"
    cat <<EOF
     วิธีที่ 1 (ง่ายสุด ถ้าเครื่องมี Homebrew): เปิด Terminal พิมพ์
         brew install ffmpeg
     วิธีที่ 2 (ไม่มี Homebrew): โหลด ffmpeg และ ffprobe สำหรับ macOS รุ่นชิป $CHIP
         จาก https://www.osxexperts.net แตกไฟล์ แล้ววางทั้ง 2 ไฟล์ไว้ในโฟลเดอร์ $HOME/bin
         (ไม่มีโฟลเดอร์ bin ให้สร้างใหม่) จากนั้นเปิด Terminal พิมพ์ทีละบรรทัด:
         chmod +x ~/bin/ffmpeg ~/bin/ffprobe
         xattr -d com.apple.quarantine ~/bin/ffmpeg ~/bin/ffprobe
     ต้องเป็น ffmpeg ที่มี libass (ใช้ทำซับ) · ติดตั้งเสร็จแล้วรันไฟล์นี้อีกครั้ง
EOF
    fi
fi

# ───────── 3) ดึงโปรแกรม ─────────
OLD=""
MANIFEST_URL=""
if [ -n "$CUSTOMER" ]; then
    say "3/7 ดาวน์โหลดโปรแกรมรุ่นล่าสุด ไว้ที่ $DEST"
    [ -d "$DEST/.git" ] && fail "เครื่องนี้มีโปรแกรมแบบเจ้าของ (GitHub) อยู่แล้วที่ $DEST — ไม่ติดตั้งทับ"
    # โหลด zip ตามไฟล์บอกรุ่นของระบบขาย → ตรวจ sha256 → แตกไฟล์ (คงสิทธิ์ไฟล์รันได้) → เก็บรุ่นเดิมไว้ 1 ชุด
    MANIFEST_URL="$("$PY" - "$CUTAI_SERVER" "$CUTAI_KEY" "$DEST" <<'PYEOF'
import hashlib, json, os, pathlib, shutil, socket, ssl, subprocess, sys, tempfile, time, urllib.error, urllib.parse, urllib.request, zipfile

LOG_PATH = "/tmp/cutai_ติดตั้ง_error.txt"

def say(m):
    print("  " + m, file=sys.stderr, flush=True)

def log_write(path, message):
    try:
        with open(path, "a", encoding="utf-8") as f:
            f.write("[%s] %s\n" % (time.strftime("%Y-%m-%d %H:%M:%S"), message))
    except Exception:
        pass

# แยกสาเหตุจาก exception ให้อ่านรู้เรื่อง (เทียบเท่า Get-CutAIErrorReason ใน install.ps1 ฝั่ง Windows)
def classify_error(e):
    if isinstance(e, urllib.error.HTTPError):
        return "เซิร์ฟเวอร์ตอบรหัส HTTP %s" % e.code
    if isinstance(e, urllib.error.URLError):
        r = e.reason
        if isinstance(r, ssl.SSLError):
            return "ปัญหา TLS/SSL (%s)" % r
        if isinstance(r, socket.gaierror):
            return "หา DNS ของระบบขายไม่เจอ (%s)" % r
        if isinstance(r, (socket.timeout, TimeoutError)):
            return "เชื่อมต่อหมดเวลา (timeout)"
        if isinstance(r, ConnectionRefusedError):
            return "เซิร์ฟเวอร์ปฏิเสธการเชื่อมต่อ (ConnectionRefusedError)"
        return "%s: %s" % (type(r).__name__, r)
    if isinstance(e, (socket.timeout, TimeoutError)):
        return "เชื่อมต่อหมดเวลา (timeout)"
    if isinstance(e, ConnectionRefusedError):
        return "เซิร์ฟเวอร์ปฏิเสธการเชื่อมต่อ (ConnectionRefusedError)"
    return "%s: %s" % (type(e).__name__, e)

# urllib บน macOS (python ของ Apple ที่ /usr/bin/python3) อ่าน proxy ของระบบเองอยู่แล้ว —
# ProxyHandler เริ่มต้นเรียก getproxies() ซึ่งบน darwin ใช้ _scproxy อ่านทั้ง System Settings และ env http_proxy/https_proxy
# จึงไม่ต้องสร้าง opener/proxy เพิ่มเอง
def fetch_json_urlopen(url, timeout=90):
    req = urllib.request.Request(url, headers={"User-Agent": "CutAI-installer"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode("utf-8"))

def fetch_json_curl(url, timeout=30):
    try:
        out = subprocess.run(["/usr/bin/curl", "-s", "-m", str(timeout), url],
                              capture_output=True, timeout=timeout + 10)
    except Exception as e:
        raise RuntimeError("เรียก curl สำรองไม่สำเร็จ: %s" % e)
    if out.returncode != 0 or not out.stdout:
        raise RuntimeError("curl สำรองคืนรหัส %s หรือไม่มีผลลัพธ์" % out.returncode)
    return json.loads(out.stdout.decode("utf-8"))

# ลอง urlopen 3 ครั้งก่อน ค่อยลองสำรองด้วย curl (มีมากับ Mac ทุกเครื่อง) — เก็บ log ทุกครั้งที่ลองแล้วไม่สำเร็จ
def fetch_manifest(url, log_path=LOG_PATH, retry_delays=(3, 6, 10), urlopen_fn=fetch_json_urlopen, curl_fn=fetch_json_curl):
    tries = 3
    last_reason = None
    for i in range(1, tries + 1):
        try:
            return urlopen_fn(url)
        except Exception as e:
            last_reason = classify_error(e)
            log_write(log_path, "เรียก manifest ครั้งที่ %d/%d ล้มเหลว: %s | %r" % (i, tries, last_reason, e))
            if i <= len(retry_delays):
                time.sleep(retry_delays[i - 1])
    try:
        result = curl_fn(url)
        log_write(log_path, "ลอง curl สำรองสำเร็จ")
        return result
    except Exception as e:
        curl_reason = classify_error(e)
        log_write(log_path, "curl สำรองล้มเหลว: %s | %r" % (curl_reason, e))
        raise RuntimeError(last_reason or curl_reason)

# CUTAI_INSTALL_TEST_FUNCS=1 ให้ tests/test_install_mac.py exec โค้ดนี้แล้วเรียกฟังก์ชันข้างบนตรง ๆ
# โดยไม่รันขั้นตอนติดตั้งจริง — ตัวแปรนี้จะไม่ถูกตั้งบนเครื่องลูกค้า จึงไม่กระทบของจริง
if not os.environ.get("CUTAI_INSTALL_TEST_FUNCS"):
    server, key, dest = sys.argv[1], sys.argv[2], pathlib.Path(sys.argv[3])
    sep = "&" if "?" in server else "?"
    # คีย์ว่าง = ตัวติดตั้งสาธารณะ (ลิงก์ตรงบนหน้าขาย) → manifest_public (ไม่ใช้คีย์)
    q = {"action": "manifest", "key": key, "m": "installer"} if key else {"action": "manifest_public", "m": "installer"}
    murl = server + sep + urllib.parse.urlencode(q)
    try:
        man = fetch_manifest(murl)
    except Exception as e:
        say("ติดต่อระบบขายไม่ได้ — สาเหตุ: %s (ลองแล้ว 3 ครั้ง + curl สำรอง)" % e)
        say("แนะนำ: ลองรันไฟล์นี้ใหม่ / ปิด VPN หรือโปรแกรมแอนตี้ไวรัสชั่วคราวแล้วรันไฟล์นี้ใหม่ / ส่งรหัส error ด้านบนหรือไฟล์ log ที่ %s ให้แอดมินทางไลน์" % LOG_PATH)
        sys.exit(1)
    if not man.get("url") or not man.get("sha256"):
        say("ดาวน์โหลดโปรแกรมไม่ได้: " + str(man.get("error") or "ไม่พบไฟล์โปรแกรม"))
        sys.exit(1)
    say("กำลังดาวน์โหลดรุ่น %s (%.1f MB)…" % (man.get("version_count"), float(man.get("size") or 0) / 1e6))
    tmpd = pathlib.Path(tempfile.mkdtemp(prefix="cutai_"))
    zp, h = tmpd / "app.zip", hashlib.sha256()
    try:
        with urllib.request.urlopen(urllib.request.Request(man["url"], headers={"User-Agent": "CutAI-installer"}), timeout=120) as r, \
                open(str(zp), "wb") as f:
            while True:
                b = r.read(1 << 20)
                if not b:
                    break
                f.write(b)
                h.update(b)
    except Exception as e:
        say("ดาวน์โหลดไม่สำเร็จ (%s)" % type(e).__name__)
        sys.exit(1)
    if h.hexdigest() != str(man["sha256"]).lower():
        say("ไฟล์โปรแกรมที่ดาวน์โหลดไม่ครบ/เสีย (ตรวจ sha256 ไม่ผ่าน)")
        sys.exit(1)
    say("ดาวน์โหลดครบ ตรวจความถูกต้องแล้ว")
    out = (tmpd / "x").resolve()
    with zipfile.ZipFile(str(zp)) as z:
        for info in z.infolist():
            target = (out / info.filename).resolve()
            if target != out and not str(target).startswith(str(out) + os.sep):
                say("แพ็กเกจมีชื่อไฟล์ผิดปกติ — ไม่ติดตั้ง")
                sys.exit(1)
            z.extract(info, str(out))
            mode = (info.external_attr >> 16) & 0o777
            if mode and not info.is_dir():
                os.chmod(str(target), mode)
    src = out / "CutAI"
    if not (src / "launcher.py").is_file():
        say("แพ็กเกจโปรแกรมไม่ครบ")
        sys.exit(1)
    if dest.exists():
        prev = dest.with_name(dest.name + "_ก่อนหน้า")
        if prev.exists():
            shutil.rmtree(str(prev), ignore_errors=True)
        dest.rename(prev)
    shutil.move(str(src), str(dest))
    shutil.rmtree(str(tmpd), ignore_errors=True)
    say("โปรแกรมรุ่น %s อยู่ที่ %s" % (man.get("version_count"), dest))
    print(murl)
PYEOF
)" || fail "ดาวน์โหลดโปรแกรมไม่สำเร็จ — ดูข้อความด้านบน แล้วรันไฟล์นี้ใหม่"
    ok "ดาวน์โหลดโปรแกรมแล้ว"
else
say "3/7 ดึงโปรแกรม (สาย $BRANCH) ไว้ที่ $DEST"
if [ -d "$DEST/.git" ]; then
    "$GIT" -C "$DEST" fetch origin "$BRANCH" || fail "ดึงโปรแกรมไม่สำเร็จ (เช็คอินเทอร์เน็ต / สิทธิ์ GitHub)"
    "$GIT" -C "$DEST" checkout -q -f -B "$BRANCH" "origin/$BRANCH" || fail "เปลี่ยนไปสาย $BRANCH ไม่สำเร็จ"
    "$GIT" -C "$DEST" reset -q --hard "origin/$BRANCH" || fail "อัปเดตโปรแกรมไม่สำเร็จ"
else
    if [ -e "$DEST" ]; then
        OLD="${DEST}_old_$(date +%Y%m%d_%H%M%S)"
        mv "$DEST" "$OLD" || fail "ย้ายโฟลเดอร์ $DEST เดิมออกไม่ได้"
        warn "มีโฟลเดอร์ $DEST เดิมที่ไม่ได้ติดตั้งจาก GitHub — ย้ายไปไว้ที่ $OLD (ไม่ได้ลบ)"
    fi
    echo "  ถ้ามีคำถาม Username / Password ของ GitHub — ให้เจ้าของโปรแกรมเป็นคนกรอกเอง"
    echo "  (ช่อง Password ต้องใส่ token ของ GitHub ไม่ใช่รหัสผ่านปกติ)"
    "$GIT" clone --branch "$BRANCH" "$REPO" "$DEST" || fail "ดึงโปรแกรมไม่สำเร็จ (เช็คอินเทอร์เน็ต / สิทธิ์ GitHub)"
    # โฟลเดอร์เก่ามีข้อมูลผู้ใช้ (คีย์/ตั้งค่า/ประวัติงาน) → ย้ายมาใช้ต่อ ไม่ให้คีย์หายเงียบ ๆ
    if [ -n "$OLD" ] && [ -d "$OLD/งาน" ] && [ ! -e "$DEST/งาน" ]; then
        mv "$OLD/งาน" "$DEST/งาน" && ok "ย้ายข้อมูลเดิม (คีย์ / ตั้งค่า / งาน) จากโฟลเดอร์เก่ามาใช้ต่อแล้ว"
    fi
fi
ok "โปรแกรมอยู่ที่ $DEST — รุ่น $("$GIT" -C "$DEST" rev-list --count HEAD) ($("$GIT" -C "$DEST" log -1 --format='%h %s'))"
fi
[ -f "$DEST/thaitext" ] && chmod +x "$DEST/thaitext"

# ───────── 3b) ffmpeg ของ Mac: ลูกค้าไม่มี → โหลดจากระบบขายมาติดตั้งเอง (macffmpeg.py ในโปรแกรมที่เพิ่งดึงมา) ─────────
if [ -n "$CUSTOMER" ] && { [ -z "$FF" ] || [ -z "$FFP" ]; } && [ -f "$DEST/macffmpeg.py" ]; then
    say "3/7 ติดตั้ง ffmpeg (ตัวตัดต่อวิดีโอ) ให้เอง"
    if "$PY" "$DEST/macffmpeg.py" "$MANIFEST_URL"; then
        FF="$(find_tool ffmpeg)"; FFP="$(find_tool ffprobe)"
        ok "ffmpeg พร้อมใช้: $FF"
    else
        warn "ติดตั้ง ffmpeg ให้เองไม่สำเร็จ — เปิดโปรแกรมแล้วกด 🔧 ซ่อมให้อัตโนมัติ หรือทักไลน์ผู้ขาย"
    fi
fi

# ───────── 4) ไลบรารี Python ─────────
say "4/7 ติดตั้งไลบรารี Python (ครั้งแรกใช้เวลาหลายนาที)"
if [ -n "$CUTAI_TEST" ]; then
    warn "โหมดทดสอบ: ข้าม pip"
elif "$PY" -m pip install --user --disable-pip-version-check -r "$DEST/requirements.txt"; then
    ok "ไลบรารีครบ"
else
    warn "ติดตั้งไลบรารีบางตัวไม่สำเร็จ — หน้าโปรแกรมจะบอกว่าขาดอะไร (กดปุ่ม 🔧 ซ่อมให้อัตโนมัติ ได้)"
fi

# ───────── 5) ตรวจเครื่องมือ ─────────
say "5/7 ตรวจเครื่องมือของโปรแกรม"
if [ -n "$CUTAI_TEST" ]; then
    warn "โหมดทดสอบ: ข้ามการตรวจเครื่องมือ"
else
    ( cd "$DEST" && PYTHONIOENCODING=utf-8 "$PY" config.py ) || warn "ตรวจเครื่องมือไม่สำเร็จ — ดูรายละเอียดในหน้าโปรแกรม"
fi

# จดคีย์ + ช่องทางอัปเดต (ลูกค้า) → โปรแกรมเปิดใช้งานเองตอนเปิดครั้งแรก (licensing.py) · โฟลเดอร์ข้อมูลกติกาเดียวกับ plat.data_dir
if [ -n "$CUSTOMER" ]; then
    if [ -n "$CUTAI_DATA" ]; then DATA="$CUTAI_DATA"
    elif [ -d "$DEST/งาน" ]; then DATA="$DEST/งาน"
    else DATA="$HOME/Library/Application Support/CutAI/งาน"; fi
    mkdir -p "$DATA" || fail "สร้างโฟลเดอร์ข้อมูล $DATA ไม่ได้"
    "$PY" - "$DATA" "$CUTAI_KEY" "$MANIFEST_URL" <<'PYEOF' || fail "จดคีย์ไม่สำเร็จ"
import json, os, pathlib, sys
d = pathlib.Path(sys.argv[1])
lic = d / "ใบอนุญาต.json"
if sys.argv[2]:                                  # ตัวติดตั้งสาธารณะไม่มีคีย์ — ไม่เขียนไฟล์ใบอนุญาตว่างทับ
    lic.write_text(json.dumps({"key": sys.argv[2]}), encoding="utf-8")
    os.chmod(str(lic), 0o600)
(d / "update_channel.json").write_text(json.dumps({"channel": "zip", "manifest_url": sys.argv[3]}), encoding="utf-8")
PYEOF
    if [ -n "$CUTAI_KEY" ]; then ok "จดคีย์ไว้แล้ว — โปรแกรมจะเปิดใช้งานเองตอนเปิดครั้งแรก (ต้องต่ออินเทอร์เน็ต)"
    else ok "ตั้งช่องทางอัปเดตแล้ว — เปิดโปรแกรมแล้วขอคีย์ใช้ฟรีได้เลย"; fi
fi

# ───────── 6) ไอคอนบน Desktop ─────────
say "6/7 สร้างไอคอนบน Desktop"
mkdir -p "$DESK"
ICON="$DESK/ตัดคลิป AI.command"
cat > "$ICON" <<EOF
#!/bin/bash
# เปิดโปรแกรมตัดคลิป AI (ไฟล์นี้สร้างโดยตัวติดตั้ง) — เช็ครุ่นใหม่และอัปเดตตัวเองทุกครั้งที่เปิด
exec /usr/bin/python3 "$DEST/launcher.py" "\$@"
EOF
chmod +x "$ICON" || fail "สร้างไอคอนบน Desktop ไม่ได้"
ok "ไอคอน 'ตัดคลิป AI' อยู่บน Desktop แล้ว (ดับเบิลคลิกเพื่อเปิดโปรแกรม)"

# ───────── 7) เปิดโปรแกรม ─────────
say "7/7 เปิดโปรแกรม"
if [ -n "$CUTAI_TEST" ]; then
    warn "โหมดทดสอบ: ไม่เปิดโปรแกรม"
else
    nohup "$PY" "$DEST/launcher.py" >/dev/null 2>&1 &     # nohup: ปิดหน้าต่างนี้แล้วตัวเปิดโปรแกรมไม่ตายตาม
    [ -n "$CUSTOMER" ] && ins_done                         # ครบ 7 ขั้นแล้วเท่านั้น · ยิงไม่ติดก็จบปกติ
fi
echo
echo "เสร็จแล้ว! หน้าโปรแกรมจะเปิดในเบราว์เซอร์ให้เอง"
echo "ครั้งแรก: ทำการ์ด 'ตั้งค่าครั้งแรก' บนหน้าแรก (ใส่คีย์ Google AI ฟรี)"
echo "ต่อไปเปิดจากไอคอน 'ตัดคลิป AI' บน Desktop — โปรแกรมจะอัปเดตตัวเองทุกครั้งที่เปิด"
[ -z "$FF" ] && warn "อย่าลืมติดตั้ง ffmpeg ตามขั้นที่ 2 ก่อนเริ่มตัดคลิป"
bye 0
