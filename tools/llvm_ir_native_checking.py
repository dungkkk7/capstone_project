#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check_native_ir.py — Kiểm tra mức độ "native" của LLVM IR sau khi de-lift
McSema/Remill (KHÔNG xét deobfuscate).

Nâng cấp:
  * Hiểu opaque pointer (ptr) và wrapper shims.
  * Phân loại hàm thành SHIM (wrapper), ARGIFIED (đã làm đẹp CC), và LIFTED (chưa argified).
  * Hạ cấp độ nghiêm trọng của GPR alias accesses trong .argified thành info (chỉ là boundary flushes).
  * Loại bỏ shim wrapper khỏi các active blocker counts để tránh báo cáo sai.
  * Chấm điểm theo Native Recovery Score (phần trăm hàm đã argified hoặc clean).
  * Hỗ trợ file .ll, thư mục (đệ quy), nhiều path, .bc.
"""

import sys
import os
import re
import io
import json
import shutil
import argparse
import subprocess
from collections import defaultdict

# ----------------------------------------------------------------------------- color
class C:
    def __init__(self, enabled):
        e = enabled
        self.B   = '\033[94m' if e else ''
        self.G   = '\033[92m' if e else ''
        self.Y   = '\033[93m' if e else ''
        self.R   = '\033[91m' if e else ''
        self.M   = '\033[95m' if e else ''
        self.CY  = '\033[96m' if e else ''
        self.GR  = '\033[90m' if e else ''
        self.BD  = '\033[1m'  if e else ''
        self.END = '\033[0m'  if e else ''

# ----------------------------------------------------------------------------- patterns
GP_REGS = r'(?:R[A-D]X|R[SD]I|R[BS]P|RIP|R8|R9|R1[0-5]|E[A-D]X|E[SD]I|[A-D][LHX]|[SD]IL|BPL|SPL)'
FLAG_REGS = r'(?:CF|PF|AF|ZF|SF|OF|DF|TF|IF|AC|NT|RF|VM|ID)'
VEC_REGS = r'(?:X|Y|Z)MM\d+|ST[0-7]|MM[0-7]|FS|GS|CS|SS|ES|DS'

PATTERNS = [
    # --- HARD: chặn native hoàn toàn ------------------------------------------
    ('state_types', re.compile(
        r'%(?:struct|union)\.(?:State|ArithFlags|GPR|Reg|X87Stack|MMX|Segments|'
        r'SegmentCaches|SegmentShadow|SegmentSelector|FPU|FpuFXSAVE|FPUStatusFlags|'
        r'FPUControlStatus|FPUStackElem|FPUAbridgedTagWord|AddressSpace|ArchState|'
        r'VectorReg|vec\d+_t|uint\d+v\d+_t|float80_t|anon(?:\.\d+)?)\b'),
        'hard', 'Kiểu State/Remill (struct mô hình CPU)'),
    ('memory_struct', re.compile(r'%struct\.Memory\b'),
        'hard', '%struct.Memory (mô hình memory của Remill)'),
    ('reg_state_global', re.compile(r'@__mcsema_reg_state\b'),
        'hard', 'Global register-file dùng chung @__mcsema_reg_state'),
    ('reg_flag_globals', re.compile(
        r'@(?:' + GP_REGS + r'|' + FLAG_REGS + r'|' + VEC_REGS + r')_\d+_[0-9a-fA-F]+\b'),
        'hard', 'Register/flag dạng GLOBAL ALIAS (@RAX_.._hex, @CF_.. ...)'),
    ('reg_alias_defs', re.compile(
        r'=\s*(?:private\s+|internal\s+|external\s+)*'
        r'(?:thread_local(?:\([^)]*\))?\s+)?alias\s+[^,]+,\s*getelementptr[^@]*@__mcsema_reg_state'),
        'hard', 'Định nghĩa alias trỏ vào @__mcsema_reg_state'),
    ('remill_intrinsics', re.compile(r'__remill_(?!(?:read|write)_memory_)[A-Za-z0-9_]+'),
        'hard', 'Intrinsic __remill_* (call/declare)'),
    ('mcsema_syms', re.compile(r'__mcsema_(?!reg_state\b)[A-Za-z0-9_]+'),
        'hard', 'Symbol __mcsema_*'),
    ('remill_metadata', re.compile(r'!remill\.[A-Za-z0-9_.]+'),
        'info', 'Metadata !remill.* (function.type, pc, ...)'),
    ('untethered_state_call', re.compile(
        r'(?:tail\s+)?call[^\n]*\(\s*ptr\s+@__mcsema_reg_state\b'),
        'hard', 'Call truyền thẳng @__mcsema_reg_state (state CHƯA thread qua tham số)'),
    # --- SOFT: dư lượng, gần native nhưng chưa sạch ---------------------------
    ('remill_memaccess', re.compile(r'__remill_(?:read|write)_memory_[A-Za-z0-9_]+'),
        'soft', 'Memory model OPAQUE (__remill_read/write_memory_*) — khó AA, nên recover-type'),
    ('flag_store', re.compile(
        r'store\s+i8\s+[^,]+,\s*ptr\s+@(?:' + FLAG_REGS + r')_'),
        'soft', 'EFLAGS residue: store vào flag global'),
    ('ctpop_parity', re.compile(r'@llvm\.ctpop\.i\d+'),
        'soft', 'Tính Parity-flag (llvm.ctpop) — đặc trưng EFLAGS lift'),
    ('inttoptr', re.compile(r'\binttoptr\b'),
        'soft', 'inttoptr (mô hình memory chưa recover type con trỏ)'),
    ('ptrtoint', re.compile(r'\bptrtoint\b'),
        'soft', 'ptrtoint'),
    ('lift_naming', re.compile(r'@(?:sub|seg|data)_[0-9a-fA-F]+\b'),
        'soft', 'Đặt tên kiểu lift (@sub_/@data_/@seg_) — cosmetic'),
    # --- INFO -----------------------------------------------------------------
    ('ext_thunks', re.compile(r'@ext_[0-9a-fA-F]+_[A-Za-z0-9_]+\b'),
        'info', 'Thunk ngoại vi McSema @ext_<addr>_<libcall>'),
    ('argified_calls', re.compile(r'call\s+[^@\n]*@[A-Za-z0-9_$.\-]+\.argified\b'),
        'info', 'Gọi trực tiếp hàm đã argified (native CC)'),
]

MARKERS = ('__remill', '__mcsema', '%struct.', '%union.', '!remill',
           'alias', 'inttoptr', 'ptrtoint', 'ctpop', 'getelementptr',
           '@sub_', '@seg_', '@data_', '@ext_', 'store i8', '@R', '@E',
           '@CF', '@PF', '@AF', '@ZF', '@SF', '@OF', '@DF', '@X', '@Y',
           '@Z', '@ST', '@MM', '@FS', '@GS', 'define', 'Memory', 'argified')

DEFINE_RE = re.compile(r'^\s*define\b.*?@(?P<name>[A-Za-z0-9_$.\-]+)\s*\(')
SIG_RE = re.compile(r'@[A-Za-z0-9_$.\-]+\s*\(\s*ptr\b[^,]*,\s*i64\b[^,]*,\s*ptr\b')
LIFTED_NAME_RE = re.compile(r'^(?:sub|callback|ext)_[0-9A-Fa-f]+')

# Các key đánh dấu "hàm này còn chạm register-state"
FUNC_DIRTY_KEYS = {'state_types', 'memory_struct', 'reg_state_global',
                   'reg_flag_globals', 'remill_intrinsics', 'mcsema_syms',
                   'remill_metadata', 'untethered_state_call', 'remill_memaccess',
                   'flag_store'}

# ----------------------------------------------------------------------------- scan
def read_text(path):
    """Đọc .ll; nếu là .bc thử llvm-dis."""
    with open(path, 'rb') as f:
        head = f.read(4)
    if head[:2] == b'BC' and head[2:4] == b'\xc0\xde':
        dis = shutil.which('llvm-dis-21') or shutil.which('llvm-dis') or _find_versioned('llvm-dis')
        if not dis:
            raise RuntimeError("File .bc (bitcode) nhưng không tìm thấy llvm-dis để giải.")
        out = subprocess.run([dis, path, '-o', '-'], capture_output=True)
        if out.returncode != 0:
            raise RuntimeError("llvm-dis lỗi: " + out.stderr.decode('utf-8', 'replace')[:200])
        return out.stdout.decode('utf-8', 'replace')
    with open(path, 'r', encoding='utf-8', errors='replace') as f:
        return f.read()

def _find_versioned(tool):
    for v in range(21, 13, -1):
        p = shutil.which(f'{tool}-{v}')
        if p:
            return p
    return None

def scan(content):
    # Pass 1: Thu thập tất cả các hàm được define và phân loại
    defined_funcs = set()
    argified_funcs = set()
    for line in content.splitlines():
        m = DEFINE_RE.match(line)
        if m:
            name = m.group('name')
            defined_funcs.add(name)
            if name.endswith('.argified') or name.endswith('_native'):
                argified_funcs.add(name)

    shims = set()
    for name in argified_funcs:
        if name.endswith('.argified'):
            orig_name = name[:-9] # loại bỏ '.argified'
        else:
            orig_name = name[:-7] # loại bỏ '_native'
        if orig_name in defined_funcs:
            shims.add(orig_name)

    # Bỏ qua các hàm boilerplate của McSema/Remill và entry point khỏi target active check
    for name in defined_funcs:
        if name.startswith("__mcsema_") or name.startswith("__remill_") or name == "start" or name == "main" or name.startswith("callback_"):
            shims.add(name)

    lifted_funcs = set()
    for name in defined_funcs:
        if name in shims or name in argified_funcs:
            continue
        if LIFTED_NAME_RE.match(name):
            lifted_funcs.add(name)

    counts = defaultdict(int)            # khớp toàn cục (chứa cả shim/module)
    active_counts = defaultdict(int)     # khớp trong các hàm active (đã loại bỏ shim/module)
    examples = {}                        # key -> dòng ví dụ
    per_func_dirty = defaultdict(int)    # func name -> số artifact 'dirty' trong hàm active
    funcs_with_lift_sig = set()
    funcs_with_argified_sig = set()
    
    cur = '<module>'
    loc = 0

    for raw in content.splitlines():
        loc += 1
        line = raw

        # Theo dõi biên hàm
        m = DEFINE_RE.match(line)
        if m:
            cur = m.group('name')
            if SIG_RE.search(line):
                if cur in argified_funcs:
                    funcs_with_argified_sig.add(cur)
                else:
                    funcs_with_lift_sig.add(cur)
        elif line.strip() == '}':
            cur = '<module>'

        # Prefilter nhanh
        if not any(mk in line for mk in MARKERS):
            continue

        for key, rgx, original_sev, desc in PATTERNS:
            found = rgx.findall(line)
            if found:
                n = len(found)
                counts[key] += n
                examples.setdefault(key, line.strip()[:160])

                # Xác định severity thực tế của match này trong context hiện tại
                sev = original_sev
                if cur == '<module>' or cur in shims or cur.endswith('_wrapper'):
                    sev = 'info' # module scope và shim wrapper không làm bẩn active logic
                elif cur in argified_funcs:
                    # Downgrade các flushes/reloads thanh ghi ở biên các hàm argified thành info
                    if key in {'reg_flag_globals', 'reg_state_global', 'state_types', 'untethered_state_call', 'reg_alias_defs'}:
                        sev = 'info'

                if sev != 'info':
                    active_counts[key] += n
                    if key in FUNC_DIRTY_KEYS:
                        per_func_dirty[cur] += n

    # Đếm số hàm lifted sạch (không chạm register-state chủ động)
    lifted_funcs_clean_count = 0
    for name in lifted_funcs:
        if per_func_dirty[name] == 0:
            lifted_funcs_clean_count += 1

    funcs_dirty_count = 0
    for f, n in per_func_dirty.items():
        if f != '<module>' and f not in shims and n > 0:
            funcs_dirty_count += 1

    sev_map = {k: s for k, s, _ in [(p[0], p[2], p[3]) for p in PATTERNS]}
    desc_map = {k: d for k, _, d in [(p[0], p[2], p[3]) for p in PATTERNS]}

    return {
        'loc': loc,
        'counts': dict(counts),
        'active_counts': dict(active_counts),
        'examples': examples,
        'funcs_total': len(defined_funcs),
        'shims_count': len(shims),
        'argified_funcs_count': len(argified_funcs),
        'lifted_funcs_count': len(lifted_funcs),
        'lifted_funcs_clean_count': lifted_funcs_clean_count,
        'funcs_with_lift_sig': len(funcs_with_lift_sig),
        'funcs_with_argified_sig': len(funcs_with_argified_sig),
        'funcs_dirty': funcs_dirty_count,
        'top_dirty': sorted(((n, f) for f, n in per_func_dirty.items() if f != '<module>' and f not in shims),
                            reverse=True)[:15],
        'sev_map': sev_map,
        'desc_map': desc_map,
    }

# ----------------------------------------------------------------------------- verdict
def evaluate(r):
    active_counts = r['active_counts']
    sev = r['sev_map']
    
    hard = sum(v for k, v in active_counts.items() if sev.get(k) == 'hard')
    soft = sum(v for k, v in active_counts.items() if sev.get(k) == 'soft')

    total_targets = r['argified_funcs_count'] + r['lifted_funcs_count']
    if total_targets == 0:
        total_targets = 1

    dirty_targets = r['funcs_dirty']
    clean_targets = total_targets - dirty_targets
    clean_pct = round(100.0 * clean_targets / total_targets, 1)

    # Điểm khôi phục native = (số hàm đã argified + số hàm lifted truyền thống đã sạch) / tổng số hàm target
    native_score = round(100.0 * (r['argified_funcs_count'] + r['lifted_funcs_clean_count']) / total_targets, 1)

    if hard == 0 and soft == 0:
        verdict = 'NATIVE'
    elif hard == 0:
        verdict = 'MOSTLY_NATIVE'
    else:
        if native_score >= 90:
            verdict = 'NEARLY_NATIVE'
        elif native_score >= 50:
            verdict = 'PARTIALLY_LIFTED'
        else:
            verdict = 'FULLY_LIFTED'

    return {
        'hard': hard,
        'soft': soft,
        'verdict': verdict,
        'score': int(native_score),
        'clean_pct': clean_pct,
        'is_native': hard == 0
    }

def recommend(r, ev):
    c = r['active_counts']
    recs = []
    
    if ev['is_native'] and r['argified_funcs_count'] > 0:
        recs.append("Mã đã NATIVE-LIKE sau brightening! Sẵn sàng biên dịch hoặc phân tích deobfuscate tiếp theo.")
        return recs

    if c.get('untethered_state_call') or c.get('reg_state_global') or c.get('reg_flag_globals'):
        recs.append("mcsema-state-to-param : thread @__mcsema_reg_state vào tham số state (arg0)")
    if c.get('state_types') or c.get('reg_alias_defs') or c.get('flag_store'):
        recs.append("mcsema-localize-state + sroa : đưa State về alloca rồi promote SSA")
    if ev['verdict'] in ('PARTIALLY_LIFTED', 'NEARLY_NATIVE') and r['funcs_dirty'] > 0:
        recs.append("inline cây callee của hàm đích rồi localize-state (Level-2) để xoá ABI register ở biên call")
    if c.get('remill_memaccess'):
        recs.append("recover-type cho memory (vd dùng anvill) — đang còn __remill_read/write_memory_*")
    if c.get('inttoptr') or c.get('ptrtoint'):
        recs.append("early-cse + instcombine để triệt tiêu cặp inttoptr/ptrtoint round-trip")
    if not recs:
        recs.append("Không còn active artifact lift — chỉ còn (nếu có) tầng deobfuscate CFF/MBA, ngoài phạm vi.")
    return recs

# ----------------------------------------------------------------------------- report
def report_text(path, r, ev, col, verbose):
    o = io.StringIO()
    P = lambda s='': print(s, file=o)
    name = os.path.basename(path)
    P(f"\n{col.BD}══════ Native-IR Check: {name} ══════{col.END}")
    P(f"{col.GR}LOC={r['loc']:,}  hàm={r['funcs_total']:,}  "
      f"hàm-argified={r['argified_funcs_count']:,}  shims-wrapper={r['shims_count']:,}  "
      f"hàm-lift={r['lifted_funcs_count']:,}{col.END}")

    vcolor = {'NATIVE': col.G, 'MOSTLY_NATIVE': col.G, 'NEARLY_NATIVE': col.Y,
              'PARTIALLY_LIFTED': col.Y, 'FULLY_LIFTED': col.R}[ev['verdict']]
    badge = "PASS" if ev['is_native'] else "FAIL"
    bcol = col.G if ev['is_native'] else col.R
    P(f"{bcol}{col.BD}[{badge}]{col.END} {vcolor}{col.BD}{ev['verdict']}{col.END}"
      f"  {col.GR}(native_score={ev['score']}%; cleanliness={ev['clean_pct']}% hàm sạch; hard_active={ev['hard']:,}, soft_active={ev['soft']:,}){col.END}")

    # Bảng phân tích artifact
    hard_rows, soft_rows, info_rows = [], [], []
    for key, rgx, sevx, desc in PATTERNS:
        n = r['counts'].get(key, 0)
        n_active = r['active_counts'].get(key, 0)
        if n == 0:
            continue
        row = (key, n, n_active, desc, r['examples'].get(key, ''))
        (hard_rows if sevx == 'hard' else soft_rows if sevx == 'soft' else info_rows).append(row)

    def dump(title, rows, color):
        if not rows:
            return
        P(f"\n{color}{col.BD}{title}{col.END}")
        for key, n, n_active, desc, ex in rows:
            if n_active > 0:
                P(f"  {color}•{col.END} {desc} {col.BD}×{n:,} ({n_active} active){col.END}")
            else:
                P(f"  {col.GR}• {desc} ×{n:,} (0 active){col.END}")
            if verbose and ex:
                P(f"      {col.GR}{ex}{col.END}")

    if ev['is_native'] and not (hard_rows or soft_rows):
        P(f"\n{col.G}  Sạch — không phát hiện active artifact lift.{col.END}")
    dump("HARD — chặn native (active):", hard_rows, col.R)
    dump("SOFT — dư lượng / chưa sạch:", soft_rows, col.Y)
    if verbose:
        dump("INFO:", info_rows, col.B)

    # Top hàm bẩn
    if r['top_dirty']:
        P(f"\n{col.M}{col.BD}Top hàm còn chạm register-state chủ động:{col.END}")
        for n, f in r['top_dirty'][:10 if verbose else 5]:
            P(f"  {col.M}{n:>5,}{col.END}  {f}")

    # Khuyến nghị
    P(f"\n{col.CY}{col.BD}Pass de-lift đề xuất kế tiếp:{col.END}")
    for rec in recommend(r, ev):
        P(f"  {col.CY}→{col.END} {rec}")
    return o.getvalue()

def result_dict(path, r, ev):
    return {
        'file': path,
        'loc': r['loc'],
        'funcs_total': r['funcs_total'],
        'shims_count': r['shims_count'],
        'argified_funcs_count': r['argified_funcs_count'],
        'lifted_funcs_count': r['lifted_funcs_count'],
        'funcs_dirty': r['funcs_dirty'],
        'verdict': ev['verdict'],
        'is_native': ev['is_native'],
        'native_score': ev['score'],
        'cleanliness_pct': ev['clean_pct'],
        'hard_active': ev['hard'],
        'soft_active': ev['soft'],
        'counts': r['counts'],
        'active_counts': r['active_counts'],
        'top_dirty': [{'func': f, 'artifacts': n} for n, f in r['top_dirty']],
        'recommendations': recommend(r, ev),
    }

# ----------------------------------------------------------------------------- driver
def gather_files(paths):
    out = []
    for p in paths:
        if os.path.isdir(p):
            for root, _d, files in os.walk(p):
                for f in files:
                    if f.endswith(('.ll', '.bc')):
                        out.append(os.path.join(root, f))
        elif os.path.exists(p):
            out.append(p)
        else:
            print(f"[!] Không thấy: {p}", file=sys.stderr)
    return sorted(set(out))

def main():
    ap = argparse.ArgumentParser(
        description="Kiểm tra LLVM IR đã de-lift McSema/Remill về native chưa (phủ hết artifact).")
    ap.add_argument('paths', nargs='+', help='file .ll/.bc hoặc thư mục')
    ap.add_argument('--json', action='store_true', help='xuất JSON (tắt màu, không in báo cáo người-đọc)')
    ap.add_argument('-v', '--verbose', action='store_true', help='in ví dụ dòng + nhiều hàm hơn')
    ap.add_argument('-q', '--quiet', action='store_true', help='chỉ in verdict 1 dòng/ file')
    ap.add_argument('--no-color', action='store_true', help='tắt màu')
    args = ap.parse_args()

    use_color = (not args.no_color and not args.json
                 and sys.stdout.isatty() and os.environ.get('NO_COLOR') is None)
    col = C(use_color)

    files = gather_files(args.paths)
    if not files:
        print("[!] Không có file .ll/.bc nào.", file=sys.stderr)
        sys.exit(2)

    results, any_fail, err = [], False, False
    for path in files:
        try:
            content = read_text(path)
        except Exception as e:
            print(f"{col.R}[!] {path}: {e}{col.END}", file=sys.stderr)
            err = True
            continue
        r = scan(content)
        ev = evaluate(r)
        if not ev['is_native']:
            any_fail = True
        results.append(result_dict(path, r, ev))

        if args.json:
            continue
        if args.quiet:
            badge = f"{col.G}NATIVE{col.END}" if ev['is_native'] else f"{col.R}{ev['verdict']}{col.END}"
            print(f"[{ev['score']:>5}%] {badge}  {path}")
        else:
            sys.stdout.write(report_text(path, r, ev, col, args.verbose))

    if args.json:
        agg = {
            'files': results,
            'summary': {
                'total': len(results),
                'native': sum(1 for x in results if x['is_native']),
                'not_native': sum(1 for x in results if not x['is_native']),
            }
        }
        print(json.dumps(agg, indent=2, ensure_ascii=False))
    elif len(results) > 1 and not args.quiet:
        nat = sum(1 for x in results if x['is_native'])
        print(f"\n{col.BD}══════ Tổng kết ══════{col.END}")
        print(f"  {col.G}NATIVE: {nat}{col.END} / {len(results)} file"
              f"   {col.R}chưa native: {len(results)-nat}{col.END}")

    sys.exit(2 if err and not results else (1 if any_fail else 0))

if __name__ == '__main__':
    main()