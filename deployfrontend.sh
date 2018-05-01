rsync -r src/ docs
rsync build/contracts/Game.json docs/
git add .
git commit -m "adding frontend files to github pages"
git push
