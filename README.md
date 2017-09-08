This is a bunch of small scripts which allow to post thing on the tumblr blog from command line using Tumblr API. Is it possible to use these scripts with Hazel for images and Alfred for quotes and links.

# Requirements
- mac os
- GPGTools
- `rvm`
- `pip`
- `oauth` and `oauth2` python libs
- `tumblr_client` gem
- `colorize` gem
- `faraday` gem
- `nokogiri` gem
- `zsh`

# Installation

0. [Register an app on tumblr](https://www.tumblr.com/docs/en/api/v2)
0. Clone this repo to your local machine.
1. Edit install.sh script to install required things.
2. Run `python oauth_tumblr.py` to authorize your machine. Use tumblr app credentials for that.
3. Use output of previous command to create `~/.tumblr.yml` with following structure:
```
tumblr_auth:
  consumer_key: "<YOUR CONSUMER KEY>"
  consumer_secret: "<YOUR CONSUMER SECRET>"

  <YOUR BLOG NAME: blog-name.tumblr.com>:
    oauth_token: "<OAUTH TOKEN FROM PREVIOUS STEP>"
    oauth_secret: "<OAUTH SECRET FROM PREVIOUS STEP>"
```
4. Encrypt `~/.tumblr.yml` with GPGTools using your key
5. Remove unencrypted version of `~/.tumblr.yml`

# Hazel integration

You can use hazel to post images to your blog just by dragging images to the folder on your desktop. Just import hazel rules from `hazel` folder and edit them to use your blog.

# Alfred integration

You can use alfred as a shortcut to post quotes and links to your blog using alfred's workflow feature. To do that import alfred's workflows from `alfred` folder and edit them to meet your needs.
