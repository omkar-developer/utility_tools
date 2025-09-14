@echo off
setlocal enabledelayedexpansion

REM Ensure we’re on main and up to date
git checkout main
git pull origin main

REM Build Flutter web release
flutter build web --release
if errorlevel 1 (
    echo Flutter build failed!
    exit /b 1
)

REM Prepare gh-pages worktree
git worktree add "%TEMP%\gh-pages" gh-pages

REM Copy build output
xcopy /E /Y /I build\web\* "%TEMP%\gh-pages\"

REM Commit and push
cd /d "%TEMP%\gh-pages"
git add --all
git commit -m "Update GitHub Pages build" || echo Nothing to commit
git push origin gh-pages

REM Cleanup
cd /d %~dp0
git worktree remove "%TEMP%\gh-pages" --force

echo Deployment finished!
