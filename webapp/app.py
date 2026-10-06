"""自用 Web 版：儿童绘本生成器

在上游 story_generator_V2.py 的流水线之上包一层 Web 界面：
主题输入 -> 后台生成（写故事 -> 逐段配图）-> 绘本阅读页。

运行：
    cd ~/workspace/picturebook-web
    cp .env.example .env   # 填入 OPENAI_API_KEY / FAL_KEY
    .venv/bin/python webapp/app.py
    打开 http://127.0.0.1:5057
"""
import os
import sys
import json
import time
import uuid
import threading
from pathlib import Path
from datetime import datetime

# ---- 路径与环境 ----
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from dotenv import load_dotenv
load_dotenv(ROOT / ".env")
# fal_client 1.x 只认环境变量 FAL_KEY
if os.getenv("FAL_KEY"):
    os.environ["FAL_KEY"] = os.getenv("FAL_KEY")

import story_generator_V2 as gen  # noqa: E402
from flask import Flask, request, jsonify, render_template, send_from_directory, abort  # noqa: E402

DATA_DIR = Path(__file__).resolve().parent / "data" / "books"
DATA_DIR.mkdir(parents=True, exist_ok=True)

app = Flask(__name__, template_folder="templates", static_folder="static")

# ---- 任务状态（自用：内存保存即可） ----
jobs = {}
jobs_lock = threading.Lock()


def set_job(job_id, **kw):
    with jobs_lock:
        jobs[job_id].update(kw)


def worker(job_id, theme, age, paragraph_count, image_every):
    """后台生成流水线，与上游 main() 同逻辑，另加进度上报。"""
    book_dir = DATA_DIR / job_id
    book_dir.mkdir(parents=True, exist_ok=True)
    try:
        set_job(job_id, state="running", phase="写故事", progress=5,
                detail="正在请 AI 写故事…")

        config = gen.StoryConfig(
            language="中文",
            target_age=age,
            words_per_paragraph=100,
            paragraph_count=paragraph_count,
        )
        story_generator = gen.StoryGenerator()
        prompt_generator = gen.FluxPromptGenerator()
        image_generator = gen.FluxImageGenerator(api_key=os.getenv("FAL_KEY"))
        story_formatter = gen.StoryFormatter()

        story = story_generator.generate_story(
            theme=theme, config=config,
            additional_requirements="故事要富有教育意义，适合儿童阅读",
        )
        if not story or not story.get("paragraphs"):
            raise RuntimeError("故事生成失败（API 无返回）")

        paragraphs = story["paragraphs"]
        # 按 image_every 挑选配图段落
        img_indices = [i for i in range(len(paragraphs)) if i % image_every == 0]
        total_imgs = len(img_indices)

        image_files = {}  # paragraph_index -> filename
        for n, idx in enumerate(img_indices):
            p = paragraphs[idx]
            content = p.get("paragraph", "") if isinstance(p, dict) else p
            scene = p.get("scene", "") if isinstance(p, dict) else content
            set_job(job_id, phase="画插图", progress=10 + int(80 * n / total_imgs),
                    detail=f"正在画第 {n + 1}/{total_imgs} 张插图…")
            prompts = prompt_generator.generate_prompts(
                title=story.get("title", theme),
                scene=scene,
                main_character=story.get("main_character", ""),
            )
            fname = f"scene_{idx + 1:02d}.png"
            ok = False
            if prompts:
                ok = image_generator.generate_image(
                    positive_prompt=prompts["positive_prompt"],
                    negative_prompt=prompts["negative_prompt"],
                    output_path=str(book_dir / fname),
                )
            if ok:
                image_files[idx] = fname
            time.sleep(1)

        set_job(job_id, phase="排版", progress=95, detail="正在排版成绘本…")

        pages = []
        for i, p in enumerate(paragraphs):
            text = p.get("paragraph", "") if isinstance(p, dict) else p
            pages.append({"text": text, "image": image_files.get(i)})

        book = {
            "id": job_id,
            "theme": theme,
            "title": story.get("title", theme),
            "age": age,
            "pages": pages,
            "image_count": len(image_files),
            "created_at": datetime.now().strftime("%Y-%m-%d %H:%M"),
        }
        (book_dir / "story.json").write_text(
            json.dumps(book, ensure_ascii=False, indent=2), encoding="utf-8")

        # 顺手留一份 markdown（上游格式）
        image_links = [f"./{image_files[i]}" for i in sorted(image_files)]
        md = story_formatter.format_story(story, image_links)
        if md:
            (book_dir / "book.md").write_text(md, encoding="utf-8")

        set_job(job_id, state="done", phase="完成", progress=100,
                detail=f"共 {len(pages)} 段，{len(image_files)} 张插图",
                book=book)
    except Exception as e:
        set_job(job_id, state="error", phase="出错", detail=str(e)[:300])


# ---- 路由 ----
@app.route("/")
def index():
    return render_template("index.html")


@app.route("/api/config")
def api_config():
    return jsonify({
        "openai": bool(os.getenv("OPENAI_API_KEY")),
        "fal": bool(os.getenv("FAL_KEY")),
        "model": os.getenv("OPENAI_MODEL", "gpt-4"),
    })


@app.route("/api/jobs", methods=["POST"])
def api_create_job():
    if not os.getenv("OPENAI_API_KEY") or not os.getenv("FAL_KEY"):
        return jsonify({"error": "API Key 未配置，请先填写 .env"}), 400
    data = request.get_json(force=True)
    theme = (data.get("theme") or "").strip()
    if not theme:
        return jsonify({"error": "请填写故事主题"}), 400
    job_id = uuid.uuid4().hex[:12]
    age = (data.get("age") or "5-8岁").strip()
    paragraph_count = max(3, min(15, int(data.get("paragraphs", 12))))
    image_every = max(1, min(6, int(data.get("image_every", 3))))
    with jobs_lock:
        jobs[job_id] = {
            "id": job_id, "theme": theme, "state": "queued",
            "phase": "排队", "progress": 0, "detail": "等待开始…",
            "created_at": datetime.now().strftime("%Y-%m-%d %H:%M"),
        }
    t = threading.Thread(target=worker,
                         args=(job_id, theme, age, paragraph_count, image_every),
                         daemon=True)
    t.start()
    return jsonify({"job_id": job_id})


@app.route("/api/jobs/<job_id>")
def api_job(job_id):
    with jobs_lock:
        job = jobs.get(job_id)
    if not job:
        # 重启后从磁盘恢复
        bj = DATA_DIR / job_id / "story.json"
        if bj.exists():
            book = json.loads(bj.read_text(encoding="utf-8"))
            return jsonify({"id": job_id, "state": "done", "phase": "完成",
                            "progress": 100, "theme": book["theme"], "book": book})
        return jsonify({"error": "任务不存在"}), 404
    return jsonify(job)


@app.route("/api/books")
def api_books():
    books = []
    for d in sorted(DATA_DIR.iterdir(), reverse=True):
        f = d / "story.json"
        if f.exists():
            b = json.loads(f.read_text(encoding="utf-8"))
            books.append({"id": b["id"], "title": b["title"],
                          "theme": b["theme"], "created_at": b["created_at"],
                          "pages": len(b["pages"]), "images": b["image_count"]})
    return jsonify(books)


@app.route("/book/<job_id>")
def book_page(job_id):
    bj = DATA_DIR / job_id / "story.json"
    if not bj.exists():
        abort(404)
    book = json.loads(bj.read_text(encoding="utf-8"))
    return render_template("book.html", book=book)


@app.route("/books/<job_id>/images/<path:fname>")
def book_image(job_id, fname):
    return send_from_directory(DATA_DIR / job_id, fname)


if __name__ == "__main__":
    app.run(host=os.getenv("HOST", "127.0.0.1"),
            port=int(os.getenv("PORT", "5057")), threaded=True)
