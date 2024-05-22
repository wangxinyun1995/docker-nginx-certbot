##### 生成泛域名证书

##### 什么是泛域名证书？

例如：\*.example.com 也就是这个证书可以给某个域名的所有二级域名使用，就叫做泛域名证书（也称作通配符证书）。

Let's Encrypt 官方推荐我们使用 certbot 脚本申请证书（当然也可以使用 acme.sh 等方式），以下是申请步骤基于 Debian10 python3.7.3 如果你在操作过程中遇到什么报错，请多考虑 python 工具包的版本问题之类的。

Let's Encrypt 自 2018 年开始支持申请泛域名证书，相比于单域名证书，泛域名证书更利于日常的维护。

##### 申请泛域名证书

`docker-compose run --rm  certbot certonly --preferred-challenges dns -d "*.example.com" -d example.com --manual`

参数说明：

certonly 表示只申请证书。

--manual 表示交互式申请。

-d 为那些主机申请证书如 \*.example.com（此处为泛域名）

--preferred-challenges dns，使用 DNS 方式校验域名所有权，可以配置多个

证书签发成功后去 Nginx 或 Apache 配置新生成的证书文件即可。

这里用 example.com 来假设要签的域名，-d 后面跟着一个域名，如果有多个域名要签的话记得每一个单独的域名前都要写-d。

我指定了两个-d 参数，因为 certbot 的泛域名其实只支持诸如\*.example.com，如要直接使用 example.com，就得为其单独也签发一条。

##### 交互步骤

```
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Plugins selected: Authenticator manual, Installer None
Obtaining a new certificate
Performing the following challenges:
dns-01 challenge for example.com

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
NOTE: The IP of this machine will be publicly logged as having requested this
certificate. If you're running certbot in manual mode on a machine that is not
your server, please ensure you're okay with that.

Are you OK with your IP being logged?
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
(Y)es/(N)o: y

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Please deploy a DNS TXT record under the name
_acme-challenge.example.com with the following value:

nI0DhzH-vn0W7STVuLi2O-oIKuFNlqQx5EnjB-zewvs

Before continuing, verify the record is deployed.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Press Enter to Continue
```

需要在 dns 解析添加一条 txt 记录,\_acme-challenge.example.com 指向上面生成的 value:`nI0DhzH-vn0W7STVuLi2O-oIKuFNlqQx5EnjB-zewvs`

##### 确认解析是否生效

`nslookup -type=txt _acme-challenge.example.com 8.8.8.8`

得到如下结果

```
Server:		8.8.8.8
Address:	8.8.8.8#53

Non-authoritative answer:
# 因为同时添加了*.example.com和example.com，所以有2条记录
_acme-challenge.example.com	text = "F8pbljlgmDcNrHcTBcDJ5VOTU2xmllnu-zpLwZpax6w"
_acme-challenge.example.com	text = "loCGueExh-4V6MZr4pCbl2nqynjsMSFBxMszQJbp1Gs"

Authoritative answers can be found from:
```

验证解析是否生效，然后按下 Enter 通过验证,完成证书申请

```
Waiting for verification...
Cleaning up challenges

IMPORTANT NOTES:
- Congratulations! Your certificate and chain have been saved at:
/etc/letsencrypt/live/xx.cn/fullchain.pem
Your key file has been saved at:
/etc/letsencrypt/live/xx.cn/privkey.pem
Your cert will expire on 2024-08-20. To obtain a new or tweaked
version of this certificate in the future, simply run certbot
again. To non-interactively renew *all* of your certificates, run
"certbot renew"
- If you like Certbot, please consider supporting our work by:

Donating to ISRG / Let's Encrypt: https://letsencrypt.org/donate
Donating to EFF: https://eff.org/donate-le

#至此证书申请成功
```

##### 成功生成证书

证书成功保存在`./certbot/cert/`目录，nginx docker 也共享这个文件夹，所以应用的 nginx conf 文件中

```
server {
  listen 443 default_server ssl http2;
  listen [::]:443 ssl http2;

  server_name example.org;

  ssl_certificate /etc/nginx/ssl/live/example.org/fullchain.pem;
  ssl_certificate_key /etc/nginx/ssl/live/example.org/privkey.pem;

  location / {
    # ...
  }
}
```

现在重新加载 nginx 服务器将使其能够处理使用 HTTPS 的安全连接。Nginx 使用来自 Certbot 卷的证书。

##### 更新证书

Certbot 和 Let's Encrypt 可能会遇到的一个小问题是证书只能使用 3 个月。如果您不希望人们被浏览器上的丑陋和可怕的消息阻止，您将需要定期更新您使用的证书。

但是由于我们已经有了这个 Docker 环境，更新 Let's Encrypt 证书比以往任何时候都容易！

```
docker-compose run --rm certbot renew
```

##### 定时自动更新

```
[~]# crontab -l
## 更新证书,执行docker-compose 命令需要在 docker-compose.yml 文件所在的文件夹内执行；
00 03 * * 1 cd /server;/usr/local/bin/docker-compose run --rm certbot renew
```

#### 运行项目
```
docker compose build
docker compose up -d
```
更推荐certbot的方式，一次配置，自动更新，方便省事~