#!/bin/bash
hexo clean && hexo generate && hexo deploy
git add .
git commit -a -m 'dev'
git push origin dev