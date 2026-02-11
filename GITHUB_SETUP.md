# GitHub Setup Instructions

## Step 1: Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `appfinder`
3. Description: `CodeMeter Runtime detection scripts for ConnectWise ScreenConnect`
4. Choose Public or Private
5. **DO NOT** initialize with README, .gitignore, or license (we already have these)
6. Click "Create repository"

## Step 2: Add Remote and Push

After creating the repo, GitHub will show you commands. Use these instead (already configured for this repo):

```bash
cd c:\git\appfinder
git remote add origin https://github.com/YOUR_USERNAME/appfinder.git
git branch -M main
git push -u origin main
```

**Replace `YOUR_USERNAME` with your actual GitHub username.**

## Step 3: Update One-Liner Commands

After pushing, update the one-liner commands in `SC-OneLiner.txt` and `README.md` by replacing `YOUR_USERNAME` with your actual GitHub username.

## Quick Push Commands (Copy All)

```bash
cd c:\git\appfinder
git remote add origin https://github.com/YOUR_USERNAME/appfinder.git
git branch -M main
git push -u origin main
```

## ScreenConnect One-Liner (After Push)

Once pushed, use this command in ScreenConnect (replace YOUR_USERNAME):

```powershell
powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/YOUR_USERNAME/appfinder/main/Find-CodeMeterRuntime.ps1' -OutFile '$env:TEMP\Find-CodeMeterRuntime.ps1'; & '$env:TEMP\Find-CodeMeterRuntime.ps1'"
```
