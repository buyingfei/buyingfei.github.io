---
title: composer 生成自己项目 
date: 2018-06-25 20:24:07
tags:
- composer
categories:
- web开发
---

写一个插件，想能不能通过composer 来引入，这样更方便大家使用，开始探索之旅。

**github 上新建项目**
例如新建项目：https://github.com/buyingfei/buyingfei.github.io.git

**git clone 到本地**
```bash
git clone 项目地址
```
**composer init 生成composer.json 文件架构，并对composer.json 文件进行修改**
此为项目结构
```bash
$ tree .
.
├── composer.json
├── example
│   ├── cli_xml.php
│   ├── composer_xml.php
│   └── test.xml
├── README.md
├── src
│   ├── ArrayToXML.php
│   └── Exception.php
└── vendor
    ├── autoload.php
    └── composer
        ├── autoload_classmap.php
        ├── autoload_namespaces.php
        ├── autoload_psr4.php
        ├── autoload_real.php
        ├── autoload_static.php
        ├── ClassLoader.php
        └── LICENSE

```
主要修改composer.json，增加psr-4,完成文件映射

```php
"autoload": {
        "psr-4": {
            "parseArray\\": "./src/"
        }
    },
```
**生成composer vendor 等文件**
```bash
composer dumpautoload
```

**注册https://packagist.org 账号，并获取token**
![token 界面](/source/packagisttoken.png)

**完成本地调试后，push  github 服务器，并进行代码同步设置**
![github设置页](/source/githubpack.png)

complate！！！



