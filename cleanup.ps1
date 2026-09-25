# Get out of the broken venv
deactivate

Set-Location "C:\Users\Areesha\reproductive-health app\wellness_saheli"
Remove-Item ".git\index.lock" -Force -ErrorAction SilentlyContinue

git rm -r app_backend
git rm Procfile
git rm -r data results
git rm -r --cached venv
git add -A
git commit -m "Clean up: remove dead FastAPI code, ML artifacts, untrack venv"

python -m pip install --user git-filter-repo
python -m git_filter_repo --path venv --invert-paths --force
git remote add origin https://github.com/areeshasadaf56-debug/wellness-saheli-server.git
git push origin main:main --force