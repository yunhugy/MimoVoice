# 绘本生成器 · Web 自用版

输入一个故事主题，AI 自动写故事、画插图，生成一本图文并茂的儿童绘本。单用户自用版本：无登录、无多用户，打开即用。

生成流程：主题 → OpenAI 写故事（可设段落数、目标年龄）→ Fal.ai Flux 按段落画插图（含角色一致性处理）→ 绘本阅读页展示，可回看历史记录。

## 致谢

故事与配图流水线基于 [whotto/Picture_book_production](https://github.com/whotto/Picture_book_production)（MIT 协议），本仓库将其 `story_generator_V2.py` 直接收录，Web 界面与任务调度为自用新增。

## 快速开始（本地）

```bash
git clone <本仓库地址>
cd picturebook-web

python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

cp .env.example .env   # 填入你的 Key（见下）
python webapp/app.py
```

浏览器打开 http://127.0.0.1:5057

## 配置说明

复制 `.env.example` 为 `.env` 并填写：

| 变量 | 说明 |
|---|---|
| `OPENAI_API_KEY` | 必填。故事文本生成，可用 OpenAI 官方或任何 OpenAI 兼容接口 |
| `OPENAI_API_BASE` | 选填。兼容接口地址，留空则用官方 `https://api.openai.com/v1` |
| `OPENAI_MODEL` | 选填，默认 `gpt-4` |
| `FAL_KEY` | 必填。插图生成，在 [fal.ai](https://fal.ai) 注册获取 |

`.env` 已加入 `.gitignore`，不会被提交。

## VPS 部署（Docker Compose，推荐）

```bash
# 1. 拉代码、配 Key
git clone <本仓库地址> && cd picturebook-web
cp .env.example .env && nano .env   # 填好两个 Key

# 2. 启动
docker compose up -d --build

# 3. 查看日志
docker compose logs -f
```

服务监听 `0.0.0.0:5057`，生成的数据挂载在 `./webapp/data/books`，容器重建不丢失。

如需域名访问，建议前置 Nginx 反向代理并加基础认证（自用场景）：

```nginx
server {
    listen 80;
    server_name book.example.com;
    location / {
        proxy_pass http://127.0.0.1:5057;
        auth_basic "private";
        auth_basic_user_file /etc/nginx/.htpasswd;
    }
}
```

## 生成耗时与费用参考

- 写故事约 1 分钟；每张插图约 30–60 秒
- 默认 12 段、每 3 段配 1 张图，一本约 4–6 分钟、4 张图
- 费用 = OpenAI 文本 token + fal.ai 图片张数，按各自官网计价；自用建议先小批量试

## 目录结构

```
picturebook-web/
├── webapp/
│   ├── app.py              # Flask 服务：任务创建、进度、绘本页
│   ├── templates/          # 首页、绘本阅读页
│   ├── static/             # 样式
│   └── data/books/         # 生成产物（不进仓库）
├── story_generator_V2.py   # 上游流水线（故事/提示词/配图/排版）
├── Dockerfile / docker-compose.yml
└── .env.example
```

## 注意事项

- 自用版本无鉴权，不要直接暴露到公网不设密码
- 儿童读物内容建议人工过一遍再给孩子看
