#!/bin/bash
# 自动版本发布脚本
# 用法: ./scripts/release.sh [patch|minor|major]

set -e

cd "$(dirname "$0")/.."

# 读取当前版本
VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
echo "当前版本: $VERSION"

# 解析版本号
IFS='.' read -ra V <<< "$VERSION"
MAJOR="${V[0]}"
MINOR="${V[1]}"
PATCH="${V[2]}"

# 根据参数确定新版本
case "${1:-patch}" in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch|*)
    PATCH=$((PATCH + 1))
    ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
echo "新版本: $NEW_VERSION"

# 更新 pubspec.yaml
sed -i "s/^version: $VERSION/version: $NEW_VERSION/" pubspec.yaml
echo "已更新 pubspec.yaml"

# Git 提交
git add -A
git commit -m "release: v$NEW_VERSION"

# 创建标签
git tag "v$NEW_VERSION"

# 推送
echo ""
echo "即将推送以下内容:"
echo "  - Commit: release: v$NEW_VERSION"
echo "  - Tag: v$NEW_VERSION"
echo ""
read -p "确认推送? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
  git push origin main --tags
  echo ""
  echo "✅ 已推送! 请在 GitHub 创建 Release:"
  echo "   https://github.com/wangwhy133/wisdom_quotes/releases/new?tag=v$NEW_VERSION&title=v$NEW_VERSION"
else
  echo "已取消推送"
  echo "如需手动推送，运行: git push origin main --tags"
fi
