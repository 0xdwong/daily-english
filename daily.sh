#!/bin/bash

# ssh key 文件名
SSH_KEY="dwong"

# 脚本所在根目录
SCRIPT_DIR="/home/ubuntu/code/ai-words"

# 资源目录变量
RESOURCE_DIR="/home/ubuntu/code/daily-english"

# 当前日期
current_date=$(date +"%Y-%m-%d")

# website url
WEBSITE_BASE_URL="https://daily-english.dwong.top"


# 检查脚本目录是否存在
if [ ! -d "$SCRIPT_DIR" ]; then
  echo "脚本目录不存在: $SCRIPT_DIR"
  exit 1
fi

# 检查资源目录是否存在
if [ ! -d "$RESOURCE_DIR" ]; then
  echo "资源目录不存在: $RESOURCE_DIR"
  exit 1
fi

# 执行脚本
cd "$SCRIPT_DIR"
npx ts-node src/index.ts


# 把文件复制到指定的文件夹
mv "$current_date.md" "$RESOURCE_DIR/src"
mv audios/english.mp3 "$RESOURCE_DIR/src/audios/story/$current_date-english.mp3"
mv audios/chinese.mp3 "$RESOURCE_DIR/src/audios/story/$current_date-chinese.mp3"
mv audios/* "$RESOURCE_DIR/src/audios/words"
mv images/* "$RESOURCE_DIR/src/images"


# 进入资源文件夹
cd "$RESOURCE_DIR"


# 修改 SUMMARY.md
summary_file="$RESOURCE_DIR/src/SUMMARY.md"
# 插入行位置 (N)
line_number=3
# 插入的内容
new_entry="- [$current_date](./$current_date.md)"
# 在指定行插入新的目录项
awk -v n="$line_number" -v entry="$new_entry" 'NR == n {print entry} {print}' "$summary_file" > summary.tmp &&
mv summary.tmp "$summary_file"


# feed
FEED_FILE_PATH="$RESOURCE_DIR/src/feed.xml"
MEIDA_FILE_PATH="$RESOURCE_DIR/src/audios/story/$current_date-english.mp3"
CONTENT_FILE_PATH="$RESOURCE_DIR/src/$current_date.md"
DESCRIPTION=$(head -n 1 "$CONTENT_FILE_PATH")

# 进入脚本文件夹
cd "$SCRIPT_DIR"
npx ts-node scripts/feed.ts "$FEED_FILE_PATH" "$MEIDA_FILE_PATH" "$DESCRIPTION" "$current_date" "$WEBSITE_BASE_URL"


cd "$RESOURCE_DIR"
# 确保当前目录是一个 git 仓库
if [ ! -d ".git" ]; then
  echo "当前目录不是一个 git 仓库: $RESOURCE_DIR"
  exit 1
fi

# 提交git
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/$SSH_KEY

git pull
git add .
git commit -m "add $current_date"
git push


# 打包
mdbook build


# 打印完成信息
echo "所有步骤完成。"