"""Gộp nội dung toàn bộ file văn bản trong thư mục Lab1_Devops thành một file .txt duy nhất.

Mỗi file được đánh dấu bằng tag tên file (đường dẫn tương đối) ở đầu đoạn nội dung.
Dùng: python summary.py [--root DIR] [--output FILE] [--include-state]
"""
import argparse
import os
import sys
from pathlib import Path

DEFAULT_ROOT = Path(r"C:\Users\an.t\Workspace\Learning\Lab1_Devops")
SKIP_DIRS = {".git", ".terraform", "__pycache__", "node_modules", ".venv"}
# State/plan có thể chứa thông tin nhạy cảm nên mặc định bỏ qua
STATE_FILES = {"terraform.tfstate", "terraform.tfstate.backup", "tfplan"}


def is_text_file(path: Path) -> bool:
    try:
        with open(path, "rb") as f:
            chunk = f.read(8192)
        if b"\x00" in chunk:
            return False
        chunk.decode("utf-8")
        return True
    except UnicodeDecodeError:
        # Có thể chunk bị cắt giữa ký tự đa byte, thử đọc toàn bộ file
        try:
            path.read_text(encoding="utf-8")
            return True
        except UnicodeDecodeError:
            return False
    except OSError:
        return False


def collect_files(root: Path, exclude: set, include_state: bool):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = sorted(
            d for d in dirnames if d not in SKIP_DIRS and not d.startswith(".venv")
        )
        for name in sorted(filenames):
            path = Path(dirpath) / name
            if path.resolve() in exclude:
                continue
            if not include_state and name in STATE_FILES:
                continue
            yield path


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=DEFAULT_ROOT)
    parser.add_argument("--output", type=Path, default=None)
    parser.add_argument("--include-state", action="store_true",
                        help="Gộp cả terraform.tfstate*, tfplan")
    args = parser.parse_args()

    root = args.root.resolve()
    output = (args.output or root / "summary.txt").resolve()
    exclude = {output, Path(__file__).resolve()}

    written, skipped = 0, []
    with open(output, "w", encoding="utf-8", newline="\n") as out:
        for path in collect_files(root, exclude, args.include_state):
            rel = path.relative_to(root).as_posix()
            if not is_text_file(path):
                skipped.append(rel)
                continue
            content = path.read_text(encoding="utf-8", errors="replace")
            out.write(f"===== FILE: {rel} =====\n")
            out.write(content)
            if not content.endswith("\n"):
                out.write("\n")
            out.write(f"===== END FILE: {rel} =====\n\n")
            written += 1

    print(f"Đã gộp {written} file vào: {output}")
    if skipped:
        print("Bỏ qua file nhị phân:", ", ".join(skipped))


if __name__ == "__main__":
    main()
